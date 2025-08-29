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

RSpec.describe ProjectCustomFieldProjectMappings::ToggleService do
  let!(:project) { create(:project) }
  let!(:project_custom_field_section) { create(:project_custom_field_section, name: "Section with invisible fields") }

  let!(:visible_custom_field) do
    create(:project_custom_field,
           name: "Visible field",
           admin_only: false,
           project_custom_field_section:)
  end

  let!(:required_custom_field) do
    create(:project_custom_field,
           name: "Visible required field",
           admin_only: false,
           is_required: true,
           project_custom_field_section:)
  end

  let!(:invisible_custom_field) do
    create(:project_custom_field,
           name: "Admin only field",
           admin_only: true,
           project_custom_field_section:)
  end

  let(:instance) { described_class.new(user:) }

  let(:visible_custom_field_params) { { project_id: project.id, custom_field_id: visible_custom_field.id } }
  let(:required_custom_field_params) { { project_id: project.id, custom_field_id: required_custom_field.id } }
  let(:invisible_custom_field_params) { { project_id: project.id, custom_field_id: invisible_custom_field.id } }

  context "with admin permissions" do
    let(:user) { create(:admin) }

    it "toggles visible, non-required fields" do
      expect(project.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      2.times do
        expect(instance.call(**visible_custom_field_params, value: "1")).to be_success

        expect(project.reload.project_custom_fields).to contain_exactly(
          required_custom_field, visible_custom_field
        )
      end

      2.times do
        expect(instance.call(**visible_custom_field_params, value: "0")).to be_success

        expect(project.reload.project_custom_fields).to contain_exactly(
          required_custom_field
        )
      end
    end

    it "toggles invisible, non-required fields" do
      expect(project.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      2.times do
        expect(instance.call(**invisible_custom_field_params, value: "1")).to be_success

        expect(project.reload.project_custom_fields).to contain_exactly(
          required_custom_field, invisible_custom_field
        )
      end

      2.times do
        expect(instance.call(**invisible_custom_field_params, value: "0")).to be_success

        expect(project.reload.project_custom_fields).to contain_exactly(
          required_custom_field
        )
      end
    end

    it "does not toggle required fields" do
      expect(project.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**required_custom_field_params, value: "1")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**required_custom_field_params, value: "0")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )
    end
  end

  context "with non-admin but sufficient permissions" do
    let(:user) do
      create(:user,
             firstname: "Project",
             lastname: "Admin",
             member_with_permissions: {
               project => %w[
                 view_work_packages
                 edit_project
                 select_project_custom_fields
               ]
             })
    end

    it "toggles visible, non-required fields" do
      expect(project.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      2.times do
        expect(instance.call(**visible_custom_field_params, value: "1")).to be_success

        expect(project.reload.project_custom_fields).to contain_exactly(
          required_custom_field, visible_custom_field
        )
      end

      2.times do
        expect(instance.call(**visible_custom_field_params, value: "0")).to be_success

        expect(project.reload.project_custom_fields).to contain_exactly(
          required_custom_field
        )
      end
    end

    it "does not toggle invisible, non-required fields" do
      expect(project.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**invisible_custom_field_params, value: "1")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**invisible_custom_field_params, value: "0")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )
    end

    it "does not toggle required fields" do
      expect(project.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**required_custom_field_params, value: "1")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**required_custom_field_params, value: "0")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )
    end
  end

  context "with insufficient permissions" do
    let(:user) do
      create(:user,
             firstname: "Project",
             lastname: "Editor",
             member_with_permissions: {
               project => %w[
                 view_work_packages
                 edit_project
               ]
             })
    end

    it "does not toggle visible, non-required fields" do
      expect(project.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**visible_custom_field_params, value: "1")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**visible_custom_field_params, value: "0")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )
    end

    it "does not toggle invisible, non-required fields" do
      expect(project.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**invisible_custom_field_params, value: "1")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**invisible_custom_field_params, value: "0")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )
    end

    it "does not toggle required fields" do
      expect(project.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**required_custom_field_params, value: "1")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )

      expect(instance.call(**required_custom_field_params, value: "0")).to be_failure

      expect(project.reload.project_custom_fields).to contain_exactly(
        required_custom_field
      )
    end
  end
end
