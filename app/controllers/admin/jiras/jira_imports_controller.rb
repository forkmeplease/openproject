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

module Admin
  module Jiras
    class JiraImportsController < ApplicationController
      include OpTurbo::ComponentStream
      layout "admin"

      menu_item :jira_import

      before_action :require_admin
      before_action :find_jira_and_jira_import, only: %i[edit update fetch import remove]

      def new
        jira = Jira.find(params[:jira_id])
        jira_import = JiraImport.create!(author_id: current_user.id, jira_id: jira.id, status: "initial")
        redirect_to(edit_admin_jira_jira_import_path(jira_id: jira.id, id: jira_import.id))
      end

      def edit
      end

      def update
        projects = params[:jira_import][:projects]
        @jira_import.update!(projects:, status: "configured")
        redirect_to(admin_jira_path(@jira))
      end

      def fetch
        redirect_to(admin_jira_path(@jira))
      end

      def import
        redirect_to(admin_jira_path(@jira))
      end

      def remove
        redirect_to(admin_jira_path(@jira))
      end

      private

      def find_jira_and_jira_import
        @jira = Jira.find(params[:jira_id])
        @jira_import = JiraImport.find(params[:id])
      end

      def jira_params
        params.expect(jira: %i[url personal_access_token])
      end

      def stream_form_component(&)
        update_via_turbo_stream(component: Admin::Jiras::FormComponent.new(@jira))
        respond_with_turbo_streams(&)
      end
    end
  end
end
