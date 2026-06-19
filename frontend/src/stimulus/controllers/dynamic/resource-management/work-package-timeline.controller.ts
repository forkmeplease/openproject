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

import { Controller, ActionEvent } from '@hotwired/stimulus';
import { Calendar } from '@fullcalendar/core';
import interactionPlugin from '@fullcalendar/interaction';
import resourceTimelinePlugin from '@fullcalendar/resource-timeline';
import allLocales from '@fullcalendar/core/locales-all';
import { renderStreamMessage } from '@hotwired/turbo';
import { TurboHelpers } from 'core-turbo/helpers';

export default class WorkPackageTimelineController extends Controller {
  static targets = ['calendar'];

  static values = {
    resourcesUrl: String,
    eventsUrl: String,
    locale: String,
    firstDay: Number,
    initialDate: String,
    initialView: String,
    licenseKey: String,
    canAllocate: Boolean,
    newAllocationUrl: String,
  };

  declare readonly calendarTarget:HTMLElement;
  declare readonly resourcesUrlValue:string;
  declare readonly eventsUrlValue:string;
  declare readonly localeValue:string;
  declare readonly firstDayValue:number;
  declare readonly initialDateValue:string;
  declare readonly initialViewValue:string;
  declare readonly licenseKeyValue:string;
  declare readonly canAllocateValue:boolean;
  declare readonly newAllocationUrlValue:string;

  private calendar:Calendar;

  connect() {
    // Defer so the container has its final size before FullCalendar measures it.
    setTimeout(() => this.initializeCalendar(), 5);
  }

  disconnect() {
    if (this.calendar) {
      this.calendar.destroy();
    }
  }

  prev() { this.calendar?.prev(); }

  next() { this.calendar?.next(); }

  today() { this.calendar?.today(); }

  // The granularity menu items carry a `view` action param (e.g. resourceTimelineWeek).
  setView(event:ActionEvent) {
    this.calendar?.changeView(event.params.view as string);
  }

  private initializeCalendar() {
    this.calendar = new Calendar(this.calendarTarget, {
      schedulerLicenseKey: this.licenseKeyValue,
      plugins: [resourceTimelinePlugin, interactionPlugin],
      initialView: this.initialViewValue,
      initialDate: this.initialDateValue,
      locales: allLocales,
      locale: this.localeValue,
      firstDay: this.firstDayValue,
      headerToolbar: false,
      nowIndicator: true,
      height: '100%',
      resourceAreaColumns: [{
        headerContent: '',
        cellContent: (arg) => ({ html: (arg.resource?.extendedProps?.html as string) || '' }),
      }],
      resources: (_info, success, failure) => {
        fetch(this.resourcesUrlValue, { headers: { Accept: 'application/json' } })
          .then((response) => response.json())
          .then((data:{ resources:unknown[] }) => success(data.resources as never))
          .catch(failure);
      },
      events: (info, success, failure) => {
        const url = new URL(this.eventsUrlValue, window.location.origin);
        url.searchParams.set('start', info.startStr);
        url.searchParams.set('end', info.endStr);
        fetch(url.toString(), { headers: { Accept: 'application/json' } })
          .then((response) => response.json())
          .then((data:{ events:unknown[] }) => success(data.events as never))
          .catch(failure);
      },
      eventContent: (arg) => ({ html: (arg.event.extendedProps.html as string) || '' }),
      eventClassNames: (arg) => (arg.event.extendedProps.overbooked ? ['resource-allocation--overbooked'] : []),
      selectable: this.canAllocateValue && this.newAllocationUrlValue.length > 0,
      select: (info) => {
        const resourceId = info.resource?.id ?? '';
        const inclusiveEnd = new Date(info.end.getTime() - 86400000).toISOString().slice(0, 10);
        const url = `${this.newAllocationUrlValue}?work_package_id=${resourceId}&start_date=${info.startStr}&end_date=${inclusiveEnd}`;
        this.openDialog(url);
        this.calendar.unselect();
      },
    });

    this.calendar.render();
  }

  private openDialog(url:string):void {
    TurboHelpers.showProgressBar();

    void fetch(url, { headers: { Accept: 'text/vnd.turbo-stream.html' } })
      .then((response) => response.text())
      .then((html) => { renderStreamMessage(html); })
      .finally(() => { TurboHelpers.hideProgressBar(); });
  }
}
