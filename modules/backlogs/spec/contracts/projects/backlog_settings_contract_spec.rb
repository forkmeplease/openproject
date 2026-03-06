# frozen_string_literal: true

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe Projects::BacklogSettingsContract, type: :model do
  include_context "ModelContract shared context"

  shared_let(:current_user) { build_stubbed(:user) }
  let(:project) { create(:project) }
  let(:can_share_sprint) { true }
  subject(:contract) { described_class.new(project, current_user) }

  before do
    allow(current_user)
      .to receive(:allowed_in_project?)
      .with(:share_sprint, project)
      .and_return(can_share_sprint)
  end

  it_behaves_like "contract is valid"

  describe "validations" do
    it { is_expected.to validate_presence_of(:sprint_sharing) }

    it do
      expect(subject)
        .to validate_inclusion_of(:sprint_sharing).in_array(Project::SPRINT_SHARING_OPTIONS)
    end

    it_behaves_like "contract is valid"

    describe "permissions" do
      context "when user can share sprint" do
        let(:can_share_sprint) { true }

        it_behaves_like "contract is valid"
      end

      context "when user cannot share sprint" do
        let(:can_share_sprint) { false }

        it_behaves_like "contract user is unauthorized"
      end
    end

    describe "#validate_global_sprint_sharer_uniqueness" do
      before do
        project.sprint_sharing = "share_all_projects"
      end

      context "when no other project shares with all projects" do
        it_behaves_like "contract is valid"
      end

      context "when the project already has share_all_projects" do
        let(:project) { create(:project, sprint_sharing: "share_all_projects") }

        it_behaves_like "contract is valid"
      end

      context "when another project already shares with all projects" do
        let!(:other_project) { create(:project, sprint_sharing: "share_all_projects") }

        it_behaves_like "contract is invalid", sprint_sharing: :share_all_projects_already_taken

        context "when sprint_sharing is set to Share subprojects" do
          before { project.sprint_sharing = "share_subprojects" }

          it_behaves_like "contract is valid"
        end

        context "when the other project is archived" do
          let!(:other_project) { create(:project, :archived, sprint_sharing: "share_all_projects") }

          it_behaves_like "contract is valid"
        end
      end
    end
  end

  describe "#writable_attributes" do
    it "only allows sprint_sharing to be written" do
      expect(contract.writable_attributes).to include("sprint_sharing")
      expect(contract.writable_attributes).not_to include("settings")
      expect(contract.writable_attributes).not_to include("deactivate_work_package_attachments")
    end
  end
end
