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

module MeetingAgendaItems
  class UpdateService < ::BaseServices::Update
    include AfterPerformHook

    private

    def before_perform(params)
      @old_meeting_id = model.meeting_id if model.persisted?

      super
    end

    def after_perform(call)
      super

      if call.success? && @old_meeting_id != call.result.meeting_id
        copy_attachments_to_new_meeting(call.result, @old_meeting_id)
      end

      call
    end

    def copy_attachments_to_new_meeting(agenda_item, old_meeting_id)
      return if agenda_item.notes.blank?

      old_meeting = Meeting.find(old_meeting_id)
      old_meeting.attachments.each do |attachment|
        next unless agenda_item.notes.include?("/attachments/#{attachment.id}/")

        copy_attachment(attachment, agenda_item.meeting, agenda_item)
      end
    end

    def copy_attachment(source_attachment, target_meeting, agenda_item)
      copy = Attachment.new(
        source_attachment
          .dup
          .attributes
          .except("file")
          .merge("author_id" => user.id, "container_id" => target_meeting.id)
      )

      source_attachment.file.copy_to(copy)
      copy.save!

      updated_notes = agenda_item.notes.gsub(
        "/api/v3/attachments/#{source_attachment.id}/content",
        "/api/v3/attachments/#{copy.id}/content"
      )

      agenda_item.update!(notes: updated_notes)
    end
  end
end
