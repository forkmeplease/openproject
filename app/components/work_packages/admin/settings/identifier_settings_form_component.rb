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
#

module WorkPackages
  module Admin
    module Settings
      class IdentifierSettingsFormComponent < ApplicationComponent
        include OpPrimer::FormHelpers

        attr_reader :projects_data, :total_count

        def initialize
          super
          # FIXME: Replace WHERE clause with:
          #   Project.where.not(id: OldProjectIdentifier.where(current: true).select(:project_id))
          # once all valid identifiers have been migrated to handle rows.
          problematic_scope = Project.where(
            "length(identifier) > ? OR identifier ~ ?",
            WorkPackages::ProjectHandleSuggestionGenerator::HANDLE_MAX_LENGTH,
            "[^a-zA-Z0-9]"
          )

          @total_count = problematic_scope.count
          preview_projects = problematic_scope
            .select(:id, :name, :identifier)
            .limit(WorkPackages::Admin::Settings::IdentifierAutofixSectionComponent::DISPLAY_COUNT)
            .to_a

          in_use_handles = Project.where.not(id: problematic_scope.select(:id)).pluck(:identifier).to_set
          # TODO: Replace with OldProjectIdentifier.pluck(:identifier).to_set
          # once the OldProjectIdentifier model and migration are added.
          reserved_handles = Set.new

          @projects_data = WorkPackages::ProjectHandleSuggestionGenerator.call(
            preview_projects,
            in_use_handles:,
            reserved_handles:
          )
        end

        def has_problematic_projects?
          total_count > 0
        end

        private

        def show_autofix_section?
          Setting::WorkPackageIdentifier.alphanumeric? && has_problematic_projects?
        end
      end
    end
  end
end
