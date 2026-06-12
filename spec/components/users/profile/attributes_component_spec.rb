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

RSpec.describe Users::Profile::AttributesComponent, type: :component do
  shared_let(:logged_in_user) { create(:user) }
  let(:user) { build(:user) }
  let(:component) { described_class.new(user:) }

  current_user { logged_in_user }

  describe "render?" do
    subject { component.render? }

    context "when user has view_user_email permission" do
      before { create(:standard_global_role) }

      it { is_expected.to be(true) }
    end

    context "when user views its own profile" do
      current_user { user }

      it { is_expected.to be(true) }
    end

    context "when user cannot see the email" do
      it { is_expected.to be(false) }
    end
  end
end
