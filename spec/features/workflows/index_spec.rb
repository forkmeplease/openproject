# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Workflows index" do
  include Toasts::Expectations

  let(:admin)  { create(:admin) }
  let!(:types) { create_list(:type, 3) }

  current_user { admin }

  before do
    visit url_for(controller: "/workflows", action: :index)
  end

  it "lists all the types" do
    expect(page).to have_heading("Workflows")

    within "[role=table]" do
      expect(page).to have_css(".Box-row[role=row]", count: 3)
      types.each do |type|
        expect(page).to have_css(".Box-row[role=row] a[href='#{edit_workflow_path(type)}']", text: type.name)
      end
    end
  end

  it "allows navigating to Workflow summary page" do
    within ".PageHeader-actions" do
      click_on "Summary"
    end

    expect(page).to have_heading "Summary"
    expect(page).to have_current_path(summarized_workflows_path)
  end

  it "allows navigating to Workflow copy page" do
    within ".PageHeader-actions" do
      click_on "Copy"
    end

    expect(page).to have_heading "Copy workflow"
    expect(page).to have_current_path(copy_workflows_path)
  end
end
