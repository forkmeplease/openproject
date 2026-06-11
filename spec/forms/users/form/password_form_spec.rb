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

RSpec.describe Users::Form::PasswordForm, type: :forms do
  include_context "with rendered form"

  let(:model) { build_stubbed(:user) }
  let(:params) { { user: model, assign_random_password_checked: false } }

  before { allow(model).to receive(:change_password_allowed?).and_return(true) }

  it "renders one wrapper carrying the three controllers and the passwordFields target" do
    expect(page).to have_css(
      "[data-controller~='disable-when-checked'][data-controller~='password-force-change']" \
      "[data-controller~='password-requirements'][data-admin--users-target='passwordFields']",
      visible: :all
    )
  end

  it "renders the password fields with their ids and password type" do
    expect(page).to have_field("user[password]", type: "password", visible: :all)
    expect(page).to have_field("user[password_confirmation]", type: "password", visible: :all)
    expect(page).to have_css("#user_password", visible: :all)
  end

  it "renders the unscoped send_information checkbox and the scoped flags" do
    expect(page).to have_field("send_information", visible: :all)
    expect(page).to have_css("#send_information", visible: :all)
    expect(page).to have_field("user[assign_random_password]", visible: :all)
    expect(page).to have_field("user[force_password_change]", visible: :all)
  end
end
