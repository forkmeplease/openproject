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

module WaitHelpers
  # Wait for an element to stop being resized on the page
  #
  # Useful to wait for a primer dialog to finish opening, as they have an
  # opening animation.
  #
  # @param selector_or_element [String or Capybara::Node::Element] CSS selector or element to wait for
  # @param wait [Integer] Optional maximum time to wait in seconds, defaults to
  #   Capybara's default wait time
  def wait_for_size_animation_completion(selector_or_element, wait: Capybara.default_max_wait_time)
    element =
      case selector_or_element
      when String
        page.find(selector_or_element, wait:)
      when Capybara::Node::Element
        selector_or_element
      else
        raise ArgumentError, "Invalid selector or element"
      end
    page.document.synchronize do
      initial_position = page.evaluate_script("arguments[0].getBoundingClientRect()", element)
      sleep 0.1 # Small delay to allow for animation
      final_position = page.evaluate_script("arguments[0].getBoundingClientRect()", element)
      raise Capybara::ExpectationNotMet, "Animation not finished" unless initial_position == final_position
    end
  end

  # Executes the given block and waits for a Turbo stream to be rendered.
  #
  # Sets up a JS event listener BEFORE yielding, avoiding the race condition
  # where the stream renders before the listener is registered.
  #
  # @example
  #   wait_for_turbo_stream { click_button "Save" }
  #   expect(page).to have_text("Saved")
  #
  def wait_for_turbo_stream(wait: 10, &block)
    return block ? yield : nil unless wait

    timeout = wait == true ? 10 : wait
    timeout_ms = timeout * 1000
    page.execute_script(<<~JS, timeout_ms)
      window.__opTurboStreamRendered = new Promise((resolve, reject) => {
        const handler = () => { clearTimeout(timer); document.removeEventListener('op:turbo-stream-rendered', handler); resolve(true); };
        const timer = setTimeout(() => { document.removeEventListener('op:turbo-stream-rendered', handler); reject(new Error('wait_for_turbo_stream: no turbo stream rendered within #{timeout}s')); }, arguments[0]);
        document.addEventListener('op:turbo-stream-rendered', handler);
      });
    JS

    block_result = yield

    result = page.evaluate_async_script(<<~JS)
      window.__opTurboStreamRendered.then(() => {
        delete window.__opTurboStreamRendered;
        arguments[0]({ success: true });
      }).catch((e) => {
        delete window.__opTurboStreamRendered;
        arguments[0]({ success: false, error: e.message });
      });
    JS

    raise result["error"] if result.is_a?(Hash) && !result["success"]

    block_result
  end

  # Executes the given block and waits for a Turbo Drive navigation to complete.
  #
  # Sets up a listener for turbo:load BEFORE yielding, avoiding the race
  # condition where the navigation completes before the listener is registered.
  #
  # @example
  #   wait_for_turbo { click_link_or_button "Save" }
  #   expect(page).to have_text("Saved")
  #
  def wait_for_turbo(wait: 10, &block)
    return block ? yield : nil unless wait

    timeout = wait == true ? 10 : wait
    timeout_ms = timeout * 1000
    page.execute_script(<<~JS, timeout_ms)
      window.__opTurboLoaded = new Promise((resolve, reject) => {
        const handler = () => { clearTimeout(timer); document.removeEventListener('turbo:load', handler); resolve(true); };
        const timer = setTimeout(() => { document.removeEventListener('turbo:load', handler); reject(new Error('wait_for_turbo: no turbo:load event within #{timeout}s')); }, arguments[0]);
        document.addEventListener('turbo:load', handler);
      });
    JS

    block_result = yield

    result = page.evaluate_async_script(<<~JS)
      window.__opTurboLoaded.then(() => {
        delete window.__opTurboLoaded;
        arguments[0]({ success: true });
      }).catch((e) => {
        delete window.__opTurboLoaded;
        arguments[0]({ success: false, error: e.message });
      });
    JS

    raise result["error"] if result.is_a?(Hash) && !result["success"]

    block_result
  end

  # Executes the given block and waits for a Turbo frame navigation to complete.
  #
  # Sets up a listener for turbo:frame-load BEFORE yielding, avoiding the race
  # condition where the frame loads before the listener is registered.
  #
  # Pass `frame:` to wait for a specific frame by id; only a turbo:frame-load
  # whose target element has that id satisfies the wait. With no `frame:` the
  # first frame load of any frame satisfies it.
  #
  # @example
  #   wait_for_turbo_frame { click_link "Remove column" }
  #   wait_for_turbo_frame(frame: "backlogs_container") { drop_card }
  #
  def wait_for_turbo_frame(frame: nil, wait: 10, &block)
    return block ? yield : nil unless wait

    timeout = wait == true ? 10 : wait
    timeout_ms = timeout * 1000
    frame_id = frame&.to_s
    page.execute_script(<<~JS, timeout_ms, frame_id)
      const timeoutMs = arguments[0];
      const frameId = arguments[1];
      window.__opTurboFrameLoaded = new Promise((resolve, reject) => {
        const handler = (event) => {
          if (frameId && !(event.target instanceof Element && event.target.id === frameId)) { return; }
          clearTimeout(timer);
          document.removeEventListener('turbo:frame-load', handler);
          resolve(true);
        };
        const timer = setTimeout(() => { document.removeEventListener('turbo:frame-load', handler); reject(new Error('wait_for_turbo_frame: no turbo:frame-load event within #{timeout}s')); }, timeoutMs);
        document.addEventListener('turbo:frame-load', handler);
      });
    JS

    block_result = yield

    result = page.evaluate_async_script(<<~JS)
      window.__opTurboFrameLoaded.then(() => {
        delete window.__opTurboFrameLoaded;
        arguments[0]({ success: true });
      }).catch((e) => {
        delete window.__opTurboFrameLoaded;
        arguments[0]({ success: false, error: e.message });
      });
    JS

    raise result["error"] if result.is_a?(Hash) && !result["success"]

    block_result
  end
end

RSpec.configure do |config|
  config.include WaitHelpers, type: :feature
end
