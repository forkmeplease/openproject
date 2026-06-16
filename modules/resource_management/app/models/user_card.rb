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

class UserCard < PersistedView
  include ResourceManagement::Categorized

  # Manual views draw their cards from the query's `ordered_entities` instead of
  # its filters.
  store_attribute :options, :manual, :boolean, default: false

  validate :query_must_be_user_query

  def results
    query = effective_query
    return if query.nil?

    if manually_picked?
      # A manual view shows exactly its `ordered_entities`. When none have
      # been added yet, show an empty set instead.
      return User.none if query.ordered_entities.empty?

      query.results
    else
      query.results.in_project(project)
    end
  end

  def manually_picked?
    !!manual
  end

  def build_default_query
    UserQuery.new(project:, principal:)
  end

  def apply_query_configuration(filters_json:, filter_mode:)
    query = effective_query
    return if query.nil?

    query.filters.clear

    if manual_mode?(filter_mode)
      set_manual(true)
    else
      set_manual(false)

      query.ordered_entities.destroy_all
      configure_automatic(query, filters_json)
    end
  end

  private

  def manual_mode?(filter_mode)
    filter_mode.to_s == "manual"
  end

  def set_manual(value)
    change_by_system { self.manual = value }
  end

  def configure_automatic(query, filters_json)
    parse_filters(filters_json).each do |filter|
      query.where(filter[:attribute], filter[:operator], filter[:values])
    end
  end

  def parse_filters(filters_json)
    return [] if filters_json.blank?

    ::Queries::ParamsParser::APIV3FiltersParser.parse(filters_json)
  rescue JSON::ParserError
    []
  end

  def query_must_be_user_query
    resolved = effective_query
    return if resolved.nil? || resolved.is_a?(UserQuery)

    errors.add(:query, :invalid)
  end
end
