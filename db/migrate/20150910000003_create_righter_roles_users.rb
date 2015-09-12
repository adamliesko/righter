class CreateRighterRolesUsers < ActiveRecord::Migration
  def self.up
    create_table :righter_roles_users do |t|
      t.integer :righter_role_id
      t.integer :user_id
    end

    add_index :righter_roles_users, [:user_id, :righter_role_id], name: 'index_rr_on_ui_rroi'
  end

  def self.down
    drop_table :righter_roles_users
  end
end
