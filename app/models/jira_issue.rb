class JiraIssue < ApplicationRecord
  belongs_to :jira
  belongs_to :jira_import
  belongs_to :jira_project
end
