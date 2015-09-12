class RighterRolesRighterAccessRights < ActiveRecord::Migration
  def self.up
    create_table :righter_rights_righter_roles do |t|
      t.integer :righter_role_id
      t.integer :righter_right_id
    end

    add_index :righter_rights_righter_roles, [:righter_role_id, :righter_right_id], name: 'index_ir_on_iroi_irii'
  end

  def self.down
    drop_table :righter_rights_righter_roles
  end
end
