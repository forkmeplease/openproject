class OpenProjectJiraReference < ApplicationRecord
  belongs_to :jira
  belongs_to :jira_import

  def op_leg
    op_entity_class.constantize.find(op_entity_id)
  end

  def jira_leg
    jira_entity_class.constantize.find(jira_entity_id)
  end
end
