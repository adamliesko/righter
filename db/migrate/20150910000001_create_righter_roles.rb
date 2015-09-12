class CreateRighterRoles < ActiveRecord::Migration
  def self.up
    create_table :righter_roles do |t|
      t.string :name
      t.string :human_name
      t.boolean :hidden, default: false
      t.timestamps null: false
    end

    create_table :righter_role_grants do |t|
      t.integer :righter_role_id
      t.integer :grantable_righter_role_id
    end
  end

  def self.down
    drop_table :righter_roles
    drop_table :righter_role_grants
  end
end
