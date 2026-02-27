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
    class ScheduleRowComponent < OpPrimer::BorderBoxRowComponent
      def working_hours
        model
      end

      def start_date
        helpers.format_date(working_hours.valid_from)
      end

      def work_days
        working_hours.working_days_summary
      end

      def work_hours
        formatted = helpers.number_with_precision(working_hours.weekly_working_hours,
                                                  precision: 2,
                                                  strip_insignificant_zeros: true,
                                                  separator: I18n.t("number.format.separator"))
        "#{formatted}h"
      end

      def availability_factor
        "#{working_hours.availability_factor}%"
      end

      def effective_work_hours
        "#{working_hours.effective_weekly_working_hours}h"
      end

      def button_links
        [action_menu]
      end

      def action_menu
        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button(icon: "kebab-horizontal",
                                "aria-label": t(:label_more),
                                scheme: :invisible)

          menu.with_item(label: t(:button_edit), href: "#", tag: :a) do |item|
            item.with_leading_visual_icon(icon: :pencil)
          end

          menu.with_item(label: t(:button_delete), href: "#", tag: :a, scheme: :danger) do |item|
            item.with_leading_visual_icon(icon: :trash)
          end
        end
      end
    end
  end
end
