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

module HasPrincipalDetails
  extend ActiveSupport::Concern

  # Columns on the detail table that are managed automatically
  # and should not be delegated to the principal.
  DETAIL_INTERNAL_COLUMNS = %w[id principal_id created_at updated_at].freeze

  # AR's dup doesn't copy associations, so the detail would be lost.
  # Duplicate it so the copy behaves like a normal AR dup with all attributes.
  def dup
    super.tap do |copy|
      copy.detail = detail.dup if detail.present?
    end
  end

  class_methods do
    # Declares a detail table for this principal subclass.
    # The detail model class is generated automatically — no separate file needed.
    #
    # The block is evaluated in the context of the generated detail class,
    # so you can declare associations, validations, callbacks, etc.
    #
    # The back-reference belongs_to, uniqueness constraint, and attribute
    # delegation are set up automatically.
    #
    # Example:
    #   has_principal_details do
    #     belongs_to :parent, class_name: "Group", optional: true
    #     validates :parent, presence: true, if: -> { parent_id.present? }
    #   end
    #
    def has_principal_details(&) # rubocop:disable Naming/PredicatePrefix
      detail_class = build_detail_class(&)
      association_name = detail_class.name.underscore.to_sym

      setup_detail_association(association_name, detail_class)
      setup_detail_aliases(association_name)
      setup_detail_delegation(association_name, detail_class)
    end

    private

    def build_detail_class(&block)
      owner_name = model_name.element.to_sym # e.g. :group

      klass = Class.new(ApplicationRecord) do
        belongs_to owner_name,
                   inverse_of: :"#{owner_name}_detail",
                   foreign_key: :principal_id

        validates owner_name, presence: true, uniqueness: true

        class_eval(&block) if block
      end

      # Register as a named constant so it appears in stack traces, queries, etc.
      Object.const_set("#{name}Detail", klass)
    end

    def setup_detail_association(association_name, detail_class) # rubocop:disable Metrics/AbcSize
      has_one association_name, foreign_key: :principal_id,
                                dependent: :destroy,
                                inverse_of: model_name.element.to_sym,
                                class_name: detail_class.name,
                                autosave: true
      accepts_nested_attributes_for association_name

      scope :with_detail, -> { joins(association_name).includes(association_name) }

      scope :where_detail, ->(**conditions) {
        joins(association_name).where(detail_class.table_name => conditions)
      }

      # Validate the detail record and promote its errors onto the principal
      # so they appear as direct attributes (e.g. group.errors[:parent]).
      validate do
        next if detail.nil? || detail.valid?

        detail.errors.each do |error|
          errors.add(error.attribute, error.type, message: error.message)
        end
      end

      # Auto-build the detail record so it's never nil
      after_initialize do
        build_detail if new_record? && detail.nil?
      end
    end

    def setup_detail_aliases(association_name)
      alias_method :detail, association_name
      alias_method :detail=, :"#{association_name}="
      alias_method :build_detail, :"build_#{association_name}"
    end

    def setup_detail_delegation(association_name, detail_class)
      # Try to set up delegation eagerly so that writer methods exist
      # during assign_attributes in new/create. Requires DB + table.
      if ActiveRecord::Base.connected? && detail_class.table_exists?
        finalize_detail_delegation!(association_name, detail_class)
      end

      # Fallback for when eager setup was skipped (db:create, db:migrate).
      # finalize_detail_delegation! is idempotent via @_detail_delegation_set_up.
      after_initialize do
        self.class.send(:finalize_detail_delegation!, association_name, detail_class)
      end
    end

    # Defines a writer method that auto-builds the detail record.
    # This is necessary because `assign_attributes` runs before
    # `after_initialize`, so `allow_nil: true` delegation would
    # silently discard values when the detail hasn't been built yet.
    def define_detail_writer(association_name, writer)
      define_method(writer) do |value|
        record = send(association_name) || send(:"build_#{association_name}")
        record.send(writer, value)
      end
    end

    def finalize_detail_delegation!(association_name, detail_class)
      return if @_detail_delegation_set_up

      @_detail_delegation_set_up = true

      # Delegate all non-internal columns
      (detail_class.column_names - DETAIL_INTERNAL_COLUMNS).each do |col|
        delegate col.to_sym, to: association_name
        define_detail_writer(association_name, :"#{col}=")
      end

      # For belongs_to associations, also delegate the object reader/writer
      # (columns like parent_id are already covered above)
      detail_class.reflect_on_all_associations(:belongs_to).each do |reflection|
        next if reflection.name == model_name.element.to_sym # skip the back-reference

        delegate reflection.name, to: association_name
        define_detail_writer(association_name, :"#{reflection.name}=")
      end
    end
  end
end
