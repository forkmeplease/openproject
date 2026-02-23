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

RSpec.describe CustomFields::Scopes::Visible do
  shared_let(:project_cf) { create(:string_project_custom_field) }
  shared_let(:work_package_cf) { create(:string_wp_custom_field) }

  let(:project_cf_visible) { false }
  let(:work_package_cf_visible) { false }

  # Since there would be very many tests here, we break the rule of testing
  # the scope as a black box. Knowing that the scope relies on the individual visible scopes of each
  # custom field class, we test them by selectively enabling/disabling the scopes of each.
  describe ".visible" do
    subject { CustomField.visible(current_user) }

    current_user { build_stubbed(:user) }

    before do
      allow(ProjectCustomField)
        .to receive(:visible)
              .with(current_user)
              .and_return(project_cf_visible ? ProjectCustomField.all : ProjectCustomField.none)
      allow(WorkPackageCustomField)
        .to receive(:visible)
              .with(current_user)
              .and_return(work_package_cf_visible ? WorkPackageCustomField.all : WorkPackageCustomField.none)
    end

    context "for a project custom field" do
      context "if the fields are visible" do
        let(:project_cf_visible) { true }

        it "returns the project custom field" do
          expect(subject).to contain_exactly(project_cf)
        end

        it "calls the visible scope of the project custom field" do
          subject

          expect(ProjectCustomField).to have_received(:visible).with(current_user)
        end
      end

      context "if the fields are invisible" do
        let(:project_cf_visible) { false }

        it "does not return the project custom field" do
          expect(subject).to be_empty
        end
      end
    end

    context "for a work package custom field" do
      context "if the fields are visible" do
        let(:work_package_cf_visible) { true }

        it "returns the work package custom field" do
          expect(subject).to contain_exactly(work_package_cf)
        end

        it "calls the visible scope of the work_package custom field" do
          subject

          expect(WorkPackageCustomField).to have_received(:visible).with(current_user)
        end
      end

      context "if the fields are invisible" do
        let(:work_package_cf_visible) { false }

        it "does not return the work package custom field" do
          expect(subject).to be_empty
        end
      end
    end
  end
end
