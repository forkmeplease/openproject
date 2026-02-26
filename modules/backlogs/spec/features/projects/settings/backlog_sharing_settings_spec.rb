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

RSpec.describe "Backlogs project settings sprint sharing", :js, with_flag: { scrum_projects: true } do
  let(:project) { create(:project) }
  let(:permissions) { %i[create_sprints share_sprint] }

  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  before do
    login_as current_user
  end

  context "with share_sprint permission" do
    it "displays and stores sprint sharing settings" do
      visit project_settings_backlog_sharing_path(project)

      expect(page).to have_link(
        "Sharing",
        href: project_settings_backlog_sharing_path(project)
      )

      # have all the options in the select with No sharing as default
      expect(page).to have_select(
        Project.human_attribute_name(:sprint_sharing),
        with_options: [
          I18n.t("projects.settings.backlog_sharing.options.share_sprints"),
          I18n.t("projects.settings.backlog_sharing.options.no_sharing"),
          I18n.t("projects.settings.backlog_sharing.options.receive_shared")
        ],
        selected: I18n.t("projects.settings.backlog_sharing.options.no_sharing")
      )

      expect(page).to have_no_checked_field(
        I18n.t("projects.settings.backlog_sharing.options.share_subprojects"),
        visible: :visible
      )

      # persists receive_shared
      select(
        I18n.t("projects.settings.backlog_sharing.options.receive_shared"),
        from: Project.human_attribute_name(:sprint_sharing)
      )

      click_button I18n.t("button_save")

      expect_and_dismiss_flash(type: :success, message: I18n.t(:notice_successful_update))
      expect(page).to have_select(
        Project.human_attribute_name(:sprint_sharing),
        selected: I18n.t("projects.settings.backlog_sharing.options.receive_shared")
      )
      expect(project.reload.sprint_sharing).to eq("receive_shared")

      # persists share_subprojects
      select(
        I18n.t("projects.settings.backlog_sharing.options.share_sprints"),
        from: Project.human_attribute_name(:sprint_sharing)
      )

      # share_all_projects is automatically checked when share_sprints is selected
      expect(page)
        .to have_checked_field(
          I18n.t("projects.settings.backlog_sharing.options.share_all_projects")
        )

      choose(I18n.t("projects.settings.backlog_sharing.options.share_subprojects"))
      click_button I18n.t("button_save")

      expect_and_dismiss_flash(type: :success, message: I18n.t(:notice_successful_update))
      expect(page).to have_checked_field(I18n.t("projects.settings.backlog_sharing.options.share_subprojects"))
      expect(project.reload.sprint_sharing).to eq("share_subprojects")
    end
  end

  context "without share_sprint permission" do
    let(:permissions) { %i[create_sprints] }

    it "does not show the sharing tab and forbids direct route access" do
      visit project_settings_backlogs_path(project)

      expect(page).to have_heading(I18n.t(:label_backlogs))
      expect(page).to have_no_link(I18n.t("backlogs.sharing"))

      visit project_settings_backlog_sharing_path(project)

      expect(page).to have_text(I18n.t(:notice_not_authorized))
    end
  end

  context "when scrum_projects feature flag is inactive", with_flag: { scrum_projects: false } do
    it "does not show the sharing tab and returns 404 on direct access" do
      visit project_settings_backlogs_path(project)

      expect(page).to have_heading(I18n.t(:label_backlogs))
      expect(page).to have_no_link(I18n.t("backlogs.sharing"))

      visit project_settings_backlog_sharing_path(project)

      expect(page).to have_text(I18n.t(:notice_file_not_found))
    end
  end
end
