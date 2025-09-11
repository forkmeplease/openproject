/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
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

declare module 'idiomorph' {
  interface ConfigHeadInternal {
    style:'merge'|'append'|'morph'|'none';
    block:boolean;
    ignore:boolean;
    shouldPreserve:(element:Element) => boolean;
    shouldReAppend:(element:Element) => boolean;
    shouldRemove:(element:Element) => boolean;
    afterHeadMorphed:(oldHead:Element, options?:{ added?:Node[]; kept?:Element[]; removed?:Element[] }) => void;
  }
  interface ConfigCallbacksInternal {
    beforeNodeAdded:(node:Node) => boolean;
    afterNodeAdded:(node:Node) => void;
    beforeNodeMorphed:(oldNode:Element, newNode:Node) => boolean;
    afterNodeMorphed:(oldNode:Element, newNode:Node) => void;
    beforeNodeRemoved:(node:Element) => boolean;
    afterNodeRemoved:(node:Element) => void;
    beforeAttributeUpdated:(attr:string, element:Element, updateType:'update'|'remove') => boolean;
  }
  interface ConfigBase<Head, Callbacks> {
    morphStyle:'innerHTML'|'outerHTML';
    ignoreActive:boolean;
    ignoreActiveValue:boolean;
    restoreFocus:boolean;
    head:Head;
    callbacks:Callbacks;
  }

  type ConfigInternal = ConfigBase<ConfigHeadInternal, ConfigCallbacksInternal>;
  type ConfigHead = Partial<ConfigHeadInternal>;
  type ConfigCallbacks = Partial<ConfigCallbacksInternal>;
  type Config = Partial<ConfigInternal<ConfigHead, ConfigCallbacks>>;

  export const Idiomorph:{
    morph(ldNode:Element|Document, newContent?:Element|Node|HTMLCollection|Node[]|string|null, options?:Config);
    defaults:ConfigInternal;
  };

  export { Idiomorph };
}
