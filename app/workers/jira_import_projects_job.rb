class JiraImportProjectsJob < ApplicationJob
  def perform(jira_import_id)
    jira_import  = JiraImport.find(jira_import_id)
    project_ids = jira_import.projects
    jira = jira_import.jira
    jira_id = jira.id
    updated_at = Time.now
    created_at = updated_at
    user = User.system

    ActiveRecord::Base.transaction do
      created_projects = []
      created_wps = {}
      JiraProject.where(jira_id:, jira_project_id: project_ids).each do |jira_project|
        ### PROJECT
        service_call = Projects::CreateService
                         .new(user:)
                         .call(
                           name: jira_project.payload.fetch("name"),
                           identifier: jira_project.payload.fetch("key").downcase,
                           description: jira_project.payload.fetch("description"),
                           active: true,
                           public: false,
                           parent: nil,
                           status_code: nil,
                           status_explanation: nil,
                           templated: false,
                           workspace_type: "project"
                         )
        project = service_call.result
        if service_call.success?
          created_projects << project
          created_wps[project.id] = []
          create_reference!(
            op_leg: project,
            jira_leg: jira_project,
            jira_import:,
            uses_existing: false
          )
          JiraIssue.where(jira_id:, jira_project_id: jira_project.id).each do |jira_issue|
            ### TYPE
            issue_type = jira_issue.payload["fields"]["issuetype"]
            type =  Type.where("LOWER(name) = LOWER(?)", issue_type["name"]).first
            uses_existing = true

            if type.blank?
              service_call = WorkPackageTypes::CreateService
                               .new(user:)
                               .call(
                                 name: issue_type["name"],
                                 description: issue_type["description"],
                                 is_default: false,
                               )
              if service_call.success?
                type = service_call.result
                uses_existing = false
              else
                binding.pry
                raise ActiveRecord::Rollback
              end
            end
            service_call = WorkPackageTypes::UpdateService.new(
                user:,
                model: type,
                contract_class: WorkPackageTypes::UpdateProjectsContract
              ).call(
                project_ids: (type.project_ids + [project.id]).tap(&:uniq!).map(&:to_s)
              )
            if service_call.success?
              type = service_call.result
              jira_issue_type = JiraIssueType.find_by!(jira_issue_type_id: issue_type["id"], jira_id:)
              create_reference!(
                op_leg: type,
                jira_leg: jira_issue_type,
                jira_import:,
                uses_existing:
              )
            else
              binding.pry
              raise ActiveRecord::Rollback
            end

            ### STATUS
            issue_status = jira_issue.payload["fields"]["status"]
            status = Status.where("LOWER(name) = LOWER(?)", issue_status["name"]).first
            uses_existing = true
            if status.blank?
              status = Status.create!(
                name: issue_status["name"],
              )
              uses_existing = false
            end
            jira_status = JiraStatus.find_by!(jira_status_id: issue_status["id"], jira_id:)
            create_reference!(
              op_leg: status,
              jira_leg: jira_status,
              jira_import:,
              uses_existing:
            )

            ### PRIORITY
            issue_priority = jira_issue.payload["fields"]["priority"]
            priority = IssuePriority.where("LOWER(name) = LOWER(?)", issue_priority["name"]).first
            uses_existing = true
            if priority.blank?
              priority = IssuePriority.create!(
                name: issue_priority["name"],
              )
              uses_existing = false
            end
            jira_priority = JiraPriority.find_by!(jira_priority_id: issue_priority["id"], jira_id:)
            create_reference!(
              op_leg: priority,
              jira_leg: jira_priority,
              jira_import:,
              uses_existing:
            )

            ### WORK PACKAGE
            # required because otherwise project.types does not include type and then wp creation fails.
            project.reload
            service_call = WorkPackages::CreateService
              .new(user:)
              .call(
                project: project,
                subject: jira_issue.payload["fields"]["summary"],
                description: jira_issue.payload["fields"]["description"],
                type:,
                priority:,
                status:
              )
            if service_call.success?
              created_wps[project.id] << service_call.result
              create_reference!(
                op_leg: service_call.result,
                jira_leg: jira_issue,
                jira_import:,
                uses_existing: false
              )
            else
              binding.pry
              raise ActiveRecord::Rollback
            end
          end
        else
          raise ActiveRecord::Rollback
        end
      end
    end
  end

  private

  def create_reference!(op_leg:, jira_leg:, jira_import:, uses_existing:)
    OpenProjectJiraReference.insert_all(
      [
        op_entity_id: op_leg.id,
        op_entity_class: op_leg.class.to_s,
        jira_entity_id: jira_leg.id,
        jira_entity_class: jira_leg.class.to_s,
        jira_import_id: jira_import.id,
        jira_id: jira_import.jira.id,
        uses_existing:
      ],
      unique_by: %i[op_entity_id op_entity_class]
    )
  end
end
