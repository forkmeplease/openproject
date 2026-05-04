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

module ResourcePlanners
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    delegate :current_project, to: :table
    delegate :project, to: :model

    def name
      icon = if model.favorited_by?(User.current)
               render(Primer::Beta::Octicon.new(icon: :"star-fill", color: :attention, mr: 2))
             end

      link = render(Primer::Beta::Link.new(
                      href: project_resource_planner_path(project, model),
                      font_weight: :bold
                    )) { model.name }

      safe_join([icon, link].compact)
    end

    def work_packages
      # TODO: Implement a proper count
      "—"
    end

    def members
      # TODO: Implement a proper count
      "—"
    end

    def start_date
      helpers.format_date(model.start_date) if model.start_date.present?
    end

    def finish_date
      helpers.format_date(model.end_date) if model.end_date.present?
    end

    def button_links
      [action_menu_placeholder]
    end

    def action_menu_placeholder
      render(Primer::Beta::IconButton.new(icon: "kebab-horizontal", "aria-label": t(:label_more), scheme: :invisible))
    end
  end
end
