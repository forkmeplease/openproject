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

class Users::WorkingHoursController < ApplicationController
  include WorkingTimesAuthorization

  layout "admin"

  authorization_checked! :index, :create, :update, :destroy

  before_action :find_user
  before_action :authorize_manage_working_times
  before_action :find_working_hours, only: %i[update destroy]

  def index
    @working_hours = @user.working_hours.order(valid_from: :desc)
    @current_working_hours = @user.working_hours.current

    render "users/edit"
  end

  def create
    call = UserWorkingHours::CreateService
             .new(user: current_user)
             .call(working_hours_params.merge(user: @user))

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_create)
    else
      flash[:error] = call.errors.full_messages.join(", ")
    end

    redirect_to user_working_hours_index_path(@user)
  end

  def update
    call = UserWorkingHours::UpdateService
             .new(model: @user_working_hours, user: current_user)
             .call(working_hours_params)

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
    else
      flash[:error] = call.errors.full_messages.join(", ")
    end

    redirect_to user_working_hours_index_path(@user)
  end

  def destroy
    call = UserWorkingHours::DeleteService
             .new(model: @user_working_hours, user: current_user)
             .call

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_delete)
    else
      flash[:error] = call.errors.full_messages.join(", ")
    end

    redirect_to user_working_hours_index_path(@user)
  end

  private

  def find_user
    @user = User.visible.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_working_hours
    @user_working_hours = @user.working_hours.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def working_hours_params
    params.expect(
      working_hours: %i[valid_from
                        monday_hours
                        tuesday_hours
                        wednesday_hours
                        thursday_hours
                        friday_hours
                        saturday_hours
                        sunday_hours
                        availability_factor]
    )
  end
end
