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
    class WorkPackageCardBoxComponent < ApplicationComponent
      include Primer::AttributesHelper
      include OpPrimer::ComponentHelpers

      # Renders a `Header` above the card list with the title, count badge, and
      # consumer-provided actions/menu/description.
      #
      # @param title [String] heading text rendered inside the collapsible header.
      # @param count [Integer, NilClass] optional count badge displayed alongside
      #   the title; hidden when zero or nil.
      renders_one :header, ->(title:, count: nil) {
        Header.new(title:, count:, container:, list_id:, collapsed: folded?)
      }

      # Renders a `Primer::Beta::Blankslate` when `work_packages` is empty. The
      # slot is required — `before_render` raises if it is not set.
      #
      # @param title [String] blankslate heading.
      # @param description [String, NilClass] optional secondary text.
      # @param icon [Symbol, NilClass] optional Octicon name.
      # @param system_arguments [Hash] forwarded to `Primer::Beta::Blankslate`.
      renders_one :empty_state, ->(title:, description: nil, icon: nil, **system_arguments) {
        system_arguments[:role] = "status"
        system_arguments[:aria] = merge_aria(
          system_arguments,
          aria: { live: "polite" }
        )

        blankslate = Primer::Beta::Blankslate.new(**system_arguments)
        blankslate.with_heading(tag: :h4).with_content(title)
        blankslate.with_description_content(description) if description
        blankslate.with_visual_icon(icon:) if icon
        blankslate
      }

      # When set, the box truncates `work_packages` to the first `truncate_middle`
      # rows plus a derived tail (`max(truncate_middle / 5, 1)`) and inserts a
      # show-more affordance between them. Truncation only triggers when
      # `work_packages.size > truncate_middle + 2 * tail_size`.
      #
      # @param truncate_middle [Integer] first-page size.
      # @param text [String, NilClass] copy override for the show-more label.
      #   Supports a `%{count}` placeholder. Defaults to the
      #   `work_package_card_box_component.show_more` translation key.
      renders_one :show_more, ->(truncate_middle:, text: nil) {
        ShowMore.new(truncate_middle:, text:)
      }

      # Renders a free-form footer row below the card list.
      renders_one :footer

      attr_reader :work_packages, :project, :container, :drag_and_drop, :current_user

      # @param work_packages [Enumerable<WorkPackage>] the work packages to render
      #   as cards. Truncated when the `:show_more` slot is set and the count
      #   exceeds the derived threshold.
      # @param project [Project] the project this card box is rendered in. May
      #   differ from individual `work_package.project` values when sprints or
      #   buckets are shared across projects.
      # @param container [Symbol, String, Class, ApplicationRecord] drives the box
      #   DOM id and related ids via `dom_target`.
      # @param drag_and_drop [Hash, NilClass] optional generic drag-and-drop
      #   target data. Requires `:target_id` and `:allowed_drag_type` when set.
      # @param current_user [User] passed through to each `WorkPackageCardComponent`
      #   for permission checks; defaults to `User.current`.
      # @param system_arguments [Hash] forwarded to the underlying
      #   `Primer::Beta::BorderBox`.
      def initialize(
        work_packages:,
        project:,
        container:,
        drag_and_drop: nil,
        current_user: User.current,
        **system_arguments
      )
        super()

        @work_packages = work_packages
        @project = project
        @container = container
        @drag_and_drop = drag_and_drop
        @current_user = current_user

        @system_arguments = system_arguments
        @system_arguments[:id] = container_id
        @system_arguments[:list_id] = list_id
        @system_arguments[:padding] = :condensed
        merge_drag_and_drop_data! if drag_and_drop
      end

      def before_render
        raise ArgumentError, "empty_state slot is required" unless empty_state?

        return if !show_more? || show_more.truncate_middle.is_a?(Integer)

        raise ArgumentError, "show_more requires truncate_middle: as an Integer"
      end

      def cards
        @cards ||= visible_work_packages.map do |work_package|
          WorkPackageCardComponent.new(work_package:, project:, container:, current_user:)
        end
      end

      def truncated?
        show_more? && work_packages.size > truncate_threshold
      end

      private

      def folded?
        current_user.pref[:backlogs_versions_default_fold_state] == "closed"
      end

      def container_id
        dom_target(container)
      end

      def list_id
        dom_target(container, :list)
      end

      def header_id
        dom_target(container, :header)
      end

      def merge_drag_and_drop_data!
        @system_arguments[:data] = merge_data(
          {
            data: drag_and_drop_data
          },
          @system_arguments
        )
      end

      def drag_and_drop_data
        {
          # Sprint historically used "container" alone. The shared box keeps the
          # first mirror container on the page for now until parent-specific DnD
          # handling is extracted in follow-up work.
          generic_drag_and_drop_target: "container mirrorContainer",
          target_container_accessor: ":scope > ul",
          target_id: drag_and_drop.fetch(:target_id),
          target_allowed_drag_type: drag_and_drop.fetch(:allowed_drag_type)
        }
      end

      def visible_work_packages
        return work_packages unless truncated?

        work_packages.first(show_more.truncate_middle) + work_packages.last(tail_size)
      end

      def tail_size
        return 0 unless show_more?

        [show_more.truncate_middle / 5, 1].max
      end

      def truncate_threshold
        show_more.truncate_middle + (tail_size * 2)
      end

      def omitted_count
        work_packages.size - show_more.truncate_middle - tail_size
      end

      def last_omitted_id
        if work_packages.respond_to?(:reverse_order)
          work_packages.reverse_order.offset(tail_size).limit(1).pick(:id)
        else
          work_packages[-(tail_size + 1)]&.id
        end
      end

      def show_more_id
        dom_target(container, :show_more)
      end

      def show_more_label
        if show_more.text
          format(show_more.text, count: omitted_count)
        else
          t(".show_more", count: omitted_count)
        end
      end
    end
  end
end
