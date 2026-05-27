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

module ResourcePlannerViews
  module ConfigureStep
    # Renders the "Configure view" form (name + filter mode). Used both for
    # the new-view dialog (step 2) and for the future edit dialog. Callers
    # pass the form `url`, HTTP `method`, and the model to bind to. The
    # `form_id` lets the surrounding dialog wire its submit button to this
    # form via `<button form="...">`. `wrapper_key` is overridable so this
    # component can be slotted into different dialog bodies — each dialog
    # has its own replaceable body wrapper.
    class FormComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(view:,
                     url:,
                     method: :post,
                     hidden_fields: {},
                     form_id: ResourcePlannerViews::NewDialogComponent::FORM_ID,
                     wrapper_key: "resource_planner_view_step_body",
                     filter_query: nil)
        super
        @view = view
        @url = url
        @method = method
        @hidden_fields = hidden_fields
        @form_id = form_id
        @wrapper_key = wrapper_key
        @filter_query = filter_query
      end

      attr_reader :wrapper_key

      private

      def initial_filter_mode_automatic?
        @view.errors.empty?
      end

      def has_filter_query?
        # TODO: Properly handle the WorkPackage Query in the filter component as well
        @filter_query.present? && !@filter_query.is_a?(::Query)
      end
    end
  end
end
