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

class Workflows::CopiesController < ApplicationController
  layout "admin"

  before_action :require_admin

  before_action :find_roles
  before_action :find_types
  before_action :set_source_type
  before_action :set_source_role
  before_action :set_target_types
  before_action :set_target_roles

  def new; end

  def create
    if @source_type.nil? && @source_role.nil?
      flash.now[:error] = I18n.t(:error_workflow_copy_source)
      render :new
    elsif @target_types.nil? || @target_roles.nil?
      flash.now[:error] = I18n.t(:error_workflow_copy_target)
      render :new
    else
      Workflow.copy(@source_type, @source_role, @target_types, @target_roles)
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: "new", source_type_id: @source_type, source_role_id: @source_role
    end
  end

  private

  def find_roles
    @roles = eligible_roles.order(:builtin, :position)
  end

  def find_types
    @types = ::Type.order(:position)
  end

  def set_source_type
    @source_type = if params[:source_type_id].blank? || params[:source_type_id] == "any"
                     nil
                   else
                     ::Type.find(params[:source_type_id])
                   end
  end

  def set_source_role
    @source_role = if params[:source_role_id].blank? || params[:source_role_id] == "any"
                     nil
                   else
                     eligible_roles.find(params[:source_role_id])
                   end
  end

  def set_target_types
    @target_types = params[:target_type_ids].blank? ? nil : ::Type.where(id: params[:target_type_ids])
  end

  def set_target_roles
    @target_roles = params[:target_role_ids].blank? ? nil : eligible_roles.where(id: params[:target_role_ids])
  end

  def eligible_roles
    roles = Role.where(type: ProjectRole.name)

    if EnterpriseToken.allows_to?(:work_package_sharing)
      roles.or(Role.where(builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR))
    else
      roles
    end
  end
end
