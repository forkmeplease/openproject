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

module OpenProject::TextFormatting::Formats
  module Markdown
    # Static-HTML sibling of `Markdown::Formatter`. Shares the same filter
    # chain so identifier resolution, mention handling, and link rendering
    # stay consistent, but signals `context[:as_static_html]` so matchers
    # and filters emit server-rendered anchors in place of JS-hydrated
    # custom elements. Intended for channels that cannot run JS — HTML
    # mailers, server-side previews, archival exports — where dynamic
    # widgets would collapse to empty placeholders.
    class StaticHtmlFormatter < Formatter
      def initialize(context)
        super(context.merge(as_static_html: true))
      end

      def self.format
        :markdown_as_static_html
      end
    end
  end
end
