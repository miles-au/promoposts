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

ActiveRecord::Schema.define(version: 2019_09_17_000549) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "provider"
    t.string "account_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "access_token"
    t.string "uid"
    t.boolean "autoshare"
    t.string "name"
    t.string "picture"
    t.datetime "last_share_time"
    t.string "platform"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "name"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "content"
    t.index ["created_at"], name: "index_campaigns_on_created_at"
    t.index ["user_id"], name: "index_campaigns_on_user_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "subject"
    t.string "message"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "microposts", force: :cascade do |t|
    t.text "content"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "picture"
    t.string "category"
    t.string "source"
    t.boolean "shareable", default: false
    t.integer "top_comment"
    t.string "external_url"
    t.integer "shares"
    t.integer "downloads"
    t.integer "campaign_id"
    t.index ["user_id", "created_at"], name: "index_microposts_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_microposts_on_user_id"
  end

  create_table "oauth_accounts", force: :cascade do |t|
    t.integer "user_id"
    t.string "provider"
    t.string "uid"
    t.string "image_url"
    t.string "profile_url"
    t.string "access_token"
    t.text "raw_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_oauth_accounts_on_user_id"
  end

  create_table "overlays", force: :cascade do |t|
    t.integer "user_id"
    t.string "picture"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "permissions"
  end

  create_table "relationships", force: :cascade do |t|
    t.integer "follower_id"
    t.integer "followed_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_relationships_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_relationships_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_relationships_on_follower_id"
  end

  create_table "scheduled_posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "account_id"
    t.string "picture_url"
    t.string "caption"
    t.integer "micropost_id"
    t.string "status", default: "waiting"
    t.integer "topic_id"
    t.string "platform"
    t.datetime "post_time"
    t.integer "clicks", default: 0
  end

  create_table "settings", force: :cascade do |t|
    t.boolean "email_for_replies", default: true
    t.string "user_id"
    t.boolean "email_when_followed", default: true
    t.boolean "email_when_new_question", default: false
    t.integer "default_overlay_id"
    t.string "default_overlay_location"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "topic_relationships", force: :cascade do |t|
    t.integer "user_id"
    t.integer "topic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_topic_relationships_on_topic_id"
    t.index ["user_id"], name: "index_topic_relationships_on_user_id"
  end

  create_table "topics", force: :cascade do |t|
    t.string "name"
    t.string "picture"
  end

  create_table "tracks", force: :cascade do |t|
    t.integer "user_id"
    t.string "category"
    t.integer "asset_num"
    t.string "act"
    t.datetime "created_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.datetime "activated_at"
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.string "picture"
    t.string "fb_uid"
    t.string "linkedin_uid"
    t.string "fb_oauth_token"
    t.string "linkedin_oauth_token"
    t.string "instagram_oauth_token"
    t.string "instagram_uid"
    t.string "buffer_oauth_token"
    t.string "buffer_uid"
    t.string "cover_photo"
    t.boolean "verify_email", default: false
    t.string "slug"
    t.string "company"
    t.string "twitter_oauth_token"
    t.string "twitter_uid"
    t.string "pinterest_oauth_token"
    t.string "pinterest_uid"
    t.string "timezone"
    t.integer "onboarding_stage", default: 0
    t.string "website"
    t.string "color", default: "#ffffff"
    t.string "email_ciphertext"
    t.string "email_bidx"
    t.index ["email_bidx"], name: "index_users_on_email_bidx", unique: true
  end

end
