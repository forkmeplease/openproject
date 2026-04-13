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

module OpenProject::Backlogs::List
  extend ActiveSupport::Concern

  included do
    acts_as_list touch_on_update: false

    # acts as list adds a before destroy hook which messes
    # with the parent_id_was value
    skip_callback(:destroy, :before, :reload)

    private

    # Used by acts_list to limit the list to a certain subset within
    # the table.
    def scope_condition
      { project_id:, sprint_id: }
    end

    # acts_as_list needs to know when a work package moved between backlog/sprint scopes
    # so it can reorder both the source and target lists correctly.
    def scope_changed?
      (scope_condition.keys & changed.map(&:to_sym)).any?
    end

    # Copied from acts_as_list to support our custom hash-based scope condition.
    def destroyed_via_scope?
      return false unless destroyed_by_association

      foreign_key = destroyed_by_association.foreign_key
      if foreign_key.is_a?(Array)
        (scope_condition.keys & foreign_key.map(&:to_sym)).any?
      else
        scope_condition.keys.include?(foreign_key.to_sym)
      end
    end

    include InstanceMethods
  end

  module InstanceMethods
    def move_after(position: nil, prev_id: nil)
      if acts_as_list_list.all?(position: nil)
        # If no items have a position, create an order on position
        # silently. This can happen when sorting inside a version for the first
        # time after backlogs was activated and there have already been items
        # inside the version at the time of backlogs activation
        set_default_prev_positions_silently(acts_as_list_list.last)
      end

      # Remove so the potential 'prev' has a correct position
      remove_from_list
      reload
      id_or_position = position ? { position: position - 1 } : { id: prev_id }

      prev = acts_as_list_list.find_by(**id_or_position)

      if prev.blank?
        # If it should be the first story, move it to the 1st position
        insert_at
        move_to_top
      else
        # There's a valid predecessor
        insert_at(prev.position + 1)
      end
    end

    protected

    # Override acts_as_list implementation to avoid it calling save.
    # Calling save would remove the changes/saved_changes information.
    def set_list_position(new_position, _raise_exception_if_save_fails = false) # rubocop:disable Style/OptionalBooleanParameter
      update_columns(position: new_position)
    end

    def set_default_prev_positions_silently(prev)
      return if prev.nil?

      WorkPackages::RebuildPositionsService.new(project: prev.project).call

      prev.reload.position
    end
  end
end
