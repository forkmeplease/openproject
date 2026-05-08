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

# Integration coverage for UserQuery with real users, real custom fields and
# real persistence. Unit-level expectations live in user_query_spec.rb;
# this spec exercises the full filter→SQL→ActiveRecord round trip.
RSpec.describe UserQuery, "integration" do
  shared_let(:job_title_cf) do
    create(:user_custom_field, :list,
           name: "Job title",
           possible_values: ["Developer", "Designer", "Project Manager", "Product Manager"])
  end
  shared_let(:nickname_cf) do
    create(:user_custom_field, :string, name: "Nickname")
  end

  shared_let(:developer_option) { job_title_cf.custom_options.find_by(value: "Developer") }
  shared_let(:designer_option) { job_title_cf.custom_options.find_by(value: "Designer") }
  shared_let(:pm_option) { job_title_cf.custom_options.find_by(value: "Project Manager") }

  shared_let(:alice) { create(:user, firstname: "Alice", lastname: "Anders") }
  shared_let(:bob) { create(:user, firstname: "Bob", lastname: "Bauer") }
  shared_let(:carol) { create(:user, firstname: "Carol", lastname: "Cohen") }
  shared_let(:dave) { create(:user, firstname: "Dave", lastname: "Doe") }
  shared_let(:locked_eve) { create(:user, firstname: "Eve", lastname: "Eriksson", status: :locked) }

  before_all do
    [[alice, developer_option, "ace"],
     [bob, developer_option, "bobster"],
     [carol, designer_option, "carol-bear"],
     [dave, pm_option, nil],
     [locked_eve, developer_option, "evil-eve"]].each do |user, option, nickname|
      values = { job_title_cf.id => option.id }
      values[nickname_cf.id] = nickname if nickname
      user.custom_field_values = values
      user.save!(validate: false)
    end
  end

  before { login_as(alice) }

  let(:query) { described_class.new(name: "Users") }

  describe "filtering by a list custom field" do
    it "returns only users whose CF value matches the selected option" do
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])

      expect(query.results).to contain_exactly(alice, bob, locked_eve)
    end

    it "supports the negated operator (excludes the matching option, includes users with no value)" do
      query.where(job_title_cf.column_name, "!", [developer_option.id.to_s])

      expect(query.results).to contain_exactly(carol, dave)
    end

    it "supports 'all and non-blank' to find users with any value set" do
      query.where(job_title_cf.column_name, "*", [])

      expect(query.results).to contain_exactly(alice, bob, carol, dave, locked_eve)
    end

    it "supports 'none or blank' to find users with no value set" do
      # All seeded users have a job title, so a fresh user with no CF data should be the only match.
      blank_user = create(:user, firstname: "Frank", lastname: "Frost")

      query.where(job_title_cf.column_name, "!*", [])

      expect(query.results).to contain_exactly(blank_user)
    end
  end

  describe "filtering by a string custom field" do
    it "supports the contains (~) operator" do
      query.where(nickname_cf.column_name, "~", ["bear"])

      expect(query.results).to contain_exactly(carol)
    end
  end

  describe "combining a CF filter with built-in filters" do
    it "applies status and CF filters with AND semantics" do
      query.where("status", "=", ["active"])
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])

      expect(query.results).to contain_exactly(alice, bob)
    end

    it "applies a name filter together with a CF filter" do
      query.where("name", "~", ["alice"])
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])

      expect(query.results).to contain_exactly(alice)
    end
  end

  describe "ordering does not interfere with CF filtering" do
    it "returns matching users in the requested order" do
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])
      query.order(id: :asc)

      expect(query.results.to_a).to eq([alice, bob, locked_eve].sort_by(&:id))
    end
  end

  describe "PersistedQuery round-trip" do
    it "persists and re-runs a UserQuery with a CF filter" do
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])
      query.where("status", "=", ["active"])
      query.order(name: :asc)
      query.save!

      reloaded = described_class.find(query.id)

      expect(reloaded.filters.size).to eq(2)
      cf_filter = reloaded.filters.detect { |f| f.is_a?(Queries::Filters::Shared::CustomFields::ListOptional) }
      expect(cf_filter).not_to be_nil
      expect(cf_filter.custom_field).to eq(job_title_cf)
      expect(cf_filter.values).to eq([developer_option.id.to_s])
      expect(reloaded.orders.first).to be_a(Queries::Users::Orders::NameOrder)

      expect(reloaded.results).to contain_exactly(alice, bob)
    end

    it "stores the CF filter as the cf_<id> attribute hash in the database" do
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])
      query.save!

      raw_filters = PersistedQuery.connection.select_value(
        "SELECT filters FROM persisted_queries WHERE id = #{query.id}"
      )
      raw_filters = JSON.parse(raw_filters) if raw_filters.is_a?(String)

      expect(raw_filters).to eq([{
                                  "attribute" => job_title_cf.column_name,
                                  "operator" => "=",
                                  "values" => [developer_option.id.to_s]
                                }])
    end

    it "falls back to a NotExistingFilter when the referenced CF has been deleted" do
      query.where(job_title_cf.column_name, "=", [developer_option.id.to_s])
      query.save!

      job_title_cf.destroy!
      # The shared CF filter caches `UserCustomField.all` in RequestStore for the
      # life of the request; clear it so the deserializer sees the deletion.
      RequestStore.clear!

      reloaded = described_class.find(query.id)
      expect(reloaded.filters.first).to be_a(Queries::Filters::NotExistingFilter)
      expect(reloaded).not_to be_valid
    end
  end
end
