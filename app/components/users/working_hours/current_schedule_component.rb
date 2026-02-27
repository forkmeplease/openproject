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

module Users
  module WorkingHours
    class CurrentScheduleComponent < ApplicationComponent
      def initialize(working_hours:, **)
        super(working_hours, **)
        @working_hours = working_hours
      end

      def working_hours
        @working_hours
      end

      def working_day_count
        UserWorkingHours::DAYS.count { |day| working_hours.public_send(day) > 0 }
      end

      def working_days_label
        working_hours.working_day_ranges
      end

      def availability_label
        "#{working_hours.availability_factor}%"
      end

      def weekly_hours_label
        format_hours(working_hours.weekly_working_hours)
      end

      def effective_hours_label
        format_hours(working_hours.effective_weekly_working_hours)
      end

      private

      def format_hours(hours)
        formatted = helpers.number_with_precision(hours,
                                                  precision: 2,
                                                  strip_insignificant_zeros: true,
                                                  separator: I18n.t("number.format.separator"))
        "#{formatted}h"
      end
    end
  end
end
