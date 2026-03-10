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

RSpec.describe Agile::Sprint do
  let(:project) { create(:project) }

  subject(:sprint) do
    described_class.new(name: "Sprint 1",
                        project:,
                        start_date: Time.zone.today,
                        finish_date: Time.zone.today + 14.days)
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:finish_date) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class.statuses.keys) }

    it "validates finish_date is after or equal to start_date" do
      sprint.finish_date = sprint.start_date - 1.day
      expect(sprint).not_to be_valid
      expect(sprint.errors[:finish_date]).to include(/must be greater than or equal to/)
    end

    it "does not validate finish_date comparison when start_date is nil" do
      sprint.start_date = nil
      sprint.finish_date = Time.zone.today
      expect(sprint).not_to be_valid
      expect(sprint.errors[:start_date]).to be_present
      expect(sprint.errors[:finish_date]).not_to include(/must be greater than or equal to/)
    end

    it "still validates finish_date presence even when start_date is nil" do
      sprint.start_date = nil
      sprint.finish_date = nil
      expect(sprint).not_to be_valid
      expect(sprint.errors[:finish_date]).to be_present
    end

    context "with active sprint validation" do
      it "allows one active sprint per project" do
        sprint.status = "active"
        expect(sprint).to be_valid
      end

      it "prevents multiple active sprints in the same project" do
        create(:agile_sprint, project:, status: "active")
        sprint.status = "active"
        expect(sprint).not_to be_valid
        expect(sprint.errors[:status]).to include("only one active sprint is allowed per project.")
      end

      it "allows multiple active sprints in different projects" do
        other_project = create(:project)
        create(:agile_sprint, project: other_project, status: "active")
        sprint.status = "active"
        expect(sprint).to be_valid
      end

      it "allows updating an existing active sprint" do
        sprint.status = "active"
        sprint.save!
        sprint.name = "Updated Sprint"
        expect(sprint).to be_valid
      end

      it "allows multiple non-active sprints in the same project" do
        create(:agile_sprint, project:, status: "completed")
        create(:agile_sprint, project:, status: "in_planning")
        sprint.status = "in_planning"
        expect(sprint).to be_valid
      end
    end
  end

  describe "enums" do
    it "has status enum with correct values" do
      expect(described_class.statuses.keys).to contain_exactly("in_planning", "active", "completed")
    end

    it "status defaults to in_planning" do
      expect(sprint).to be_in_planning
    end
  end

  describe ".for_project" do
    let(:global_sharer) { create(:project, sprint_sharing: "share_all_projects") }
    let(:other_project) { create(:project) }
    let!(:sprint_in_project) { create(:agile_sprint, project:) }
    let!(:global_sprint) { create(:agile_sprint, project: global_sharer) }
    let!(:sprint_in_other_project) { create(:agile_sprint, project: other_project) }

    context "when project does not receive sprints" do
      context "and there are no work package assignments" do
        it "returns only the project's own sprint" do
          expect(described_class.for_project(project)).to contain_exactly(sprint_in_project)
        end
      end

      context "and the project has a work package assigned to a sprint from another project" do
        let!(:cross_project_sprint) { create(:agile_sprint, project: other_project) }
        let!(:work_package) { create(:work_package, project:, sprint: cross_project_sprint) }

        it "returns both the own sprint and the sprint assigned via work package" do
          expect(described_class.for_project(project)).to contain_exactly(sprint_in_project, cross_project_sprint)
        end

        context "when the cross-project sprint is completed" do
          let!(:completed_sprint) { create(:agile_sprint, project: other_project, status: "completed") }
          let!(:work_package) { create(:work_package, project:, sprint: completed_sprint) }

          it "returns the completed sprint among the sprints" do
            expect(described_class.for_project(project)).to include(completed_sprint)
          end
        end
      end
    end

    context "when project receives shared sprints" do
      let(:project) { create(:project, sprint_sharing: "receive_shared") }

      context "and there is only a global sharer" do
        it "returns only the sprints shared from the global sharer project" do
          expect(described_class.for_project(project)).to contain_exactly(global_sprint)
        end

        context "and a work package is assigned to the project's own sprint" do
          let!(:work_package) { create(:work_package, project:, sprint: sprint_in_project) }

          it "returns both the global shared sprint and the project's own sprint" do
            expect(described_class.for_project(project)).to contain_exactly(global_sprint, sprint_in_project)
          end
        end

        context "and a work package is assigned to the shared sprint from the global sharer" do
          let!(:work_package) { create(:work_package, project:, sprint: global_sprint) }

          it "returns the shared sprint only once" do
            expect(described_class.for_project(project)).to contain_exactly(global_sprint)
          end
        end

        context "and a work package is assigned to a sprint from an unrelated project" do
          let!(:work_package) { create(:work_package, project:, sprint: sprint_in_other_project) }

          it "returns the global shared sprint and the unrelated project's sprint" do
            expect(described_class.for_project(project)).to contain_exactly(global_sprint, sprint_in_other_project)
          end
        end
      end

      context "and there is a subproject-sharing ancestor" do
        let(:subproject_sharer) { create(:project, sprint_sharing: "share_subprojects") }
        let(:project) { create(:project, parent: subproject_sharer, sprint_sharing: "receive_shared") }
        let!(:subproject_sprint) { create(:agile_sprint, project: subproject_sharer) }

        it "returns only the sprints shared from the closest subproject-sharing ancestor" do
          expect(described_class.for_project(project)).to contain_exactly(subproject_sprint)
        end

        context "and a work package is assigned to the project's own sprint" do
          let!(:work_package) { create(:work_package, project:, sprint: sprint_in_project) }

          it "returns both the ancestor's shared sprint and the project's own sprint" do
            expect(described_class.for_project(project)).to contain_exactly(subproject_sprint, sprint_in_project)
          end
        end

        context "and a work package is assigned to the ancestor's shared sprint" do
          let!(:work_package) { create(:work_package, project:, sprint: subproject_sprint) }

          it "returns the ancestor's shared sprint only once" do
            expect(described_class.for_project(project)).to contain_exactly(subproject_sprint)
          end
        end

        context "and a work package is assigned to a sprint from the global sharer" do
          let!(:work_package) { create(:work_package, project:, sprint: global_sprint) }

          it "returns both the ancestor's shared sprint and the global sharer's sprint" do
            expect(described_class.for_project(project)).to contain_exactly(subproject_sprint, global_sprint)
          end
        end
      end
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:work_packages).dependent(:nullify) }
    it { is_expected.to belong_to(:project) }
  end

  describe "work_package association" do
    let(:sprint) { create(:agile_sprint, project:) }
    let(:work_package) { create(:work_package, project:, sprint:) }

    it "can have work packages associated" do
      expect(sprint.work_packages).to include(work_package)
    end

    it "nullifies work_package sprint_id when destroyed" do
      work_package_id = work_package.id
      sprint.destroy!
      expect(WorkPackage.find(work_package_id).sprint_id).to be_nil
    end
  end
end
