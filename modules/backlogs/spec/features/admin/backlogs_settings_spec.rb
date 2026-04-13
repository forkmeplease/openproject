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

RSpec.describe "Backlogs Admin Settings", :js do
  let!(:type1) { create(:type, name: "Story", position: 1) }
  let!(:type2) { create(:type_feature,        position: 2) }
  let!(:type3) { create(:type_task,           position: 3) }
  let!(:type4) { create(:type_milestone,      position: 4) }

  let(:story_autocompleter) { FormFields::Primerized::AutocompleteField.new("story_types", selector: "[data-test-selector='story_type_autocomplete']") }
  let(:task_autocompleter) { FormFields::Primerized::AutocompleteField.new("story_types", selector: "[data-test-selector='task_type_autocomplete']") }

  let(:current_user) { create(:admin) }

  before do
    login_as current_user

    visit admin_backlogs_settings_path
  end

  it "shows the sprint planning blankslate instead of legacy configuration" do
    expect(page).to have_no_field "Template for sprint wiki page"
    expect(page).to have_no_css "[data-test-selector='story_type_autocomplete']"
    expect(page).to have_no_css "[data-test-selector='task_type_autocomplete']"
    expect(page).to have_no_css "fieldset", text: "Points burn up/down"

    expect(page).to have_content "Backlog admin settings are evolving"
  end
end
