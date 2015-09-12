class CreateDoors < ActiveRecord::Migration
  def self.up
    create_table :doors do |t|
      t.string :name
      t.boolean :active

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :doors
  end
end
