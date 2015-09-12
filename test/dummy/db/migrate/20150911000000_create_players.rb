class CreatePlayers < ActiveRecord::Migration
  def self.up
    create_table :players, force: true do |t|
      t.string :name
      t.timestamps null: false
    end

    create_table :righter_roles_players do |t|
      t.integer :righter_role_id, null: false
      t.integer :player_id, null: false
    end
  end

  def self.down
    drop_table :righter_roles_players
    drop_table :players
  end
end
