class CreateRighterRights < ActiveRecord::Migration
  def self.up
    create_table :righter_rights do |t|
      t.string :name
      t.string :human_name
      t.string :controller
      t.integer :resource_id
      t.string :resource_class
      t.text :actions
      t.integer :parent_id
      t.boolean :hidden, default: false
      t.timestamps null: false
    end

    add_index :righter_rights, :parent_id, name: 'index_rr_on_pid'
  end

  def self.down
    drop_table :righter_rights
  end
end
