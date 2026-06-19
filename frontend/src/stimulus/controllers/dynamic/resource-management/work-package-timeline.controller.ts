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
import moment from 'moment';

export default class WorkPackageTimelineController extends Controller {
  static targets = ['calendar', 'granularityButton'];

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
  declare readonly hasGranularityButtonTarget:boolean;
  declare readonly granularityButtonTarget:HTMLElement;
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

  today() { this.centerOnToday(); }

  // The granularity menu items carry `view` (e.g. resourceTimelineWeeks) and
  // `label` (e.g. "Calendar week") action params.
  setView(event:ActionEvent) {
    if (!this.calendar) { return; }

    this.calendar.changeView(event.params.view as string);
    this.centerOnToday();
    this.updateGranularityLabel(event.params.label as string);
  }

  private initializeCalendar() {
    // Computed up front so the first render is already centered on today, with no
    // post-render gotoDate that would trigger a second feed fetch.
    const initialDate = moment(this.initialDateValue)
      .subtract(3, this.unitForViewName(this.initialViewValue))
      .format('YYYY-MM-DD');

    this.calendar = new Calendar(this.calendarTarget, {
      schedulerLicenseKey: this.licenseKeyValue,
      plugins: [resourceTimelinePlugin, interactionPlugin],
      initialView: this.initialViewValue,
      initialDate,
      // Custom views: a fixed span of equal-width day/week/month columns, rather
      // than FullCalendar's built-in views that zoom into hour or day slots.
      // dateIncrement is half a view's span, so prev/next page by 5 columns.
      views: {
        resourceTimelineDays: {
          type: 'resourceTimeline',
          duration: { days: 10 },
          slotDuration: { days: 1 },
          dateIncrement: { days: 5 },
          slotLabelFormat: { weekday: 'short', month: 'numeric', day: 'numeric' },
        },
        resourceTimelineWeeks: {
          type: 'resourceTimeline',
          duration: { weeks: 10 },
          slotDuration: { weeks: 1 },
          dateIncrement: { weeks: 5 },
          slotLabelFormat: { week: 'long' },
        },
        resourceTimelineMonths: {
          type: 'resourceTimeline',
          duration: { months: 10 },
          slotDuration: { months: 1 },
          dateIncrement: { months: 5 },
          slotLabelFormat: { month: 'short' },
        },
      },
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

  private centerOnToday():void {
    if (!this.calendar) { return; }

    const start = moment(this.initialDateValue)
      .subtract(3, this.unitForViewName(this.calendar.view.type))
      .format('YYYY-MM-DD');
    this.calendar.gotoDate(start);
  }

  private unitForViewName(view:string):moment.unitOfTime.DurationConstructor {
    switch (view) {
      case 'resourceTimelineDays':
        return 'days';
      case 'resourceTimelineMonths':
        return 'months';
      default:
        return 'weeks';
    }
  }

  private updateGranularityLabel(label:string):void {
    if (!label || !this.hasGranularityButtonTarget) { return; }

    const labelElement = this.granularityButtonTarget.querySelector('.Button-label');
    if (labelElement) { labelElement.textContent = label; }
  }

  private openDialog(url:string):void {
    TurboHelpers.showProgressBar();

    void fetch(url, { headers: { Accept: 'text/vnd.turbo-stream.html' } })
      .then((response) => response.text())
      .then((html) => { renderStreamMessage(html); })
      .finally(() => { TurboHelpers.hideProgressBar(); });
  }
}
