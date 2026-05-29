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
  module Filter
    # @logical_path OpenProject/Filter
    class FilterFormPreview < Lookbook::Preview
      # @display min_height 600px
      def default
        render_with_template(locals: { query: UserQuery.new })
      end

      # @display min_height 600px
      # @label With an active filter
      def with_active_filter
        query = UserQuery.new
        query.where(:login, "~", ["admin"])
        render_with_template(locals: { query: })
      end

      # @display min_height 600px
      # @label Hidden input mode
      # @param output_format [Symbol] select [json, params]
      # This also renders a field that shows the value of the hidden input to show the different serialization formats.
      def with_hidden_input(output_format: :json)
        render_with_template(locals: { query: UserQuery.new, output_format: output_format.to_sym })
      end

      # @display min_height 600px
      # @label Combined with other inputs
      def combined_with_other_inputs
        render_with_template(locals: { query: UserQuery.new })
      end
    end
  end
end
