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

require_relative "../spec_helper"

RSpec.describe BudgetsController do
  describe "#update_labor_budget_item" do
    let(:project) { create(:project) }
    let(:current_user) { create(:user, member_with_permissions: { project => [:view_hourly_rates] }) }
    let(:project_member) { create(:user, member_with_permissions: { project => [] }) }
    let(:non_member) { create(:user) }
    let(:element_id) { "labor_budget_item_1" }

    before { login_as(current_user) }

    context "when the referenced user is a project member" do
      let!(:hourly_rate) { create(:hourly_rate, user: project_member, project:, rate: 100.0, valid_from: Time.zone.today) }

      it "calculates costs based on the member's hourly rate" do
        get :update_labor_budget_item,
            format: :json,
            params: { project_id: project.id, user_id: project_member.id, hours: "2",
                      fixed_date: Time.zone.today.to_s, element_id: }

        json = response.parsed_body
        expect(json["#{element_id}_cost_value"]).to eq("200.00")
      end
    end

    context "when the referenced user is not a project member" do
      let!(:hourly_rate) { create(:hourly_rate, user: non_member, project:, rate: 100.0, valid_from: Time.zone.today) }

      it "returns zero costs" do
        get :update_labor_budget_item,
            format: :json,
            params: { project_id: project.id, user_id: non_member.id, hours: "2",
                      fixed_date: Time.zone.today.to_s, element_id: }

        json = response.parsed_body
        expect(json["#{element_id}_cost_value"]).to eq("0.00")
      end
    end
  end
end
