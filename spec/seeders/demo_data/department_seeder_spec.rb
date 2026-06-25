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

RSpec.describe DemoData::DepartmentSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { Source::SeedData.new(data_hash) }

  let(:data_hash) do
    YAML.load <<~SEEDING_DATA_YAML
      departments:
      - name: Marketing & Communications
        reference: :marketing
      - name: Public Relations
        reference: :public_relations
        parent: :marketing
    SEEDING_DATA_YAML
  end

  it "creates a root department as an organizational unit with the given name" do
    seeder.seed!

    root = seed_data.find_reference(:marketing)
    expect(root).to have_attributes(lastname: "Marketing & Communications", organizational_unit: true)
    expect(root.parent).to be_nil
  end

  it "creates a child department nested under its parent" do
    seeder.seed!

    root = seed_data.find_reference(:marketing)
    child = seed_data.find_reference(:public_relations)

    expect(child).to have_attributes(lastname: "Public Relations", organizational_unit: true)
    expect(child.parent).to eq(root)
    expect(root.children).to include(child)
  end

  it "is not applicable once an organizational unit already exists" do
    create(:department)

    expect(seeder).not_to be_applicable
  end
end
