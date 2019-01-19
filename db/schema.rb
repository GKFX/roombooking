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

ActiveRecord::Schema.define(version: 12) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "bookings", force: :cascade do |t|
    t.string "name", null: false
    t.text "notes"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.date "repeat_until"
    t.integer "repeat_mode", default: 0, null: false
    t.integer "purpose", null: false
    t.boolean "approved", default: false, null: false
    t.bigint "room_id", null: false
    t.bigint "user_id", null: false
    t.string "camdram_model_type"
    t.bigint "camdram_model_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved"], name: "index_bookings_on_approved", where: "(approved = false)"
    t.index ["camdram_model_type", "camdram_model_id"], name: "index_bookings_on_camdram_model_type_and_camdram_model_id"
    t.index ["created_at"], name: "index_bookings_on_created_at", order: :desc
    t.index ["end_time"], name: "index_bookings_on_end_time"
    t.index ["repeat_mode"], name: "index_bookings_on_repeat_mode", where: "(repeat_mode <> 0)"
    t.index ["repeat_until"], name: "index_bookings_on_repeat_until"
    t.index ["room_id"], name: "index_bookings_on_room_id"
    t.index ["start_time"], name: "index_bookings_on_start_time"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "camdram_shows", force: :cascade do |t|
    t.bigint "camdram_id", null: false
    t.integer "max_rehearsals", default: 0, null: false
    t.integer "max_auditions", default: 0, null: false
    t.integer "max_meetings", default: 0, null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_camdram_shows_on_active", where: "(active = true)"
    t.index ["camdram_id"], name: "index_camdram_shows_on_camdram_id", unique: true
  end

  create_table "camdram_societies", force: :cascade do |t|
    t.bigint "camdram_id", null: false
    t.integer "max_meetings", default: 0, null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_camdram_societies_on_active", where: "(active = true)"
    t.index ["camdram_id"], name: "index_camdram_societies_on_camdram_id", unique: true
  end

  create_table "camdram_tokens", force: :cascade do |t|
    t.string "access_token", null: false
    t.string "refresh_token", null: false
    t.datetime "expires_at", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_camdram_tokens_on_access_token", unique: true
    t.index ["created_at"], name: "index_camdram_tokens_on_created_at", order: :desc
    t.index ["refresh_token"], name: "index_camdram_tokens_on_refresh_token", unique: true
    t.index ["user_id"], name: "index_camdram_tokens_on_user_id"
  end

  create_table "log_events", force: :cascade do |t|
    t.string "logable_type"
    t.bigint "logable_id"
    t.integer "outcome"
    t.string "action"
    t.integer "interface"
    t.inet "ip"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interface"], name: "index_log_events_on_interface"
    t.index ["ip"], name: "index_log_events_on_ip"
    t.index ["logable_type", "logable_id"], name: "index_log_events_on_logable_type_and_logable_id"
  end

  create_table "provider_accounts", force: :cascade do |t|
    t.string "provider", null: false
    t.string "uid", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_provider_accounts_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_provider_accounts_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "invalidated", default: false, null: false
    t.datetime "expires_at", null: false
    t.datetime "login_at", null: false
    t.inet "ip", null: false
    t.string "user_agent", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.boolean "admin", default: false, null: false
    t.boolean "sysadmin", default: false, null: false
    t.boolean "blocked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin"], name: "index_users_on_admin", where: "(admin = true)"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string "foreign_key_name", null: false
    t.integer "foreign_key_id"
    t.string "foreign_type"
    t.integer "transaction_id"
    t.index ["foreign_key_name", "foreign_key_id", "foreign_type"], name: "index_version_associations_on_foreign_key"
    t.index ["version_id"], name: "index_version_associations_on_version_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.string "item_subtype"
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.integer "transaction_id"
    t.inet "ip"
    t.string "user_agent"
    t.bigint "session"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["transaction_id"], name: "index_versions_on_transaction_id"
  end

  add_foreign_key "bookings", "rooms"
  add_foreign_key "bookings", "users"
  add_foreign_key "camdram_tokens", "users"
  add_foreign_key "provider_accounts", "users"
  add_foreign_key "sessions", "users"
end
