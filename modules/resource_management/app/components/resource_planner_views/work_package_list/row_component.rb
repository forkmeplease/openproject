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

module ResourcePlannerViews::WorkPackageList
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    alias_method :work_package, :model

    # The type / id / status info line stacked above the linked subject.
    def subject
      safe_join(
        [
          render(WorkPackages::InfoLineComponent.new(work_package:, show_status: true)),
          render(
            Primer::Beta::Link.new(
              href: helpers.url_for(controller: "/work_packages", action: "show", id: work_package),
              font_weight: :bold,
              underline: false
            )
          ) { work_package.subject }
        ]
      )
    end

    def priority
      return if work_package.priority.blank?

      render(
        Primer::Beta::Text.new(
          tag: :span,
          classes: "__hl_inline_priority_#{work_package.priority.id} __hl_inline__small_dot"
        )
      ) { work_package.priority.name }
    end

    def dates
      return if work_package.start_date.blank? && work_package.due_date.blank?

      render(WorkPackages::HighlightedDateComponent.new(work_package:))
    end

    # Placeholder until allocation data is available.
    def allocation
      render(Primer::Beta::Text.new(color: :muted)) { allocation_placeholder }
    end

    # Placeholder until allocated members are available.
    def allocated_members
      render(Primer::Beta::Text.new(color: :muted)) { allocation_placeholder }
    end

    def button_links
      [context_menu]
    end

    private

    def allocation_placeholder
      I18n.t("resource_management.work_package_list.allocation_placeholder")
    end

    # Stubbed context menu mirroring the intended actions. Each item gets its own
    # method so it can be wired up individually later. None are functional yet.
    def context_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal",
                              "aria-label": t("resource_management.work_package_list.context_menu.label"),
                              scheme: :invisible)

        see_allocation_item(menu)
        edit_total_work_item(menu)
        add_user_group_item(menu)
        add_filter_criteria_item(menu)
        move_item(menu)
        remove_item(menu)
      end
    end

    def see_allocation_item(menu)
      menu.with_item(label: t("resource_management.work_package_list.context_menu.see_allocation"),
                     disabled: true) do |item|
        item.with_leading_visual_icon(icon: :hourglass)
      end
    end

    def edit_total_work_item(menu)
      menu.with_item(label: t("resource_management.work_package_list.context_menu.edit_total_work"),
                     disabled: true) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def add_user_group_item(menu)
      menu.with_item(label: t("resource_management.work_package_list.context_menu.add_user_group"),
                     disabled: true) do |item|
        item.with_leading_visual_icon(icon: :"person-add")
      end
    end

    def add_filter_criteria_item(menu)
      menu.with_item(label: t("resource_management.work_package_list.context_menu.add_filter_criteria"),
                     disabled: true) do |item|
        item.with_leading_visual_icon(icon: :plus)
      end
    end

    def move_item(menu)
      menu.with_item(label: t("resource_management.work_package_list.context_menu.move"),
                     disabled: true) do |item|
        item.with_leading_visual_icon(icon: :"arrow-right")
      end
    end

    def remove_item(menu)
      menu.with_item(label: t("resource_management.work_package_list.context_menu.remove"),
                     scheme: :danger,
                     disabled: true) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end
  end
end
