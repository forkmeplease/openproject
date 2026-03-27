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
require "spec_helper"

RSpec.describe Workflows::Copies::FromRoleForm, type: :forms do
  include_context "with rendered form"

  let(:model) { false }
  let(:params) { { source_type:, source_role:, all_roles: } }
  let(:source_type) { create(:type) }
  let(:all_roles) { create_list(:project_role, 4) }
  let(:source_role) { nil }

  it "renders the Source role select list" do
    expect(page).to have_select "Source role", required: true do |select|
      options_text = select.all("option").map(&:text)
      expect(options_text).to match_array(all_roles.map(&:name))
    end
  end

  it "renders the Target roles autocompleter" do
    data_attributes = "[data-test-selector=\"target_roles_autocomplete\"][data-multiple=\"true\"]"
    expect(page).to have_css "opce-autocompleter#{data_attributes}" do |autocompleter|
      options_text = JSON.parse(autocompleter["data-items"]).map { |item| item["name"] }
      expect(options_text).to match_array(all_roles.map(&:name))
    end
  end

  it "renders submit button" do
    expect(page).to have_button "Copy", class: "Button--primary"
  end

  describe "when the source type is specified" do
    let(:source_role) { all_roles.sample }

    it "renders the Source role select list with selected source" do
      expect(page).to have_select "Source role", required: true do |select|
        selected_option_text = select.all("option[selected=selected]").map(&:text)
        expect(selected_option_text).to contain_exactly(source_role.name)
      end
    end
  end
end
