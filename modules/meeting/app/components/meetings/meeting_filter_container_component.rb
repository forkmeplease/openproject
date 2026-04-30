# frozen_string_literal: true

# -- copyright
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
# ++

module Meetings
  class MeetingFilterContainerComponent < ApplicationComponent
    include ApplicationHelper

    def initialize(query:, params:, project: nil)
      super
      @query = query
      @params = params
      @project = project
    end

    def recurring_filter_value
      filter = @query.filters.find { |f| f.name == :type }
      filter&.values&.first
    end

    def time_filter_value
      filter = @query.filters.find { |f| f.name == :time }
      filter&.values&.first
    end

    def path_for_recurring(value)
      path_with_filter("type", value)
    end

    def path_for_time(value)
      direction = value == Queries::Meetings::Filters::TimeFilter::PAST_VALUE ? "desc" : "asc"
      path_with_filter("time", value, sort_by: [["start_time", direction]])
    end

    private

    def path_with_filter(key, value, sort_by: nil)
      filters = existing_filters.reject { |f| f.key?(key) }
      filters << { key => { "operator" => "=", "values" => [value] } } if value

      merged = current_params.except(:filters, :sortBy)
      merged[:filters] = filters.to_json if filters.any?
      merged[:sortBy] = sort_by.to_json if sort_by
      polymorphic_path([@project, :meetings], merged)
    end

    def current_params
      @current_params ||= @params.slice(:filters, :page, :per_page).permit!
    end

    def existing_filters
      return [] if @params[:filters].blank?

      JSON.parse(@params[:filters])
    end
  end
end
