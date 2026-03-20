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

class WorkflowsController < ApplicationController
  layout "admin"

  before_action :require_admin

  before_action :find_roles, except: :update
  before_action :find_types, except: %i[edit update]

  before_action :find_role, only: :update
  before_action :find_type, only: %i[edit update]

  before_action :find_optional_role, only: :edit

  def index; end

  def summarized
    @workflow_counts = Workflow.count_by_type_and_role
    @roles = @workflow_counts.first&.last&.map(&:first)
  end

  def edit
    @used_statuses_only = params[:used_statuses_only] == "1"

    statuses_for_form

    if @type && @role && @statuses.any?
      workflows_for_form
    end
  end

  def update
    tab = params[:tab] || "always"
    call = Workflows::BulkUpdateService
           .new(role: @role, type: @type, tab:)
           .call(permitted_status_params)

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: "edit", role_id: @role, type_id: @type, tab:
    end
  end

  private

  def statuses_for_form
    @statuses = if @type && @used_statuses_only && @type.statuses.any?
                  @type.statuses
                else
                  Status.all
                end
  end

  def workflows_for_form
    workflows = Workflow.where(role_id: @role.id, type_id: @type.id)
    @workflows = {}
    @workflows["always"] = workflows.select { |w| !w.author && !w.assignee }
    @workflows["author"] = workflows.select(&:author)
    @workflows["assignee"] = workflows.select(&:assignee)
  end

  def find_roles
    @roles = eligible_roles.order(:builtin, :position)
  end

  def find_types
    @types = ::Type.order(:position)
  end

  def find_role
    @role = eligible_roles.find(params[:role_id])
  end

  def find_type
    @type = ::Type.find(params[:type_id])
  end

  def find_optional_role
    @role = eligible_roles.find_by(id: params[:role_id])
  end

  def eligible_roles
    roles = Role.where(type: ProjectRole.name)

    if EnterpriseToken.allows_to?(:work_package_sharing)
      roles.or(Role.where(builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR))
    else
      roles
    end
  end

  def permitted_status_params
    return {} if params["status"].blank?

    params["status"]
      .to_unsafe_h
      .select { |key, value| /\A\d+\z/.match?(key) && value.keys.all? { /\A\d+\z/.match?(it) } }
  end
end
