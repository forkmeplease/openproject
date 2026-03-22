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

class Sprints::StartService < BaseServices::BaseContracted
  def initialize(user:, model:, contract_class: Sprints::StartContract)
    super(user:, contract_class:)
    self.model = model
  end

  private

  def persist(service_call)
    result = ensure_task_boards
    return result if result.failure?

    model.active!

    service_call
  rescue ActiveRecord::RecordNotUnique
    add_only_one_active_sprint_error
    ServiceResult.failure(result: model, errors: model.errors)
  end

  def ensure_task_boards
    projects = Agile::Sprint.receiving_projects(model)

    results = projects.map do |project|
      next ServiceResult.success if model.task_board_for(project).present?

      Boards::SprintTaskBoardCreateService
        .new(user: User.system)
        .call(project:, sprint: model, name: board_name)
    end

    aggregate_failures(results)
  end

  def aggregate_failures(results)
    failed = results.select(&:failure?)
    return ServiceResult.success if failed.empty?

    failed.each_with_object(ServiceResult.failure) do |result, combined|
      combined.add_dependent!(result)
    end
  end

  def board_name
    "#{model.project.name}: #{model.name}"
  end

  def add_only_one_active_sprint_error
    return if model.errors.added?(:status, :only_one_active_sprint_allowed)

    model.errors.add(:status, :only_one_active_sprint_allowed)
  end
end
