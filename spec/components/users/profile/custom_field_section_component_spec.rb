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

require "rails_helper"

RSpec.describe Users::Profile::CustomFieldSectionComponent, type: :component do
  let(:section) { create(:user_custom_field_section, name: "Profile info") }
  let(:custom_field) { create(:user_custom_field, :string, user_custom_field_section: section) }
  let(:user) { create(:user, custom_values: [build(:custom_value, custom_field:, value: "Hello custom field")]) }
  let(:component) { described_class.new(section:, fields: [custom_field], user:) }

  current_user { build(:admin) }

  before { render_inline(component) }

  it "renders the field value" do
    expect(page).to have_text("Hello custom field")
  end

  it "renders the section name as a heading" do
    expect(page).to have_text("Profile info")
  end

  context "with an untitled section" do
    let(:section) { create(:user_custom_field_section).tap { |s| s.update_column(:name, nil) } }

    it "renders the I18n fallback label" do
      expect(page).to have_text(I18n.t("settings.user_custom_fields.label_untitled_section"))
    end
  end

  context "with a multi-select field" do
    let(:custom_field) { create(:user_custom_field, :multi_list, user_custom_field_section: section) }
    let(:user) do
      create(:user, custom_values: custom_field.possible_values.first(3).map do |v|
        build(:custom_value, custom_field:, value: v)
      end)
    end

    it "renders each value as a label" do
      expect(page).to have_css("span.Label", text: "A")
      expect(page).to have_css("span.Label", text: "B")
      expect(page).to have_css("span.Label", text: "C")
    end
  end

  context "with a formattable text field" do
    let(:custom_field) { create(:user_custom_field, :text, user_custom_field_section: section) }
    let(:user) { create(:user, custom_values: [build(:custom_value, custom_field:, value: "This is **formatted** text.")]) }

    it "renders the value as HTML" do
      expect(page).to have_css("strong", text: "formatted")
    end
  end
end
