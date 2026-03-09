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

module Boards
  class SprintTaskBoardCreateService < BaseCreateService
    protected

    def before_perform(_service_result)
      create_queries_results = create_queries(params)

      return create_queries_results.find(&:failure?) if create_queries_results.any?(&:failure?)

      set_attributes(params.merge(query_ids: create_queries_results.map { it.result.id })).tap do |service_result|
        service_result.result.linked = params[:sprint] if service_result.success?
      end
    end

    private

    def create_query_params(params, status)
      default_create_query_params(params).merge(
        name: query_name(status),
        filters: query_filters(status)
      )
    end

    def column_count_for_board
      statuses.count
    end

    def create_queries(params)
      statuses.map do |status|
        Queries::CreateService.new(user:)
                              .call(create_query_params(params, status))
      end
    end

    def statuses
      @statuses ||= Type.find(Task.type).statuses
    end

    def query_name(status)
      status.name
    end

    def query_filters(status)
      [{ status_id: { operator: "=", values: [status.id.to_s] } }]
    end

    def options_for_grid(_params)
      {
        type: "action",
        attribute: "status",
        highlightingMode: "priority",
        filters: [{ sprint_id: { operator: "=", values: [params[:sprint].id.to_s] } }]
      }
    end

    def options_for_widgets(params)
      params[:query_ids].zip(statuses).map.with_index do |(query_id, status), index|
        Grids::Widget.new(
          start_row: 1,
          start_column: 1 + index,
          end_row: 2,
          end_column: 2 + index,
          identifier: "work_package_query",
          options: {
            "queryId" => query_id,
            "filters" => query_filters(status)
          }
        )
      end
    end
  end
end
