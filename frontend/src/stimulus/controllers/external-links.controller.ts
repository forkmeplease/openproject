//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ApplicationController } from 'stimulus-use';
import { useMutation } from 'stimulus-use';

const EXTERNAL_LINK_QUERY = 'a[href^="http"]';
const BLANK_LINK_DESCRIPTION_ID = 'open-blank-target-link-description';

const isElement = (node:Node):node is Element => node.nodeType === Node.ELEMENT_NODE;
const isExternalLink = (elem:Element):elem is HTMLAnchorElement => elem.matches(EXTERNAL_LINK_QUERY) && (elem as HTMLAnchorElement).hostname !== window.location.hostname;

/**
 * Dynamically observes all links in the page, including those added later via Turbo frames or DOM mutations.
 *
 * For external links (pointing to a different domain than the current page):
 *   - Sets `target="_blank"` to open in a new tab.
 *   - Sets `rel="noopener noreferrer"` for security and performance.
 *   - Adds `aria-describedby` pointing to a description element (`BLANK_LINK_DESCRIPTION_ID`) to inform
 *     users of assistive technologies that the link opens in a new tab.
 *
 * For internal links (same domain):
 *   - Ensures `target="_top"` and removes the `rel` attribute to keep default behavior.
 *
 * This ensures accessibility, security, and consistent behavior for all links, including dynamically
 * loaded content.
 */
export default class ExternalLinksController extends ApplicationController {
  connect() {
    useMutation(this, { attributes: true, childList: true, subtree: true, attributeFilter: ['href'] });

    // Initial pass: handle existing blank links (accessibility)
    document.querySelectorAll<HTMLAnchorElement>(EXTERNAL_LINK_QUERY).forEach((link)=>{
      if (link.hostname !== window.location.hostname) {
        updateExternalLink(link);
      }
    });
  }

  mutate(mutations:MutationRecord[]) {
    mutations.forEach((mutation) => {
      mutation.addedNodes.forEach((node) => {
        if (isElement(node)) {
          // Added element itself is a blank link
          if (isExternalLink(node)) updateExternalLink(node);

          // Added sub-trees
          node.querySelectorAll<HTMLAnchorElement>(EXTERNAL_LINK_QUERY).forEach((link)=>{
            if (link.hostname !== window.location.hostname) {
              updateExternalLink(link);
            }
          });
        }
      });

      // Attribute changes
      if (
        mutation.type === 'attributes' &&
        mutation.attributeName === 'target' &&
        isElement(mutation.target) &&
        isExternalLink(mutation.target)
      ) {
        updateExternalLink(mutation.target);
      }
    });
  }
}

function updateExternalLink(link:HTMLAnchorElement) {
  const existingValue = link.getAttribute('aria-describedby');
  link.target = '_blank';
  link.rel = 'noopener noreferrer';

  if (!existingValue) {
    link.setAttribute('aria-describedby', BLANK_LINK_DESCRIPTION_ID);
  } else if (!existingValue.split(/\s+/).includes(BLANK_LINK_DESCRIPTION_ID)) {
    link.setAttribute('aria-describedby', `${existingValue} ${BLANK_LINK_DESCRIPTION_ID}`);
  }
}
