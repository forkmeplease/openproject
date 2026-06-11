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

require "spec_helper"

RSpec.describe Users::Form::AuthenticationSourceForm, type: :forms do
  before do
    User.current = build_stubbed(:admin)
    create(:ldap_auth_source)
  end

  include_context "with rendered form"

  let(:params) { { user: model } }

  context "for a new user" do
    let(:model) { User.new }

    it "renders the auth source select with the toggle action and a hidden login group" do
      expect(page).to have_select("user[ldap_auth_source_id]")
      expect(page).to have_css("[data-action~='admin--users#toggleAuthenticationFields']")
      expect(page).to have_css("[data-admin--users-target='authSourceFields'][hidden]", visible: :all)
      expect(page).to have_field("user[login]", visible: :all)
    end
  end

  context "for a persisted user" do
    let(:model) { build_stubbed(:user) }

    it "renders the select inside a titled Authentication fieldset and no hidden login" do
      expect(page).to have_select("user[ldap_auth_source_id]")
      expect(page).to have_css("fieldset", text: /#{I18n.t(:label_authentication)}/i)
      expect(page).to have_no_css("[data-admin--users-target='authSourceFields']", visible: :all)
    end
  end
end
