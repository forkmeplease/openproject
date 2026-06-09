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

module ResourceAllocations
  module WarningStep
    # Final confirmation step shown before an allocation is created. It hosts the
    # "outside dates" and "overbooking" warnings; either or both may be present.
    class FormComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(allocation:, project:, allocation_kind:, form_values:, overbooked_ranges: [],
                     daily_working_minutes: nil, filters: nil)
        super
        @allocation = allocation
        @project = project
        @allocation_kind = allocation_kind
        @form_values = form_values
        @overbooked_ranges = overbooked_ranges
        @daily_working_minutes = daily_working_minutes
        @filters = filters
      end

      def wrapper_key
        ResourceAllocations::NewDialogComponent::BODY_ID
      end

      def schedule_violation?
        @allocation.schedule_violation.present?
      end

      def overbooked?
        @overbooked_ranges.any?
      end

      private

      def outside_dates_heading
        t("resource_management.allocate_resource_dialog.outside_dates.title")
      end

      def outside_dates_description
        t(
          "resource_management.allocate_resource_dialog.outside_dates.description",
          resource_dates: date_range(@allocation.start_date, @allocation.end_date),
          work_package_dates: date_range(@allocation.entity_start_date, @allocation.entity_due_date)
        )
      end

      def outside_dates_confirmation
        t("resource_management.allocate_resource_dialog.outside_dates.confirm_#{@allocation.schedule_violation}")
      end

      def overbooking_heading
        t("resource_management.allocate_resource_dialog.overbooking.title")
      end

      def overbooking_description
        t(
          "resource_management.allocate_resource_dialog.overbooking.description",
          user: @allocation.principal.name,
          hours: format_hours(@daily_working_minutes)
        )
      end

      # The work package for each forced item, restricted to those the current
      # user may see. Items for unreadable work packages render anonymously.
      def work_packages_by_id
        @work_packages_by_id ||=
          WorkPackage
            .visible(User.current)
            .where(id: @overbooked_ranges.flat_map(&:work_package_ids).uniq)
            .index_by(&:id)
      end

      def work_package_for(item)
        work_packages_by_id[item.work_package_id]
      end

      # The label for a forced item's row. Items whose work package the user may
      # not see are shown anonymously to avoid leaking subjects across projects.
      def work_package_label(item)
        work_package = work_package_for(item)
        return t("resource_management.allocate_resource_dialog.overbooking.other_allocation") if work_package.nil?

        "#{work_package.type.name} #{work_package.subject}"
      end

      def candidate?(item)
        item.id == ResourceAllocations::Availability::CANDIDATE_ID
      end

      def date_range(from_date, to_date)
        "#{format_or_dash(from_date)} - #{format_or_dash(to_date)}"
      end

      def format_or_dash(date)
        date.present? ? helpers.format_date(date) : "—"
      end

      def format_hours(minutes)
        hours = minutes.to_f / 60
        formatted = hours == hours.to_i ? hours.to_i : hours.round(2)
        "#{formatted}h"
      end
    end
  end
end
