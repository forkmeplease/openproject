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

module Projects
  class ManageMembershipsFromCustomFieldsService < ::BaseServices::BaseCallable
    attr_reader :project, :user, :custom_field

    def initialize(user:, project:, custom_field:)
      super

      @custom_field = custom_field
      @user = user
      @project = project
    end

    private

    def perform
      pp({ custom_field: custom_field, project: project, **params })
      #       # Assuming the members are loaded anyway
      #       user_member = new_project.members.detect { |m| m.principal == user }
      #
      #       if user_member
      #         Members::UpdateService
      #           .new(user:, model: user_member, contract_class: EmptyContract)
      #           .call(role_ids: user_member.role_ids + [role.id])
      #       else
      #         Members::CreateService
      #           .new(user:, contract_class: EmptyContract)
      #           .call(roles: [role], project: new_project, principal: user)
      #       end
    end
  end
end
