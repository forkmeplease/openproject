class JiraIssueType < ApplicationRecord
  belongs_to :jira
  belongs_to :jira_import
end
