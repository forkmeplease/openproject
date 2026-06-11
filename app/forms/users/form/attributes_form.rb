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
    # Admin flag + the custom-field sections (built-in fields interleaved with
    # custom fields per UserCustomFieldSection, honoring attribute_order).
    class AttributesForm < ApplicationForm
      include CustomFields::CustomFieldRendering

      form do |f|
        admin_flag(f) if User.current.admin?
        user_sections(f)
      end

      def initialize(user:, contract:)
        super()
        @user = user
        @contract = contract
      end

      private

      def custom_fields
        @custom_fields ||= @user.available_custom_fields
      end

      def admin_flag(form)
        form.check_box(name: :admin,
                       label: User.human_attribute_name(:admin),
                       disabled: @user == User.current)
      end

      def user_sections(form)
        UserCustomFieldSection.includes(:custom_fields).each do |section| # rubocop:disable Rails/FindEach -- honor default scope ordering
          render_section(form, section)
        end
      end

      def render_section(form, section)
        visible_cfs_by_key = section.custom_fields.visible(User.current).index_by(&:column_name)

        form.fieldset_group(title: section_title(section)) do |group|
          section.attribute_order.each do |key|
            if UserCustomFieldSection::BUILT_IN_ATTRIBUTES.include?(key)
              render_built_in(group, key)
            elsif (custom_field = visible_cfs_by_key[key])
              render_custom_field(form: group, custom_field:)
            end
          end
        end
      end

      def section_title(section)
        section.name.presence || I18n.t("settings.user_custom_fields.label_untitled_section")
      end

      def render_built_in(group, key) # rubocop:disable Metrics/AbcSize
        case key
        when "firstname", "lastname", "mail"
          group.text_field(name: key.to_sym,
                           label: User.human_attribute_name(key),
                           required: true,
                           disabled: !@contract.writable?(key.to_sym),
                           input_width: :medium)
        when "login"
          return if @user.new_record?

          group.text_field(name: :login,
                           label: User.human_attribute_name(:login),
                           required: true,
                           disabled: !@contract.writable?(:login),
                           input_width: :medium)
        when "language"
          group.select_list(name: :language,
                            label: User.human_attribute_name(:language),
                            include_blank: "--- #{I18n.t(:actionview_instancetag_blank_option)} ---",
                            input_width: :medium) do |list|
            helpers.lang_options_for_select.each { |label, value| list.option(label:, value:) }
          end
        end
      end
    end
  end
end
