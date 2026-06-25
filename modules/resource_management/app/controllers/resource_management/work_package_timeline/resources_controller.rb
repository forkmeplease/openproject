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

module ResourceManagement
  module WorkPackageTimeline
    # Feeds the FullCalendar resources (rows): one per work package in the view.
    class ResourcesController < FeedsController
      def index
        resources = @view.work_packages.map do |work_package|
          {
            id: work_package.id,
            title: work_package.subject,
            extendedProps: { html: render_cell(work_package) }
          }
        end

        render json: { resources: }
      end

      private

      def render_cell(work_package)
        ResourcePlannerViews::WorkPackageTimeline::ResourceCellComponent
          .new(work_package:, allocations: allocations_for(work_package),
               project: @project, resource_planner: @resource_planner, view: @view)
          .render_in(view_context)
      end

      def allocations_for(work_package)
        allocations_by_work_package.fetch(work_package.id, [])
      end
    end
  end
end
