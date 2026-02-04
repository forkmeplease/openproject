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
#

require "spec_helper"

RSpec.describe Admin::Import::Jira::ImportRunsController do
  let(:admin) { create(:admin) }
  let(:non_admin) { create(:user) }
  let(:jira) { create(:jira) }
  let(:jira_import) { create(:jira_import, jira:, author: admin, status: JiraImport::INITIAL) }

  before do
    login_as(admin)
  end

  context "when user is not an admin" do
    before { login_as(non_admin) }

    it "returns forbidden for GET #show" do
      get :show, params: { jira_id: jira.id, id: jira_import.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for GET #new" do
      get :new, params: { jira_id: jira.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for POST #continue" do
      post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "init" }, format: :turbo_stream
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for POST #select_projects" do
      post :select_projects, params: { jira_id: jira.id, id: jira_import.id, projects: %w[PROJ1] }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for GET #select_projects_modal" do
      get :select_projects_modal, params: { jira_id: jira.id, id: jira_import.id }, format: :turbo_stream
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for GET #revert_modal" do
      get :revert_modal, params: { jira_id: jira.id, id: jira_import.id }, format: :turbo_stream
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for DELETE #remove" do
      delete :remove, params: { jira_id: jira.id, id: jira_import.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET #show" do
    it "renders the show template" do
      get :show, params: { jira_id: jira.id, id: jira_import.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #new" do
    it "creates a new jira import and redirects to show" do
      expect do
        get :new, params: { jira_id: jira.id }
      end.to change(JiraImport, :count).by(1)

      new_import = JiraImport.last
      expect(new_import.author).to eq(admin)
      expect(new_import.jira).to eq(jira)
      expect(new_import.status).to eq(JiraImport::INITIAL)
      expect(response).to redirect_to(admin_import_jira_run_path(jira_id: jira.id, id: new_import.id))
    end
  end

  describe "GET/POST #continue" do
    context "when step is init" do
      before do
        jira_import.update!(status: JiraImport::CONFIGURING)
      end

      it "resets status to initial" do
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "init" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::INITIAL)
      end
    end

    context "when step is fetch" do
      it "starts instance meta fetching job" do
        allow(JiraInstanceMetaDataJob).to receive(:perform_later)
          .with(jira_import.id)
          .and_return(double(job_id: "job123"))
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "fetch" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::INSTANCE_META_FETCHING)
        expect(jira_import.job_id).to eq("job123")
        expect(JiraInstanceMetaDataJob).to have_received(:perform_later).with(jira_import.id)
      end
    end

    context "when step is stats" do
      before do
        jira_import.update!(status: JiraImport::CONFIGURING)
      end

      it "starts projects meta fetching job" do
        allow(JiraProjectsMetaDataJob).to receive(:perform_later)
          .with(jira_import.id)
          .and_return(double(job_id: "job456"))
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "stats" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::PROJECTS_META_FETCHING)
        expect(jira_import.job_id).to eq("job456")
        expect(JiraProjectsMetaDataJob).to have_received(:perform_later).with(jira_import.id)
      end
    end

    context "when step is import" do
      before do
        jira_import.update!(status: JiraImport::PROJECTS_META_DONE)
      end

      it "starts import job" do
        allow(JiraFetchAndImportProjectsJob).to receive(:perform_later)
          .with(jira_import.id)
          .and_return(double(job_id: "job789"))
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "import" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::IMPORTING)
        expect(jira_import.job_id).to eq("job789")
        expect(JiraFetchAndImportProjectsJob).to have_received(:perform_later).with(jira_import.id)
      end
    end

    context "when step is configure" do
      before do
        jira_import.update!(status: JiraImport::INSTANCE_META_DONE)
      end

      it "updates status to configuring" do
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "configure" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::CONFIGURING)
      end
    end

    context "when step is revert" do
      before do
        jira_import.update!(status: JiraImport::IMPORTED)
      end

      it "starts revert job" do
        allow(JiraRevertJiraImportJob).to receive(:perform_later)
          .with(jira_import.id)
          .and_return(double(job_id: "job999"))
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "revert" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::REVERTING)
        expect(jira_import.job_id).to eq("job999")
        expect(JiraRevertJiraImportJob).to have_received(:perform_later).with(jira_import.id)
      end
    end

    context "when step is finalize" do
      before do
        jira_import.update!(status: JiraImport::IMPORTED)
      end

      it "updates status to completed" do
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "finalize" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::COMPLETED)
      end
    end

    context "when step is blank" do
      it "does not change status" do
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::INITIAL)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when step guard conditions fail" do
      it "does not change status for init when status is after CONFIGURING" do
        jira_import.update!(status: JiraImport::IMPORTED)
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "init" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::IMPORTED)
      end

      it "does not change status for fetch when status is after CONFIGURING" do
        jira_import.update!(status: JiraImport::IMPORTED)
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "fetch" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::IMPORTED)
      end
    end

    context "when step is stats with PROJECTS_META_ERROR status" do
      before do
        jira_import.update!(status: JiraImport::PROJECTS_META_ERROR)
      end

      it "starts projects meta fetching job" do
        allow(JiraProjectsMetaDataJob).to receive(:perform_later)
          .with(jira_import.id)
          .and_return(double(job_id: "job-error-retry"))
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "stats" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::PROJECTS_META_FETCHING)
        expect(JiraProjectsMetaDataJob).to have_received(:perform_later).with(jira_import.id)
      end
    end

    context "when step is import with IMPORT_ERROR status" do
      before do
        jira_import.update!(status: JiraImport::IMPORT_ERROR)
      end

      it "starts import job" do
        allow(JiraFetchAndImportProjectsJob).to receive(:perform_later)
          .with(jira_import.id)
          .and_return(double(job_id: "job-import-retry"))
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "import" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::IMPORTING)
        expect(JiraFetchAndImportProjectsJob).to have_received(:perform_later).with(jira_import.id)
      end
    end

    context "when step is revert with REVERT_ERROR status" do
      before do
        jira_import.update!(status: JiraImport::REVERT_ERROR)
      end

      it "starts revert job" do
        allow(JiraRevertJiraImportJob).to receive(:perform_later)
          .with(jira_import.id)
          .and_return(double(job_id: "job-revert-retry"))
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "revert" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::REVERTING)
        expect(JiraRevertJiraImportJob).to have_received(:perform_later).with(jira_import.id)
      end
    end

    context "when requesting html format" do
      it "redirects to show page" do
        jira_import.update!(status: JiraImport::IMPORTED)
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "finalize" }, format: :html
        expect(response).to redirect_to(admin_import_jira_run_path(jira_id: jira.id, id: jira_import.id))
      end
    end

    context "when step is invalid" do
      it "handles the error with turbo_stream flash message" do
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "invalid_step" }, format: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("Invalid step: invalid_step")
      end
    end

    context "when import is running" do
      before do
        jira_import.update!(status: JiraImport::IMPORTING)
      end

      it "does not change the step" do
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "finalize" }, format: :turbo_stream
        expect(jira_import.reload.status).to eq(JiraImport::IMPORTING)
      end
    end

    context "when an error occurs" do
      before do
        allow(controller).to receive(:change_step).and_raise(StandardError.new("Test error"))
      end

      it "handles the error with turbo_stream" do
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "finalize" }, format: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Test error")
      end

      it "handles the error with html format" do
        post :continue, params: { jira_id: jira.id, id: jira_import.id, step: "finalize" }, format: :html
        expect(flash[:error]).to eq("Test error")
        expect(response).to redirect_to(admin_import_jira_run_path(jira_id: jira.id, id: jira_import.id))
      end
    end
  end

  describe "POST #select_projects" do
    let(:available_projects) do
      {
        "projects" => [
          { "id" => "10001", "name" => "Project One", "key" => "PROJ1" },
          { "id" => "10002", "name" => "Project Two", "key" => "PROJ2" },
          { "id" => "10003", "name" => "Project Three", "key" => "PROJ3" }
        ]
      }
    end

    before do
      jira_import.update!(available: available_projects)
    end

    it "updates the selected projects" do
      post :select_projects, params: { jira_id: jira.id, id: jira_import.id, projects: %w[10001 10002] }
      expect(jira_import.reload.projects).to eq([
        { "id" => "10001", "name" => "Project One", "key" => "PROJ1" },
        { "id" => "10002", "name" => "Project Two", "key" => "PROJ2" }
      ])
      expect(response).to redirect_to(admin_import_jira_run_path(jira_id: jira.id, id: jira_import.id))
    end

    it "filters out blank values" do
      post :select_projects, params: { jira_id: jira.id, id: jira_import.id, projects: ["10001", "", "10002", nil] }
      expect(jira_import.reload.projects).to eq([
        { "id" => "10001", "name" => "Project One", "key" => "PROJ1" },
        { "id" => "10002", "name" => "Project Two", "key" => "PROJ2" }
      ])
    end

    it "handles empty projects array" do
      post :select_projects, params: { jira_id: jira.id, id: jira_import.id, projects: [] }
      expect(jira_import.reload.projects).to eq([])
    end

    it "ignores project IDs not in available projects" do
      post :select_projects, params: { jira_id: jira.id, id: jira_import.id, projects: %w[10001 99999] }
      expect(jira_import.reload.projects).to eq([
        { "id" => "10001", "name" => "Project One", "key" => "PROJ1" }
      ])
    end

    context "when available projects is empty" do
      before do
        jira_import.update!(available: {})
      end

      it "sets projects to empty array" do
        post :select_projects, params: { jira_id: jira.id, id: jira_import.id, projects: %w[10001 10002] }
        expect(jira_import.reload.projects).to eq([])
      end
    end
  end

  describe "GET #select_projects_modal" do
    it "responds with a dialog component" do
      get :select_projects_modal, params: { jira_id: jira.id, id: jira_import.id }, format: :turbo_stream
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #revert_modal" do
    it "responds with a dialog component" do
      get :revert_modal, params: { jira_id: jira.id, id: jira_import.id }, format: :turbo_stream
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE #remove" do
    it "destroys the jira import and redirects" do
      import_to_delete = jira_import # Force lazy-loading before the expect block
      expect do
        delete :remove, params: { jira_id: jira.id, id: import_to_delete.id }
      end.to change(JiraImport, :count).by(-1)
      expect(response).to redirect_to(admin_import_jira_path(jira))
    end

    context "when import is running" do
      before do
        jira_import.update!(status: JiraImport::IMPORTING)
      end

      it "raises an error" do
        expect do
          delete :remove, params: { jira_id: jira.id, id: jira_import.id }
        end.to raise_error(StandardError)
      end
    end
  end
end
