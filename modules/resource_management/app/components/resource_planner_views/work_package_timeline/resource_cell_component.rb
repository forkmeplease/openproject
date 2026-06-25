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

module ResourcePlannerViews
  module WorkPackageTimeline
    # The work package row shown in the timeline's resource (left) column.
    # Rendered server-side so it stays consistent with the work package list view.
    class ResourceCellComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(work_package:, allocations: [], project: nil, resource_planner: nil, view: nil)
        super
        @work_package = work_package
        @allocations = allocations
        @project = project
        @resource_planner = resource_planner
        @view = view
      end

      private

      def info_line
        render(WorkPackages::InfoLineComponent.new(work_package: @work_package, show_status: true))
      end

      def subject_link
        render(
          Primer::Beta::Link.new(
            href: helpers.url_for(controller: "/work_packages", action: "show", id: @work_package),
            font_weight: :bold,
            underline: false
          )
        ) { @work_package.subject }
      end

      def progress
        render(ResourceAllocations::ProgressComponent.new(work_package: @work_package, allocations: @allocations))
      end

      def context_menu
        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button(icon: "kebab-horizontal",
                                "aria-label": t("resource_management.work_package_list.context_menu.label"),
                                scheme: :invisible)

          see_allocation_item(menu)
          edit_total_work_item(menu) if allowed_to_edit_work?
        end
      end

      def see_allocation_item(menu)
        menu.with_item(
          label: t("resource_management.work_package_list.context_menu.see_allocation"),
          tag: :a,
          href: helpers.project_work_package_resource_allocations_path(@project, @work_package),
          content_arguments: { data: { controller: "async-dialog" } }
        ) do |item|
          item.with_leading_visual_icon(icon: :hourglass)
        end
      end

      def edit_total_work_item(menu)
        menu.with_item(
          label: t("resource_management.work_package_list.context_menu.edit_total_work"),
          tag: :a,
          href: helpers.edit_project_resource_planner_view_work_package_progress_path(
            @project, @resource_planner, @view, @work_package
          ),
          content_arguments: { data: { controller: "async-dialog" } }
        ) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      end

      def allowed_to_edit_work?
        return false if @project.nil?

        User.current.allowed_in_project?(:edit_work_packages, @project)
      end
    end
  end
end
