class JiraFetchDataJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  good_job_control_concurrency_with(
    total_limit: 2,
    enqueue_limit: 1,
    perform_limit: 1,
    key: -> { "JiraSyncJob-#{arguments.last}" }
  )

=begin
jira= Jira.new
jira.url = "https://jira-software.local/"
jira.personal_access_token = "<personal_access_token>"
jira.save
j = J.new(url: jira.url, personal_access_token: jira.personal_access_token)
JiraSyncJob.new.perform(1)
=end
  def perform(jira_id)
    ActiveRecord::Base.transaction do
      jira = Jira.find(jira_id)
      jira_import = JiraImport.find_or_create_by!(status: "init_sync_in_progress", jira_id: jira_id)
      jira_import.import_time_point ||= Time.now
      jira_import.save
      jira_import_id = jira_import.id

      updated_at = Time.now
      created_at = updated_at

      # PROJECTS SYNC
      j = J.new(url: jira.url, personal_access_token: jira.personal_access_token)
      projects_upsert_data = j.projects.map do |p|
        {
          payload: p,
          jira_id:,
          jira_project_id: p.fetch("id"),
          jira_import_id: jira_import.id,
          created_at:,
          updated_at:
        }
      end
      upsert_result = JiraProject.upsert_all(projects_upsert_data, unique_by: [:jira_id, :jira_project_id])


      # PROJECT ISSUES SYNC
      JiraProject.where(jira_id:).each do |jira_project|
        already_synced_issue_ids = JiraIssue.where(jira_import_id:, jira_project_id: jira_project.id).pluck(Arel.sql("payload->>'id'"))
        jql = "project=#{jira_project.payload["key"]} AND updated <= '#{jira_import.import_time_point.strftime("%Y-%m-%d %H:%M")}'"
        # TODO Use POST not GET to avoid: having a long list of issues can exceed a server limit for request URI length.
        jql << " AND id NOT IN (#{already_synced_issue_ids.join(",")})" if already_synced_issue_ids.any?
        result = j.issues(jql: ,
                          start_at: 0,
                          max_results: 5)
        total = result["total"]
        start_at = result["startAt"]
        max_results = result["maxResults"]
        issues = result["issues"]
        issues_upsert_data = result["issues"].map do |issue|
          {
            payload: issue,
            jira_id: jira_id,
            jira_project_id: jira_project.id,
            jira_issue_id: issue.fetch("id"),
            jira_import_id: jira_import.id,
            created_at:,
            updated_at:
          }
        end
        upsert_result = JiraIssue.upsert_all(issues_upsert_data, unique_by: [:jira_id, :jira_issue_id])
        while(total > start_at + max_results)
          start_at = start_at + max_results
          result = j.issues(jql:,
                            start_at:,
                            max_results: 5)
          total = result["total"]
          start_at = result["startAt"]
          max_results = result["maxResults"]
          issues = result["issues"]
          issues_upsert_data = result["issues"].map do |issue|
            {
              payload: issue,
              jira_id: jira_id,
              jira_project_id: jira_project.id,
              jira_issue_id: issue.fetch("id"),
              jira_import_id: jira_import.id,
              created_at:,
              updated_at:
            }
          end
          upsert_result = JiraIssue.upsert_all(issues_upsert_data, unique_by: [:jira_id, :jira_issue_id])
        end
      end

      # USERS with GROUP memberships SYNC
      start_at = 0
      max_results = 1 # It should be 1000 to reduce the number of requests
      jira_users = j.users_search(start_at: , max_results: )
      users_upsert_data = jira_users.map do |jira_user_from_search|
        jira_user_key = jira_user_from_search.fetch('key')
        # here we send a direct user request to get group memberships
        # which are not returned by users_search endpoint
        jira_user_by_key = j.user_by_key(key: jira_user_key)
        {
          payload: jira_user_by_key,
          jira_id: jira_id,
          jira_import_id: jira_import.id,
          jira_user_key: ,
          created_at:,
          updated_at:
        }
      end
      upsert_result = JiraUser.upsert_all(users_upsert_data, unique_by: [:jira_id, :jira_user_key])

      while(jira_users.any?)
        start_at = start_at + jira_users.count
        jira_users = j.users_search(start_at: , max_results: )
        users_upsert_data = jira_users.map do |jira_user_from_search|
          jira_user_key = jira_user_from_search.fetch('key')
          # here we send a direct user request to get group memberships
          # which are not returned by users_search endpoint
          jira_user_by_key = j.user_by_key(key: jira_user_key)
          {
            payload: jira_user_by_key,
            jira_id: jira_id,
            jira_import_id: jira_import.id,
            jira_user_key:,
            created_at:,
            updated_at:
          }
        end
        upsert_result = JiraUser.upsert_all(users_upsert_data, unique_by: [:jira_id, :jira_user_key])
      end


      # ISSUE TYPES SYNC
      issue_types = j.issue_types
      issue_types_upsert_data = issue_types.map do |issue_type|
        {
          payload: issue_type,
          jira_id: jira_id,
          jira_issue_type_id: issue_type.fetch("id"),
          jira_import_id: jira_import.id,
          created_at:,
          updated_at:
        }
      end
      upsert_result = JiraIssueType.upsert_all(issue_types_upsert_data, unique_by: [:jira_id, :jira_issue_type_id])

      # PRIORITIES SYNC
      priorities = j.priorities
      priorities_upsert_data = priorities.map do |priority|
        {
          payload: priority,
          jira_id: jira_id,
          jira_priority_id: priority.fetch("id"),
          jira_import_id: jira_import.id,
          created_at:,
          updated_at:
        }
      end
      upsert_result = JiraPriority.upsert_all(priorities_upsert_data, unique_by: [:jira_id, :jira_priority_id])

      # STATUSES SYNC
      statuses = j.statuses
      statuses_upsert_data = statuses.map do |status|
        {
          payload: status,
          jira_id: jira_id,
          jira_status_id: status.fetch("id"),
          jira_import_id: jira_import.id,
          created_at:,
          updated_at:
        }
      end
      upsert_result = JiraStatus.upsert_all(statuses_upsert_data, unique_by: [:jira_id, :jira_status_id])

      # STATUS CATEGORIES SYNC
      status_categories = j.status_categories
      status_categories_upsert_data = status_categories.map do |status_category|
        {
          payload: status_category,
          jira_id: jira_id,
          jira_status_category_id: status_category.fetch("id"),
          jira_import_id: jira_import.id,
          created_at:,
          updated_at:
        }
      end
      upsert_result = JiraStatusCategory.upsert_all(status_categories_upsert_data, unique_by: [:jira_id, :jira_status_category_id])

      # FIELDS SYNC
      fields = j.fields
      fields_upsert_data = fields.map do |field|
        {
          payload: field,
          jira_id: jira_id,
          jira_field_id: field.fetch("id"),
          jira_import_id: jira_import.id,
          created_at:,
          updated_at:
        }
      end
      upsert_result = JiraField.upsert_all(fields_upsert_data, unique_by: [:jira_id, :jira_field_id])

      jira_import.status = "init_sync_done"
      jira_import.save!
    end
  end
end
