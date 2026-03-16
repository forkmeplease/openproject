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

require_relative "../../flash/expectations"

module Components
  module Common
    class InplaceEditField
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      attr_reader :model, :attribute, :show_in_dialog, :model_class

      def initialize(model, attribute, show_in_dialog: false)
        @model = model
        @attribute = attribute
        @show_in_dialog = show_in_dialog
        if show_in_dialog
          @dialog = InplaceEditFields::Dialog.new(model, attribute)
        end

        @model_class = @model.class.name.parameterize(separator: "_")
      end

      def open_field
        within_field do
          # Link and user type custom fields might contain a clickable link inside the edit container.
          # Use JavaScript to directly trigger the click event on the container to avoid nested links.
          page.execute_script(
            "document.querySelector('[data-test-selector=\"op-inplace-edit-field--#{model_class}-#{model.id}--#{attribute.name}\"] .op-inplace-edit--display-field').click()"
          )
        end
      end

      def expect_open
        if show_in_dialog
          dialog.expect_open
        else
          within_field do
            expect(page).to have_test_selector("op-inplace-edit-field--form")
          end
        end
      end

      def close
        if show_in_dialog
          dialog.close
        else
          # todo
        end
      end

      def expect_field_label_with_help_text(label_text)
        expect_field_label(label_text)
        expect(find_field_label(label_text)).to have_link accessible_name: "Show help text"
      end

      def expect_field_label_without_help_text(label_text)
        expect_field_label(label_text)
        expect(find_field_label(label_text)).to have_no_link accessible_name: "Show help text"
      end

      def click_help_text_link_for_label(label_text)
        link = find_field_label(label_text).find(:link, accessible_name: "Show help text")
        link.click
      end

      def fill_and_submit_value(name, val)
        fill_in(name, with: val).send_keys(:return)
        wait_for_network_idle
      end

      def fill_and_submit_value_via_button(name:, val:, ckeditor: false)
        within_field do
          if ckeditor
            find(".ck-content").base.send_keys val
          else
            fill_in(name, with: val)
          end
          click_on "Save"
        end
      end

      def dialog
        @dialog
      end

      def within_field(&)
        page.within_test_selector("op-inplace-edit-field--#{model_class}-#{model.id}--#{attribute.name}", &)
      end

      private

      def expect_field_label(label_text)
        expect(page).to have_element :label, text: label_text
      end

      def find_field_label(label_text)
        page.find(:element, :label, text: label_text)
      end
    end
  end
end
