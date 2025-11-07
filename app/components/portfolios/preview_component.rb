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

module Portfolios
  class PreviewComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include WorkspaceHelper

    def initialize(portfolio:, current_user:)
      super
      @portfolio = portfolio
      @current_user = current_user
    end

    def currently_favorited?
      false
    end

    def program_count_label
      program_count = all_descendants(@portfolio).filter { it.workspace_type == "program" }.count

      I18n.t("program.count", count: program_count)
    end

    def project_count_label
      project_count = all_descendants(@portfolio).filter { it.workspace_type == "project" }.count

      I18n.t("project.count", count: project_count)
    end

    def budget_label
      "34,000 EUR budget - 12,000 EUR spent"
    end

    def updated_at_label
      I18n.t(:label_updated_time, value: distance_of_time_in_words(Time.current, @portfolio.updated_at))
    end

    private

    def all_descendants(project = @portfolio)
      return @descendants if defined?(@descendants)

      @descendants = Set.new
      stack = [project]

      until stack.empty?
        current = stack.pop
        current.descendants.each { stack.push(it) }

        @descendants.add(current) unless current == project
      end

      @descendants
    end
  end
end
