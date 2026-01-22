class JiraFetchProjectsJob < ApplicationJob
  def perform(jira_import_id)
    jira_import  = JiraImport.find(jira_import_id)
    project_ids = jira_import.projects
    jira = jira_import.jira
    jira_id = jira.id
    updated_at = Time.now
    created_at = updated_at
    j = J.new(url: jira.url, personal_access_token: jira.personal_access_token)

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

    # PROJECTS SYNC
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


    # ISSUES SYNC
    JiraProject.where(jira_id:, jira_project_id: project_ids).each do |jira_project|
      jql = "project=#{jira_project.payload["key"]}"
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
  end
end
