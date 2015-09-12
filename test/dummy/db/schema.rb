# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_150_911_000_005) do
  create_table 'doors', force: :cascade do |t|
    t.string 'name'
    t.boolean 'active'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.integer 'house_id'
  end

  create_table 'houses', force: :cascade do |t|
    t.string 'name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'players', force: :cascade do |t|
    t.string 'name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'righter_rights', force: :cascade do |t|
    t.string 'name'
    t.string 'human_name'
    t.string 'controller'
    t.integer 'resource_id'
    t.string 'resource_class'
    t.text 'actions'
    t.integer 'parent_id'
    t.boolean 'hidden', default: false
    t.datetime 'created_at',                     null: false
    t.datetime 'updated_at',                     null: false
  end

  add_index 'righter_rights', ['parent_id'], name: 'index_ir_on_pid'

  create_table 'righter_rights_righter_roles', force: :cascade do |t|
    t.integer 'righter_role_id'
    t.integer 'righter_right_id'
  end

  add_index 'righter_rights_righter_roles', %w(righter_role_id righter_right_id), name: 'index_ir_on_iroi_irii'

  create_table 'righter_role_grants', force: :cascade do |t|
    t.integer 'righter_role_id'
    t.integer 'grantable_righter_role_id'
  end

  create_table 'righter_roles', force: :cascade do |t|
    t.string 'name'
    t.string 'human_name'
    t.boolean 'hidden', default: false
    t.datetime 'created_at',                 null: false
    t.datetime 'updated_at',                 null: false
  end

  create_table 'righter_roles_players', force: :cascade do |t|
    t.integer 'righter_role_id', null: false
    t.integer 'player_id',       null: false
  end

  create_table 'righter_roles_users', force: :cascade do |t|
    t.integer 'righter_role_id'
    t.integer 'user_id'
  end

  add_index 'righter_roles_users', %w(user_id righter_role_id), name: 'index_rr_on_ui_rroi'

  create_table 'users', force: :cascade do |t|
    t.string 'login'
    t.string 'email'
    t.string 'encrypted_password'
    t.string 'password_salt'
    t.datetime 'created_at',         null: false
    t.datetime 'updated_at',         null: false
  end
end
