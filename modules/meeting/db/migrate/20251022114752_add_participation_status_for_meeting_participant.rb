# frozen_string_literal: true

class AddParticipationStatusForMeetingParticipant < ActiveRecord::Migration[8.0]
  def change
    add_column :meeting_participants, :participation_status, :string, null: true
    execute <<-SQL.squish
      UPDATE meeting_participants
      SET participation_status = 'unknown'
      WHERE participation_status IS NULL
    SQL
    change_column_default :meeting_participants, :participation_status, "needs-action"
    change_column_null :meeting_participants, :participation_status, false
  end
end
