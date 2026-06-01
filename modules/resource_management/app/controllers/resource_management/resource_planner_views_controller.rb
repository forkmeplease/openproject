# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
module ::ResourceManagement
  class ResourcePlannerViewsController < BaseController
    include OpTurbo::ComponentStream

    menu_item :resource_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_resource_planner
    before_action :find_view, only: %i[show edit update destroy new_work_package add_work_package]

    def show; end

    def new
      if params[:view_class_name].present?
        render_configure_step(build_view)
      else
        respond_with_dialog ResourcePlannerViews::NewDialogComponent.new(
          resource_planner: @resource_planner,
          project: @project
        )
      end
    end

    def edit
      respond_with_dialog ResourcePlannerViews::EditDialogComponent.new(
        view: @view,
        project: @project,
        resource_planner: @resource_planner
      )
    end

    def create
      view_class = allowed_view_class(params[:view_class_name])
      return render_400(message: "Invalid view type") if view_class.nil?

      call = ResourcePlannerViews::CreateService
               .new(user: current_user, model: build_view(view_class:))
               .call(create_params)

      call.success? ? render_create_success(call.result) : render_configure_step(call.result, status: :unprocessable_entity)
    end

    def update
      call = ResourcePlannerViews::UpdateService
               .new(user: current_user, model: @view)
               .call(view_params)

      call.success? ? render_update_success(call.result) : render_edit_step(call.result, status: :unprocessable_entity)
    end

    def destroy
      call = ResourcePlannerViews::DeleteService.new(user: current_user, model: @view).call

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = call.message
      end

      # The deleted view was a tab; navigate back to the planner, which falls
      # back to a remaining view (or the blank slate).
      render turbo_stream: turbo_stream.redirect_to(
        project_resource_planner_path(@project, @resource_planner)
      )
    end

    # Opens the search dialog for manually hand-picked views.
    def new_work_package
      respond_with_dialog ResourcePlannerViews::WorkPackageList::AddWorkPackageDialogComponent.new(
        view: @view,
        project: @project,
        resource_planner: @resource_planner
      )
    end

    # Appends the chosen work package to the view's query and re-renders the
    # list in place.
    def add_work_package
      work_package = WorkPackage
                       .visible(current_user)
                       .where(project: @project)
                       .find_by(id: params[:work_package_id])

      return render_400(message: I18n.t(:notice_file_not_found)) if work_package.nil?

      append_work_package(work_package)
      render_work_package_added
    end

    private

    def append_work_package(work_package)
      query = @view.effective_query
      return if query.ordered_work_packages.exists?(work_package_id: work_package.id)

      next_position = (query.ordered_work_packages.maximum(:position) || 0) + 1
      query.ordered_work_packages.create!(work_package:, position: next_position)
    end

    def render_work_package_added
      replace_via_turbo_stream(
        component: ResourcePlannerViews::ContentComponent.new(
          view: @view,
          project: @project,
          resource_planner: @resource_planner
        )
      )
      close_dialog_via_turbo_stream(
        "##{ResourcePlannerViews::WorkPackageList::AddWorkPackageDialogComponent::DIALOG_ID}"
      )
      respond_with_turbo_streams
    end

    def render_configure_step(view, status: :ok)
      update_dialog_title_via_turbo_stream(
        ResourcePlannerViews::NewDialogComponent::DIALOG_ID,
        new_title: I18n.t("resource_management.configure_view_dialog.title")
      )
      replace_via_turbo_stream(
        component: ResourcePlannerViews::ConfigureStep::FormComponent.new(
          view:,
          url: project_resource_planner_views_path(@project, @resource_planner),
          hidden_fields: { view_class_name: view.class.name },
          dialog_id: ResourcePlannerViews::NewDialogComponent::DIALOG_ID,
          filter_query: view.build_default_query
        ),
        status:
      )
      replace_via_turbo_stream(component: ResourcePlannerViews::ConfigureStep::FooterComponent.new)
      respond_with_turbo_streams
    end

    # Re-renders the edit dialog's form and footer in place when the update
    # fails validation. Mirrors render_configure_step but targets the edit
    # dialog's form/footer ids and uses the PATCH update path.
    def render_edit_step(view, status: :ok)
      replace_via_turbo_stream(
        component: ResourcePlannerViews::ConfigureStep::FormComponent.new(
          view:,
          url: project_resource_planner_view_path(@project, @resource_planner, view),
          method: :patch,
          form_id: ResourcePlannerViews::EditDialogComponent::FORM_ID,
          dialog_id: ResourcePlannerViews::EditDialogComponent::DIALOG_ID,
          filter_query: view.effective_query
        ),
        status:
      )
      replace_via_turbo_stream(
        component: ResourcePlannerViews::ConfigureStep::FooterComponent.new(
          submit_label: I18n.t(:button_save),
          dialog_id: ResourcePlannerViews::EditDialogComponent::DIALOG_ID,
          form_id: ResourcePlannerViews::EditDialogComponent::FORM_ID,
          footer_id: ResourcePlannerViews::EditDialogComponent::FOOTER_ID
        ),
        status:
      )
      respond_with_turbo_streams
    end

    # On a successful update we don't navigate away: the edit dialog is closed
    # and both the tab nav (the view's name may have changed) and the view's
    # content are replaced in place. The generic ContentComponent knows how to
    # render whichever view type this is.
    def render_update_success(view)
      # The cached children association still holds the pre-update name.
      @resource_planner.children.reload

      replace_via_turbo_stream(
        component: ResourcePlanners::SubViewsComponent.new(
          resource_planner: @resource_planner,
          selected_view: view
        )
      )
      replace_via_turbo_stream(
        component: ResourcePlannerViews::ContentComponent.new(
          view:,
          project: @project,
          resource_planner: @resource_planner
        )
      )
      close_dialog_via_turbo_stream("##{ResourcePlannerViews::EditDialogComponent::DIALOG_ID}")
      respond_with_turbo_streams
    end

    def build_view(view_class: allowed_view_class(params[:view_class_name]))
      view_class.new(parent: @resource_planner, project: @project, principal: current_user)
    end

    def view_params
      params.expect(view: %i[name]).to_h.merge(query_configuration_params)
    end

    # The configure form renders inside a `scope: :view` form, so the
    # automatic/manual radio is submitted as `view[filter_mode]` even though
    # it is not a view attribute (the filters JSON, emitted via a plain
    # `hidden_field_tag`, stays top-level). Read the toggle from the view
    # scope, falling back to a top-level param. The SetAttributesService
    # consumes both to configure the backing query.
    def query_configuration_params
      { filters: params[:filters], filter_mode: filter_mode_param }
    end

    def filter_mode_param
      params.dig(:view, :filter_mode) || params[:filter_mode]
    end

    def create_params
      view_params.merge(parent: @resource_planner, project: @project, principal: current_user)
    end

    def render_create_success(view)
      render turbo_stream: turbo_stream.redirect_to(
        project_resource_planner_view_path(@project, @resource_planner, view)
      )
    end

    def allowed_view_class(name)
      ResourcePlanner.allowed_child_class(name)
    end

    def find_resource_planner
      @resource_planner = ResourcePlanner
                            .visible(current_user)
                            .where(project: @project)
                            .with_children
                            .find(params.expect(:resource_planner_id))
    end

    def find_view
      @view = @resource_planner.children.find(params.expect(:id))
    end
  end
end
