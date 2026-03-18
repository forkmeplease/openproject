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

import { Controller } from '@hotwired/stimulus';

export default class WorkflowCheckboxStateController extends Controller<HTMLFormElement> {
  connect() {
    const frame = this.element.closest<HTMLElement>('turbo-frame');
    frame?.addEventListener('turbo:before-frame-render', this.onBeforeFrameRender);

    if (frame?.dataset.workflowRestorePending) {
      delete frame.dataset.workflowRestorePending;
      this.restoreState();
    } else {
      sessionStorage.removeItem(this.storageKey);
    }

    this.element.addEventListener('submit', this.onFormSubmit);
  }

  disconnect() {
    this.element.closest('turbo-frame')?.removeEventListener('turbo:before-frame-render', this.onBeforeFrameRender);
    this.element.removeEventListener('submit', this.onFormSubmit);
  }

  private onBeforeFrameRender = () => {
    this.saveState();
    const frame = this.element.closest<HTMLElement>('turbo-frame');
    if (frame) frame.dataset.workflowRestorePending = 'true';
  };

  private onFormSubmit = () => {
    sessionStorage.removeItem(this.storageKey);
  };

  private get storageKey():string {
    return `workflow-transitions-${this.formValue('type_id')}-${this.formValue('role_id')}`;
  }

  private formValue(name:string):string {
    return this.element.querySelector<HTMLInputElement>(`input[name="${name}"]`)!.value;
  }

  private saveState():void {
    const state:Record<string, boolean> = {};
    this.element.querySelectorAll<HTMLInputElement>('input[type="checkbox"]').forEach((cb) => {
      state[`${cb.dataset.oldStatus}:${cb.dataset.newStatus}:${cb.value}`] = cb.checked;
    });
    sessionStorage.setItem(this.storageKey, JSON.stringify(state));
  }

  private restoreState():void {
    const raw = sessionStorage.getItem(this.storageKey);
    if (!raw) return;

    const state = JSON.parse(raw) as Record<string, boolean>;
    this.element.querySelectorAll<HTMLInputElement>('input[type="checkbox"]').forEach((cb) => {
      const key = `${cb.dataset.oldStatus}:${cb.dataset.newStatus}:${cb.value}`;
      if (key in state) cb.checked = state[key];
    });
  }
}
