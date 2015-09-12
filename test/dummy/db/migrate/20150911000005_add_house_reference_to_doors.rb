class AddHouseReferenceToDoors < ActiveRecord::Migration
  def self.up
    add_column :doors, :house_id, :integer
  end

  def self.down
    remove_column :doors, :house_id
  end
end
