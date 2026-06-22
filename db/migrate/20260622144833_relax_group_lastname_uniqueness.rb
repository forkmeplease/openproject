# frozen_string_literal: true

class RelaxGroupLastnameUniqueness < ActiveRecord::Migration[8.1]
  # Group name uniqueness is now enforced in the application (Group#uniqueness_of_name):
  # globally for regular groups, but only among siblings for organizational units (departments),
  # since LDAP directories repeat the same OU name across branches. The database-level unique
  # index can therefore no longer span all groups, so we restrict it to placeholder users.
  def up
    remove_index :users, name: "unique_lastname_for_groups_and_placeholder_users"
    add_index :users,
              %i[lastname type],
              name: "unique_lastname_for_placeholder_users",
              unique: true,
              where: "(type = 'PlaceholderUser')"
  end

  def down
    remove_index :users, name: "unique_lastname_for_placeholder_users"
    add_index :users,
              %i[lastname type],
              name: "unique_lastname_for_groups_and_placeholder_users",
              unique: true,
              where: "(type = 'Group' OR type = 'PlaceholderUser')"
  end
end
