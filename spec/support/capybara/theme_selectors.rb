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

Capybara.add_selector :theme do
  label "Theme"

  xpath do |locator|
    xpath = XPath.descendant(:body)
    xpath = builder(xpath).add_attribute_conditions("data-color-mode": locator) if locator
    xpath
  end

  expression_filter(:contrast) do |expr, contrast|
    if contrast
      # Extract the theme from the existing expression
      theme_match = expr.to_s.match(/data-color-mode='([^']+)'/)
      if theme_match
        theme = theme_match[1]
        contrast_suffix = "_high_contrast"
        builder(expr).add_attribute_conditions("data-#{theme}-theme": "#{theme}#{contrast_suffix}")
      else
        expr
      end
    else
      expr
    end
  end

  describe_expression_filters do |contrast: nil, **|
    contrast ? " with high contrast" : ""
  end
end

Capybara.add_selector :auto_theme_config do
  label "Auto Theme Config"

  xpath do |_locator|
    xpath = XPath.descendant(:body)
    xpath = builder(xpath).add_attribute_conditions("data-auto-theme-switcher-theme-value": "sync_with_os")
    xpath
  end

  expression_filter(:enable_auto_light_contrast) do |expr, enabled|
    if enabled
      builder(expr).add_attribute_conditions("data-auto-theme-switcher-enable-auto-light-theme-contrast-value": "true")
    else
      expr
    end
  end

  expression_filter(:enable_auto_dark_contrast) do |expr, enabled|
    if enabled
      builder(expr).add_attribute_conditions("data-auto-theme-switcher-enable-auto-dark-theme-contrast-value": "true")
    else
      expr
    end
  end

  describe_expression_filters do |enable_auto_light_contrast: nil, enable_auto_dark_contrast: nil, **|
    desc = +""
    desc << " with auto light contrast" if enable_auto_light_contrast
    desc << " with auto dark contrast" if enable_auto_dark_contrast
    desc
  end
end

module Capybara
  module RSpecMatchers
    def have_theme(locator = nil, contrast: false, **, &)
      Matchers::HaveSelector.new(:theme, locator, contrast:, **, &)
    end

    def have_no_theme(locator = nil, **, &)
      Matchers::NegatedMatcher.new(have_theme(locator, **, &))
    end

    def have_auto_theme_config(enable_auto_light_contrast: false, enable_auto_dark_contrast: false, **, &)
      Matchers::HaveSelector.new(:auto_theme_config, nil,
                                 enable_auto_light_contrast:,
                                 enable_auto_dark_contrast:,
                                 **, &)
    end
  end
end
