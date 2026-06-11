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
  module Form
    # LDAP authentication source select. For a new record it also renders the
    # hidden login field the admin--users controller reveals when an LDAP source
    # is selected; for a persisted record the login is already a built-in field,
    # so the select is wrapped in a titled "Authentication" fieldset only.
    #
    # The coordinator decides whether to include this form at all.
    class AuthenticationSourceForm < ApplicationForm
      form do |f|
        if @user.new_record?
          ldap_auth_source_select(f)
          hidden_login(f)
        else
          f.fieldset_group(title: I18n.t(:label_authentication)) do |group|
            ldap_auth_source_select(group)
          end
        end
      end

      def initialize(user:)
        super()
        @user = user
      end

      private

      def ldap_auth_source_select(target)
        target.select_list(
          name: :ldap_auth_source_id,
          label: User.human_attribute_name(:auth_source),
          include_blank: I18n.t(:label_internal),
          input_width: :medium,
          data: { action: "admin--users#toggleAuthenticationFields" }
        ) do |list|
          LdapAuthSource.order(:name).each { |source| list.option(label: source.name, value: source.id) }
        end
      end

      def hidden_login(form)
        form.group(hidden: true, data: { "admin--users-target": "authSourceFields" }) do |group|
          group.text_field(name: :login,
                           label: User.human_attribute_name(:login),
                           required: true,
                           input_width: :medium)
        end
      end
    end
  end
end
