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

RSpec.describe WorkPackages::IdentifierAutofix::ProjectIdentifierSuggestionGenerator do
  describe ".call" do
    context "when given an empty array" do
      it "returns an empty array" do
        expect(described_class.call([])).to be_empty
      end
    end

    context "when a project has a too-long identifier" do
      shared_let(:project) { create(:project, identifier: "verylongidentifier", name: "Very Long Identifier") }

      it "returns one suggestion entry for the project" do
        result = described_class.call([project])
        expect(result.size).to eq(1)
        expect(result.first[:project]).to eq(project)
        expect(result.first[:current_identifier]).to eq("verylongidentifier")
        expect(result.first[:error_reason]).to eq(:too_long)
        expect(result.first[:suggested_identifier]).to be_present
        expect(result.first[:suggested_identifier].length).to be <= described_class::IDENTIFIER_MAX_LENGTH
      end
    end

    context "when a project has a special-character identifier" do
      # "fs" is 2 chars (≤ IDENTIFIER_MAX_LENGTH) but contains no special chars;
      # use "f-s" (3 chars ≤ IDENTIFIER_MAX_LENGTH) to trigger :special_characters.
      shared_let(:project) { create(:project, identifier: "f-s", name: "Fly Sky") }

      it "returns a suggestion entry with error_reason :special_characters" do
        result = described_class.call([project])
        expect(result.size).to eq(1)
        expect(result.first[:error_reason]).to eq(:special_characters)
      end
    end

    context "when multiple projects generate conflicting identifiers" do
      shared_let(:project_sc1) { create(:project, identifier: "sc-app",         name: "Stream Communicator") }
      shared_let(:project_sc2) { create(:project, identifier: "stream-channel", name: "Stream Channel") }

      it "generates unique identifiers for each project" do
        identifiers = described_class.call([project_sc1, project_sc2]).pluck(:suggested_identifier)
        expect(identifiers.uniq.size).to eq(identifiers.size)
      end

      it "appends a numeric suffix to resolve conflicts" do
        identifiers = described_class.call([project_sc1, project_sc2]).pluck(:suggested_identifier)
        expect(identifiers).to include("SC")
        expect(identifiers.any? { it.match?(/\ASC\d+\z/) }).to be true
      end
    end
  end

  describe "identifier generation from project name" do
    {
      # Single-word names: first SINGLE_WORD_LENGTH (3) transliterated chars
      "Banana" => "BAN",
      "Kiwi" => "KIW",
      "Strawberry" => "STR",
      "Cécile" => "CEC", # single word with accented letter
      # Multi-word names: initials, truncated to IDENTIFIER_MAX_LENGTH (5)
      "Flight Planning Algorithm" => "FPA",
      "Fly & Sky" => "FS",
      "Social media marketing" => "SMM",
      "Arcanos (mobile-web-app)" => "AMWA",
      "Flight Planning Training" => "FPT",
      "A B C D E F G H I J K" => "ABCDE", # truncated to IDENTIFIER_MAX_LENGTH (5)
      "Cécile Martin" => "CM", # Unicode: "Cécile" is one word, not ["C","cile"]
      "étude de cas" => "EDC", # Unicode: é→E via transliteration
      # Non-Latin scripts have no transliteration entries (I18n.transliterate → "?").
      # All initials are dropped and the name falls back to FALLBACK_IDENTIFIER.
      "日本語プロジェクト" => "PROJ", # Japanese: every initial → "?" → fallback
      "Plan 日本" => "P" # Mixed: Latin "P" survives; "日" is dropped
    }.each do |project_name, expected_identifier|
      it "generates '#{expected_identifier}' from '#{project_name}'" do
        project = create(:project, identifier: "bad-id", name: project_name)
        expect(described_class.call([project]).first[:suggested_identifier]).to eq(expected_identifier)
      end
    end
  end

  describe "unique_identifier conflict resolution" do
    it "uses the base identifier when not yet taken" do
      project = create(:project, identifier: "sc-app", name: "Stream Communicator")
      expect(described_class.call([project]).first[:suggested_identifier]).to eq("SC")
    end

    it "increments the suffix until unique" do
      p1 = create(:project, identifier: "sc-a", name: "Stream Communicator")
      p2 = create(:project, identifier: "sc-b", name: "Stream Channel")
      p3 = create(:project, identifier: "sc-c", name: "Something Cool")
      expect(described_class.call([p1, p2, p3]).pluck(:suggested_identifier)).to contain_exactly("SC", "SC2", "SC3")
    end

    it "trims the base to fit within IDENTIFIER_MAX_LENGTH when adding a suffix" do
      p1 = create(:project, identifier: "a-b-c-d-e-f-g-h-i-j", name: "A B C D E F G H I J")
      p2 = create(:project, identifier: "a-b-c-d-e-f-g-h-i-j-x", name: "A B C D E F G H I J")
      identifiers = described_class.call([p1, p2]).pluck(:suggested_identifier)
      expect(identifiers.all? { it.length <= described_class::IDENTIFIER_MAX_LENGTH }).to be true
      expect(identifiers.uniq.size).to eq(2)
    end

    it "does not suggest an identifier that is already in use (pre-seeded collision)" do
      # "SC" is pre-seeded as an in-use identifier; the generator must skip it and use "SC2".
      project = create(:project, identifier: "sc-app", name: "Stream Communicator")
      result = described_class.call([project], in_use_identifiers: Set["SC"])
      expect(result.first[:suggested_identifier]).not_to eq("SC")
      expect(result.first[:suggested_identifier]).to match(/\ASC\d+\z/) # e.g. "SC2"
    end
  end

  describe "error reason assignment" do
    it "assigns :too_long when identifier length exceeds IDENTIFIER_MAX_LENGTH" do
      project = create(:project, identifier: "verylongidentifier", name: "Test")
      expect(described_class.call([project]).first[:error_reason]).to eq(:too_long)
    end

    it "assigns :special_characters when identifier has non-alphanumeric chars but is short" do
      project = create(:project, identifier: "ab-c", name: "Test")
      expect(described_class.call([project]).first[:error_reason]).to eq(:special_characters)
    end

    it "assigns :too_long (priority) when identifier is both too long and has special chars" do
      project = create(:project, identifier: "my-very-long-identifier", name: "Test")
      expect(described_class.call([project]).first[:error_reason]).to eq(:too_long)
    end

    it "assigns :in_use when identifier is another project's active identifier" do
      # "abc" is valid (lowercase alphanumeric, ≤ 5 chars, no special chars)
      project = create(:project, identifier: "abc", name: "Alpha Beta Corp")
      result = described_class.call([project], in_use_identifiers: Set["abc"])
      expect(result.first[:error_reason]).to eq(:in_use)
    end

    it "assigns :reserved when identifier appears in historical identifiers" do
      project = create(:project, identifier: "abc", name: "Alpha Beta Corp")
      result = described_class.call([project], reserved_identifiers: Set["abc"])
      expect(result.first[:error_reason]).to eq(:reserved)
    end

    it "prefers :in_use over :reserved when identifier is in both sets" do
      project = create(:project, identifier: "abc", name: "Alpha Beta Corp")
      result = described_class.call([project], in_use_identifiers: Set["abc"], reserved_identifiers: Set["abc"])
      expect(result.first[:error_reason]).to eq(:in_use)
    end

    it "prefers :too_long over :in_use when identifier is also too long" do
      # "toolong" is 7 chars (> IDENTIFIER_MAX_LENGTH=5) and alphanumeric — too_long wins
      project = create(:project, identifier: "toolong", name: "Too Long Identifier")
      result = described_class.call([project], in_use_identifiers: Set["toolong"])
      expect(result.first[:error_reason]).to eq(:too_long)
    end
  end

  describe ".suggest_identifier" do
    it "produces the same identifier as .call for the same name" do
      project = build_stubbed(:project, name: "Alpha Beta", identifier: "alpha-beta")
      batch_result = described_class.call([project]).first[:suggested_identifier]
      single_result = described_class.suggest_identifier("Alpha Beta")
      expect(single_result).to eq(batch_result)
    end
  end
end
