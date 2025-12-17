/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

/**
 * Shadow DOM styles for BlockNote editor
 *
 * Note: These styles are kept in a TypeScript constant to avoid build configuration complexity.
 * Primer component styles (Banner, SkeletonBox, etc.) are loaded via shadow-dom-primer.scss bundle.
 */
const blockNoteStylesContent = `
.block-note-editor-container {
  align-items: center;
  display: flex;
  flex-direction: column-reverse;
  gap: 10px;
  height: 100%;
  max-width: none;
  padding: 0;
}

.block-note-editor-container > .bn-editor {
  height: 100%;
  max-width: 800px;
  min-height: 80vh;
  overflow: auto;
  width: 100%;
  background-color: transparent;
  padding-top: 10px;
  padding-inline: 0;
}
`;

const blockNoteStyleSheet = new CSSStyleSheet();
blockNoteStyleSheet.replaceSync(blockNoteStylesContent);

export { blockNoteStyleSheet };
