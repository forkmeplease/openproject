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
  module InplaceEdit
    class FieldRegistry
      def initialize
        @registry = {}
        @custom_field_format_mappings = {}
      end

      def register(attribute_name, field_component)
        @registry[attribute_name.to_s] = field_component
      end

      def register_custom_field_format_mappings(mappings)
        @custom_field_format_mappings = mappings
      end

      def register_custom_field(id, field_format)
        component = @custom_field_format_mappings[field_format]
        register("custom_field_#{id}", component) if component
      end

      def fetch(attribute_name)
        @registry.fetch(attribute_name.to_s) { Common::InplaceEditFields::TextInputComponent }
      end

      @default = new

      class << self
        attr_reader :default

        delegate :register, :fetch, :register_custom_field_format_mappings, :register_custom_field, to: :@default
      end
    end
  end
end
