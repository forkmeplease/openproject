class Jira < ApplicationRecord
  def available_projects
    @available_projects ||= begin
                              j = J.new(url:, personal_access_token:)
                              j.projects
                            end
  end
end
