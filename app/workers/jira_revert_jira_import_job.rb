class JiraRevertJiraImportJob < ApplicationJob
  def perform(jira_import_id)
    jira_import  = JiraImport.find(jira_import_id)
    project_ids = jira_import.projects
    jira = jira_import.jira
    jira_id = jira.id
    user = User.system

    ActiveRecord::Base.transaction do
      OpenProjectJiraReference
        .where(jira_import_id: jira_import.id,)
        .where.not(op_entity_class: "WorkPackage")
        .find_each do |ref|
        op_leg = ref.op_leg
        uses_existing = ref.uses_existing
        if op_leg.is_a? Project
          service_call = ::Projects::DeleteService.new(user:, model: op_leg).call
          if service_call.failure?
            raise ActiveRecord::Rollback
          end
        elsif op_leg.is_a? WorkPackage
          # removed with project
        elsif op_leg.is_a? Type
          op_leg.destroy unless uses_existing
        elsif op_leg.is_a? Status
          op_leg.destroy unless uses_existing
        elsif op_leg.is_a? IssuePriority
          op_leg.destroy unless uses_existing
        end
      end
      OpenProjectJiraReference.where(jira_import_id: jira_import.id).delete_all
    end

    jira_import.update!(status: JiraImport::REVERTED, job_id: nil)
  rescue StandardError => e
    jira_import.update!(status: JiraImport::REVERT_ERROR, job_id: nil, error: e.message)
  end
end
