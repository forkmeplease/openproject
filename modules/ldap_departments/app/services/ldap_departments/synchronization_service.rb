# frozen_string_literal: true

module LdapDepartments
  # Entry point for the department synchronization. For every configured tree it first mirrors the
  # organizational unit structure into departments and then assigns the users found below the base.
  class SynchronizationService
    def self.synchronize!
      User.system.run_given do
        new.call
      end
    end

    def call
      SynchronizedTree.includes(:ldap_auth_source).find_each do |tree|
        synchronize_tree(tree)
      end
    end

    private

    def synchronize_tree(tree)
      Rails.logger.info { "[LDAP departments] Synchronizing structure for tree '#{tree.name}'" }
      SynchronizeTreeService.new(tree).call

      Rails.logger.info { "[LDAP departments] Synchronizing members for tree '#{tree.name}'" }
      SynchronizeMembersService.new(tree).call
    rescue StandardError => e
      Rails.logger.error "[LDAP departments] Failed to synchronize tree '#{tree.name}': #{e.class}: #{e.message}"
    end
  end
end
