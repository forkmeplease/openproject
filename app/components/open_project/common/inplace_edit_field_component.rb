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

module OpenProject
  module Common
    class InplaceEditFieldComponent < ViewComponent::Base
      include OpTurbo::Streamable

      attr_reader :model, :attribute

      def initialize(model:, attribute:, **system_arguments)
        super()
        @model = model
        @attribute = attribute
        @system_arguments = system_arguments
      end

      def field_component(form)
        klass = OpenProject::InplaceEdit::FieldRegistry.fetch(attribute)
        klass.new(form:, attribute:, model:, **merged_system_arguments)
      end

      private

      def merged_system_arguments
        @system_arguments.merge(
          disabled: !writable?
        )
      end

      def writable?
        contract_class = OpenProject::InplaceEdit::UpdateRegistry.fetch_contract(model)

        return false unless contract_class

        contract_class.new(model, User.current).writable?(attribute)
      end
    end
  end
end
