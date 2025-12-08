class JiraImportDataJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  good_job_control_concurrency_with(
    total_limit: 2,
    enqueue_limit: 1,
    perform_limit: 1,
    key: -> { "JiraImportJob-#{arguments.last}" }
  )

  def perform(jira_id)
    ActiveRecord::Base.transaction do
      jira = Jira.find(jira_id)
      # IMPORT USERS GROUPS MEMBERSHIPS

      jira_users = JiraUser.where(jira_id: jira.id)
      # group_name => member_ids
      groups = {}
      jira_users.each do |jira_user|
        call = Users::CreateService
                 .new(user: User.system)
                 .call(jira_user.to_op_attributes)
        ref = nil
        call.on_success do |result|
          user_id = call.result.id
          ref = OpenProjectJiraReference.create!(
            op_entity_id: user_id,
            op_entity_table: "User",
            jira_id: jira.id,
            jira_entity_id: jira_user.id,
            jira_entity_table: "JiraUser",
            created: true
          )
          jira_user
            .payload["groups"]["items"]
            .each do |item|
            group = item["name"]
            groups[group] = Set.new unless groups.key?(group)
            groups[group] << user_id
          end

        end
        call.on_failure do |result|
          binding.pry
        end
      end
      groups.each do |name, member_ids|
        call = Groups::CreateService
                 .new(user: User.system)
                 .call(name:)
        call.on_success do |result|
          group = result.result
          ref = OpenProjectJiraReference.create!(
            op_entity_id: group.id,
            op_entity_table: "Group",
            jira_id: jira.id,
            jira_entity_id: nil,
            jira_entity_table: nil,
            created: true
          )

          if member_ids.present?
            add_users_call = Groups::AddUsersService
                               .new(group, current_user: User.system)
                               .call(ids: member_ids, send_notifications: false)
          end
        end
        call.on_failure do |result|
          binding.pry
        end
      end

      # IMPORT STATUSES

      JiraStatus.all.each do |jira_status|
        status = Status.create!(name: "J-#{jira_status.payload['name']}")
        ref = OpenProjectJiraReference.create!(
          op_entity_id: status.id,
          op_entity_table: "Status",
          jira_id: jira.id,
          jira_entity_id: jira_status.id,
          jira_entity_table: "JiraStatus",
        )
      end

      # create status

      # create reference

      # cleanup

      binding.pry
      raise ActiveRecord::Rollback

      # OpenProjectJiraReference.all.map(&:model).each do |model|
      #   delete_service = "#{model.class.to_s.pluralize}::DeleteService".constantize
      #   delete_service
      #     .new(user: User.system, model:)
      #     .call
      # end
      # OpenProjectJiraReference.destroy_all
    end
  end
end
