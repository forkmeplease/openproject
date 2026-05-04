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

module QuickFilter
  class BooleanComponent < ApplicationComponent
    include ApplicationHelper

    def initialize(name:, query:, filter_key:, true_label:, false_label:, path_args:,
                   show_all: true, true_value: "t", false_value: "f", true_first: false, orders: nil)
      super

      @name = name
      @query = query
      @filter_key = filter_key
      @true_label = true_label
      @false_label = false_label
      @path_args = path_args
      @show_all = show_all
      @true_value = true_value
      @false_value = false_value
      @true_first = true_first
      @orders = orders
    end

    private

    def current_value
      @query.find_active_filter(@filter_key)&.values&.first
    end

    def items
      items = [
        { href: href_for(@false_value), label: @false_label, selected: current_value == @false_value },
        { href: href_for(@true_value), label: @true_label, selected: current_value == @true_value }
      ]
      @true_first ? items.reverse : items
    end

    def all_href
      href_for(nil)
    end

    def href_for(value)
      params = {}
      filters = filters_params(value)
      params[:filters] = filters.to_json if filters.any?

      sort = sort_params(value)
      params[:sortBy] = sort.to_json if sort.any?

      polymorphic_path(@path_args, params)
    end

    def sort_params(value)
      order_override = @orders && @orders[value]
      if order_override
        order_override.map { |attr, dir| [attr.to_s, dir.to_s] }
      else
        @query.orders.map { |o| [o.class.key.to_s, o.direction.to_s] }
      end
    end

    def filters_params(value)
      filters = @query.filters
        .reject { |f| f.name == @filter_key }
        .map { |f| { f.class.key.to_s => { "operator" => f.operator.to_s, "values" => f.values } } }

      filters << { @filter_key.to_s => { "operator" => "=", "values" => [value] } } if value
      filters
    end
  end
end
