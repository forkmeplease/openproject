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

RSpec.describe OpenProject::InplaceEdit::FieldRegistry do
  subject(:registry) { described_class.new }

  let(:rich_text_component) { Class.new }

  describe "#register" do
    it "registers a field component for an attribute" do
      registry.register(:description, rich_text_component)

      expect(registry.fetch(:description)).to eq(rich_text_component)
    end
  end

  describe "#fetch" do
    it "returns the registered component for the attribute" do
      registry.register(:description, rich_text_component)

      expect(registry.fetch(:description)).to eq(rich_text_component)
    end

    it "falls back to TextInputComponent if attribute is not registered" do
      expect(registry.fetch(:unknown))
        .to eq(OpenProject::Common::InplaceEditFields::TextInputComponent)
    end

    it "normalizes attribute names to strings" do
      registry.register("description", rich_text_component)

      expect(registry.fetch(:description)).to eq(rich_text_component)
    end
  end

  describe "#register_custom_field_format_mappings" do
    it "stores format-to-component mappings used by register_custom_field" do
      text_component = Class.new
      registry.register_custom_field_format_mappings("text" => text_component)

      registry.register_custom_field(42, "text")

      expect(registry.fetch("custom_field_42")).to eq(text_component)
    end
  end

  describe "#register_custom_field" do
    let(:text_component) { Class.new }

    before do
      registry.register_custom_field_format_mappings("text" => text_component)
    end

    it "registers the correct component for the given field format" do
      registry.register_custom_field(1, "text")

      expect(registry.fetch("custom_field_1")).to eq(text_component)
    end

    it "does nothing when the format has no mapping" do
      registry.register_custom_field(2, "unknown_format")

      expect(registry.fetch("custom_field_2"))
        .to eq(OpenProject::Common::InplaceEditFields::TextInputComponent)
    end
  end
end
