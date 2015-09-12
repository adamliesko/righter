class CreateUsersTable < ActiveRecord::Migration
  def self.up
    create_table 'users', force: true do |t|
      t.string 'login'
      t.string 'email'
      t.string 'encrypted_password'
      t.string 'password_salt'
      t.timestamps null: false
    end
  end

  def self.down
    drop_table 'users'
  end
end
