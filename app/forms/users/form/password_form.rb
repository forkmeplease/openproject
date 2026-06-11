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
    # The internal password / activation block as a single Primer group. All three
    # Stimulus controllers sit on the wrapper: the password-requirements controller
    # finds both its passwordInput and requirement targets within it.
    # assign_random_password and send_information are not model
    # attributes, so they render with an explicit checked: and no hidden companion
    # (the controller relies on their absence when unchecked); send_information is
    # unscoped (top-level param). Included by the coordinator only for editing an
    # internal user as admin while password login is enabled.
    class PasswordForm < ApplicationForm
      form do |f|
        f.group(
          hidden: !@user.change_password_allowed?,
          data: {
            controller: "disable-when-checked password-force-change password-requirements",
            "admin--users-target": "passwordFields"
          }
        ) do |group|
          assign_random_password(group)
          password_fields(group) unless disable_password_choice?
          send_information(group)
          force_password_change(group)
        end
      end

      def initialize(user:, assign_random_password_checked:)
        super()
        @user = user
        @assign_random_password_checked = assign_random_password_checked
      end

      private

      def disable_password_choice?
        OpenProject::Configuration.disable_password_choice?
      end

      def assign_random_password(group)
        group.check_box(name: :assign_random_password,
                        id: "user_assign_random_password",
                        checked: @assign_random_password_checked,
                        include_hidden: false,
                        label: I18n.t("user.assign_random_password"),
                        data: {
                          "disable-when-checked-target": "cause",
                          "password-force-change-target": "assignRandomPassword"
                        })
      end

      def password_fields(group)
        group.text_field(name: :password,
                         id: "user_password",
                         type: :password,
                         required: @user.new_record?,
                         label: User.human_attribute_name(:password),
                         caption: helpers.password_complexity_requirements,
                         input_width: :medium,
                         data: {
                           "disable-when-checked-target": "effect",
                           "password-requirements-target": "passwordInput"
                         })
        group.text_field(name: :password_confirmation,
                         id: "user_password_confirmation",
                         type: :password,
                         required: @user.new_record?,
                         label: User.human_attribute_name(:password_confirmation),
                         input_width: :medium,
                         data: { "disable-when-checked-target": "effect" })
      end

      def send_information(group)
        group.check_box(name: :send_information,
                        id: "send_information",
                        scope_name_to_model: false,
                        scope_id_to_model: false,
                        checked: false,
                        include_hidden: false,
                        label: I18n.t(:label_send_information),
                        caption: I18n.t("users.send_information_hint"),
                        data: { "password-force-change-target": "sendInformationCheckbox" })
      end

      def force_password_change(group)
        group.check_box(name: :force_password_change,
                        id: "user_force_password_change",
                        checked: @user.force_password_change,
                        label: User.human_attribute_name(:force_password_change),
                        caption: I18n.t("users.force_password_change_hint"),
                        data: { "password-force-change-target": "forceChangeCheckbox" })
      end
    end
  end
end
