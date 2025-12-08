# frozen_string_literal: true

class CreateJiraMigrationTables < ActiveRecord::Migration[8.0]
  def change
    create_table :jiras do |t|
      t.string :url
      t.string :personal_access_token

      t.timestamps
    end

    create_table :jira_imports do |t|
      t.string :status
      t.timestamp :import_time_point
      t.bigint :author_id, null: false
      t.string :projects, array: true, default: []
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
    end

    create_table :jira_projects do |t|
      t.jsonb :payload
      t.string :jira_project_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:jira_id, :jira_project_id], unique: true

      t.timestamps
    end

    create_table :jira_project_types do |t|
      t.jsonb :payload
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }

      t.timestamps
    end

    create_table :jira_issues do |t|
      t.jsonb :payload
      t.string :jira_project_id
      t.string :jira_issue_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:jira_id, :jira_issue_id], unique: true

      t.timestamps
    end

    create_table :jira_issue_types do |t|
      t.jsonb :payload
      t.string :jira_issue_type_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:jira_id, :jira_issue_type_id], unique: true

      t.timestamps
    end

    create_table :jira_priorities do |t|
      t.jsonb :payload
      t.string :jira_priority_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:jira_id, :jira_priority_id], unique: true

      t.timestamps
    end

    create_table :jira_statuses do |t|
      t.jsonb :payload
      t.string :jira_status_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:jira_id, :jira_status_id], unique: true

      t.timestamps
    end

    create_table :jira_status_categories do |t|
      t.jsonb :payload
      t.string :jira_status_category_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:jira_id, :jira_status_category_id], unique: true

      t.timestamps
    end

    create_table :jira_fields do |t|
      t.jsonb :payload
      t.string :jira_field_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:jira_id, :jira_field_id], unique: true

      t.timestamps
    end

    create_table :jira_users do |t|
      t.jsonb :payload
      t.string :jira_user_key
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:jira_id, :jira_user_key], unique: true

      t.timestamps
    end

    create_table :open_project_jira_references do |t|
      t.string :op_entity_id
      t.string :op_entity_table
      t.string :jira_entity_id
      t.string :jira_entity_table
      t.boolean :new_op_record
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index [:op_entity_id, :op_entity_table], unique: true

      t.timestamps
    end
  end
end
