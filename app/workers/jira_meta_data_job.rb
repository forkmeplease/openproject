class JiraMetaDataJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  good_job_control_concurrency_with(
    total_limit: 2,
    enqueue_limit: 1,
    perform_limit: 1,
    key: -> { "JiraMetaDataJob-#{arguments.last}" }
  )

  def perform(jira_import_id)
    jira_import = JiraImport.find(jira_import_id)
    get_meta(jira_import)
  end

  def get_meta(jira_import)
    jira = jira_import.jira
    j = J.new(url: jira.url, personal_access_token: jira.personal_access_token)
    available = { "projects" => j.projects }
    jira_import.update!(status: "fetched", job_id: nil, available:)
  rescue StandardError => e
    jira_import.update!(status: "fetch-error", job_id: nil, error: e.message)
  end
end
