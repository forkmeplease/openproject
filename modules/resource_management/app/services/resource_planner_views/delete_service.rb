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

module ResourcePlannerViews
  # Destroying the view also tears down its dependents: the backing query is
  # removed by PersistedView#destroy_query_if_orphaned (which cascades to the
  # query's ordered_work_packages at the database level) and favorites are
  # cleaned up by acts_as_favoritable.
  class DeleteService < ::BaseServices::Delete
    private

    # Keep the parent planner consistent: if the deleted view was its default,
    # repoint the default at a remaining view (or clear it).
    def after_perform(call)
      return call unless call.success?

      planner = call.result.parent
      if planner.is_a?(ResourcePlanner) && planner.default_view_id == call.result.id
        planner.update!(default_view_id: planner.children.reload.first&.id)
      end

      call
    end
  end
end
