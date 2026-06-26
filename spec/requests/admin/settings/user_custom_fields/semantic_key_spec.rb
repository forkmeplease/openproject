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

RSpec.describe "Admin user custom field semantic key",
               :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:section) { create(:user_custom_field_section) }

  before { login_as(admin) }

  describe "GET new" do
    it "renders the semantic key select with the job title option" do
      get new_admin_settings_user_custom_field_path(field_format: "string")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("job_title")
      expect(response.body).to include("Semantic meaning")
    end
  end

  describe "POST create" do
    it "stores the chosen semantic key on the new field" do
      post admin_settings_user_custom_fields_path,
           params: {
             type: "UserCustomField",
             custom_field: {
               name: "Position",
               field_format: "string",
               custom_field_section_id: section.id,
               semantic_key: "job_title"
             }
           }

      custom_field = UserCustomField.find_by(name: "Position")
      expect(custom_field.semantic_key).to eq("job_title")
    end
  end

  context "when a field already owns the job_title semantic key" do
    shared_let(:job_title_field) do
      create(:user_custom_field, name: "Job title", field_format: "string",
                                 user_custom_field_section: section, semantic_key: "job_title")
    end
    shared_let(:other_field) do
      create(:user_custom_field, name: "Other", field_format: "string",
                                 user_custom_field_section: section)
    end

    describe "GET edit of another field" do
      it "renders the already-taken option as disabled" do
        get edit_admin_settings_user_custom_field_path(other_field)

        expect(response.body).to match(/<option(?=[^>]*\bdisabled\b)(?=[^>]*value="job_title")[^>]*>/)
      end
    end

    describe "GET edit of the owning field" do
      it "keeps its own option selectable" do
        get edit_admin_settings_user_custom_field_path(job_title_field)

        expect(response.body).not_to match(/<option(?=[^>]*\bdisabled\b)(?=[^>]*value="job_title")[^>]*>/)
      end
    end

    describe "PATCH update assigning the taken key to another field" do
      it "does not persist the duplicate semantic key" do
        patch admin_settings_user_custom_field_path(other_field),
              params: {
                type: "UserCustomField",
                custom_field: { semantic_key: "job_title" }
              }

        expect(other_field.reload.semantic_key).to be_nil
      end
    end

    describe "PATCH update clearing the semantic key (blank option)" do
      it "removes the semantic key from the owning field" do
        patch admin_settings_user_custom_field_path(job_title_field),
              params: {
                type: "UserCustomField",
                custom_field: { semantic_key: "" }
              }

        expect(job_title_field.reload.semantic_key).to be_nil
      end
    end
  end
end
