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
    # The container the FullCalendar resource-timeline controller mounts into.
    # Bulk data comes from the feed endpoints; only small config travels inline.
    class ContentComponent < ApplicationComponent
      # This component mounts the Stimulus controller; other timeline components
      # reference this identifier to dispatch actions to it.
      STIMULUS = "resource-management--work-package-timeline"

      def initialize(view:, project:, resource_planner:, work_packages: [], allocations: {}, visible_principal_ids: nil)
        super
        @view = view
        @project = project
        @resource_planner = resource_planner
        @work_packages = work_packages
        @allocations = allocations
        @visible_principal_ids = visible_principal_ids
      end

      private

      def container_attributes
        attributes = {
          "class" => "op-rm-timeline-view",
          "data-controller" => STIMULUS,
          "data-test-selector" => "resource-work-package-timeline"
        }
        stimulus_values.each { |key, value| attributes["data-#{STIMULUS}-#{key}-value"] = value }
        attributes
      end

      def stimulus_values
        {
          "resources-url" => helpers.project_resource_planner_view_work_package_timeline_resources_path(
            @project, @resource_planner, @view, format: :json
          ),
          "events-url" => helpers.project_resource_planner_view_work_package_timeline_events_path(
            @project, @resource_planner, @view, format: :json
          ),
          "locale" => I18n.locale.to_s,
          "first-day" => (Setting.start_of_week.presence || 1).to_i,
          "initial-date" => Date.current.iso8601,
          "initial-view" => Granularity.default_view,
          "license-key" => "GPL-My-Project-Is-Open-Source",
          "can-allocate" => can_allocate?,
          "new-allocation-url" => new_allocation_url
        }
      end

      def can_allocate?
        helpers.current_user.allowed_in_project?(:allocate_user_resources, @project)
      end

      # The timeline appends the work package and date range as query params,
      # consumed by #74141.
      def new_allocation_url
        return "" unless can_allocate?

        helpers.new_project_resource_allocation_path(@project)
      end
    end
  end
end
