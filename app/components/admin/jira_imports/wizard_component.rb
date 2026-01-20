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

module Admin
  module JiraImports
    class WizardComponent < ApplicationComponent
      include ApplicationHelper
      include Turbo::FramesHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def self.wrapper_key = :jira_imports_wizard

      def initialize(model, **options)
        super
        @import_settings = [
          { label: "4 projects", caption: "Including only name and key", value: "projects", checked: true },
          { label: "233 issues ", caption: "Includes only name, title and description", value: "issues", checked: true },
          { label: "12 users", caption: "Includes only name, email and project membership", value: "users", checked: true },
          { label: "5 statuses", caption: "Does not include workflows", value: "statuses", checked: true },
          { label: "11 types", caption: "Types are attached to projects", value: "types", checked: true }
        ]
        @import_stats_available = [
          { label: "4 projects", checked: true },
          { label: "233 issues (name, title and description)", checked: true },
          { label: "12 users", checked: true },
          { label: "5 statuses", checked: true },
          { label: "11 types", checked: true }
        ]
        @import_stats_unavailable = [
          { label: "Relations between issues", checked: false },
          { label: "Attachments in issues", checked: false },
          { label: "Custom workflow", checked: false },
          { label: "User, group and project permissions", checked: false }
        ]
      end
    end
  end
end
