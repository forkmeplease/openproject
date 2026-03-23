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
  module Groups
    class GroupHierarchyLayoutComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      attr_reader :groups, :active_group

      def initialize(groups:, active_group: nil)
        super()
        @groups = groups
        @active_group = active_group
      end

      def render_group_tree(tree, parent_id: nil)
        children_for(parent_id).each do |group|
          if children?(group)
            tree.with_sub_tree(label: group.name) do |sub_tree|
              render_group_tree(sub_tree, parent_id: group.id)
            end
          else
            tree.with_leaf(label: group.name)
          end
        end
      end

      private

      def children_by_parent_id
        @children_by_parent_id ||= groups.group_by(&:parent_id)
      end

      def children_for(parent_id)
        children_by_parent_id[parent_id] || []
      end

      def children?(group)
        children_by_parent_id.key?(group.id)
      end
    end
  end
end
