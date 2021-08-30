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

ActiveRecord::Schema.define(version: 20161005062015) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.string   "type",            limit: 255
    t.text     "as_text"
    t.datetime "deleted_at"
    t.integer  "actionable_id"
    t.string   "actionable_type", limit: 255
    t.text     "data"
  end

  create_table "channel_groups", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.text     "description"
    t.integer  "user_id"
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.string   "tparty_keyword",     limit: 255
    t.string   "keyword",            limit: 255
    t.integer  "default_channel_id"
    t.text     "moderator_emails"
    t.boolean  "real_time_update"
    t.datetime "deleted_at"
    t.boolean  "web_signup",                     default: false
    t.index ["user_id"], name: "index_channel_groups_on_user_id", using: :btree
  end

  create_table "channels", force: :cascade do |t|
    t.string   "name",                     limit: 255
    t.text     "description"
    t.integer  "user_id"
    t.string   "type",                     limit: 255
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.string   "keyword",                  limit: 255
    t.string   "tparty_keyword",           limit: 255
    t.datetime "next_send_time"
    t.text     "schedule"
    t.integer  "channel_group_id"
    t.string   "one_word",                 limit: 255
    t.string   "suffix",                   limit: 255
    t.text     "moderator_emails"
    t.boolean  "real_time_update"
    t.datetime "deleted_at"
    t.boolean  "relative_schedule"
    t.boolean  "send_only_once",                       default: false
    t.boolean  "active",                               default: true
    t.boolean  "allow_mo_subscription",                default: true
    t.datetime "mo_subscription_deadline"
    t.index ["user_id"], name: "index_channels_on_user_id", using: :btree
  end

  create_table "message_options", force: :cascade do |t|
    t.integer  "message_id"
    t.string   "key",        limit: 255
    t.string   "value",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "messages", force: :cascade do |t|
    t.text     "title"
    t.text     "caption"
    t.string   "type",                         limit: 255
    t.integer  "channel_id"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "content_file_name",            limit: 255
    t.string   "content_content_type",         limit: 255
    t.integer  "content_file_size"
    t.datetime "content_updated_at"
    t.integer  "seq_no"
    t.datetime "next_send_time"
    t.boolean  "primary"
    t.text     "reminder_message_text"
    t.integer  "reminder_delay"
    t.text     "repeat_reminder_message_text"
    t.integer  "repeat_reminder_delay"
    t.integer  "number_of_repeat_reminders"
    t.text     "options"
    t.datetime "deleted_at"
    t.text     "schedule"
    t.boolean  "active"
    t.boolean  "requires_response"
    t.text     "recurring_schedule"
    t.index ["channel_id"], name: "index_messages_on_channel_id", using: :btree
  end

  create_table "rails_admin_histories", force: :cascade do |t|
    t.text     "message"
    t.string   "username",   limit: 255
    t.integer  "item"
    t.string   "table",      limit: 255
    t.integer  "month",      limit: 2
    t.bigint   "year"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["item", "table", "month", "year"], name: "index_rails_admin_histories", using: :btree
  end

  create_table "response_actions", force: :cascade do |t|
    t.string   "response_text", limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "message_id"
    t.datetime "deleted_at"
  end

  create_table "subscriber_activities", force: :cascade do |t|
    t.integer  "subscriber_id"
    t.integer  "channel_id"
    t.integer  "message_id"
    t.string   "type",              limit: 255
    t.string   "origin",            limit: 255
    t.text     "title"
    t.text     "caption"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "channel_group_id"
    t.boolean  "processed"
    t.datetime "deleted_at"
    t.string   "tparty_identifier", limit: 255
    t.text     "options"
    t.index ["channel_id"], name: "index_subscriber_activities_on_channel_id", using: :btree
    t.index ["message_id"], name: "index_subscriber_activities_on_message_id", using: :btree
    t.index ["subscriber_id"], name: "index_subscriber_activities_on_subscriber_id", using: :btree
  end

  create_table "subscribers", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.string   "phone_number",          limit: 255
    t.text     "remarks"
    t.integer  "last_msg_seq_no"
    t.integer  "user_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "email",                 limit: 255
    t.datetime "deleted_at"
    t.text     "additional_attributes"
    t.text     "data"
    t.index ["user_id"], name: "index_subscribers_on_user_id", using: :btree
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "channel_id"
    t.integer  "subscriber_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.datetime "deleted_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "admin",                              default: false
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

end
