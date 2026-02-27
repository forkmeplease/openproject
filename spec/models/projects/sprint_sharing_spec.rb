# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::SprintSharing do
  let(:project) { create(:project) }

  describe "SPRINT_SHARING_OPTIONS" do
    it "defines all supported sprint sharing options" do
      expect(described_class::SPRINT_SHARING_OPTIONS).to match_array(
        %w[share_all_projects share_subprojects no_sharing receive_shared]
      )
    end

    it "is exposed on Project" do
      expect(Project::SPRINT_SHARING_OPTIONS).to eq(described_class::SPRINT_SHARING_OPTIONS)
    end
  end

  describe "#sprint_sharing" do
    it "defaults to no_sharing" do
      expect(project.sprint_sharing).to eq("no_sharing")
    end

    it "persists configured values" do
      project.update!(sprint_sharing: "share_subprojects")

      expect(project.reload.sprint_sharing).to eq("share_subprojects")
    end
  end

  describe ".sprint_sharer" do
    context "when no project shares with all projects" do
      it "returns nil" do
        expect(Project.sprint_sharer).to be_nil
      end
    end

    context "when a project shares with all projects" do
      before { project.update!(sprint_sharing: "share_all_projects") }

      it "returns that project" do
        expect(Project.sprint_sharer).to eq(project)
      end
    end
  end

  describe "#validate_sprint_sharer_uniqueness" do
    context "when no other project shares with all projects" do
      it "allows setting share_all_projects" do
        project.sprint_sharing = "share_all_projects"

        expect(project).to be_valid
      end
    end

    context "when the project already has share_all_projects" do
      before { project.update!(sprint_sharing: "share_all_projects") }

      it "remains valid on re-save" do
        expect(project.reload).to be_valid
      end
    end

    context "when another project already shares with all projects" do
      let!(:other_project) { create(:project, sprint_sharing: "share_all_projects") }

      it "is invalid" do
        project.sprint_sharing = "share_all_projects"

        expect(project).not_to be_valid
        expect(project.errors[:sprint_sharing]).to include(
          I18n.t("activerecord.errors.models.project.attributes.sprint_sharing.share_all_projects_already_taken",
                 name: other_project.name)
        )
      end

      it "allows other sharing options" do
        project.sprint_sharing = "share_subprojects"

        expect(project).to be_valid
      end
    end
  end
end
