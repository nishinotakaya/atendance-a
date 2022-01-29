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

ActiveRecord::Schema.define(version: 20200624124645) do

  create_table "attendances", force: :cascade do |t|
    t.date "worked_on"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "before_started_at"
    t.datetime "before_finished_at"
    t.datetime "edit_started_at"
    t.datetime "edit_finished_at"
    t.date "good_day"
    t.datetime "attended_time"
    t.string "note"
    t.datetime "plan_finished_at"
    t.datetime "over_time"
    t.boolean "tomorrow"
    t.string "business_processing_contents"
    t.boolean "change"
    t.string "instructor_confirmation"
    t.string "overtime_status"
    t.string "change_status"
    t.string "user_one_month_attendance_status"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "offices", force: :cascade do |t|
    t.string "office_number"
    t.string "office_name"
    t.string "office_modality"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.string "department"
    t.datetime "basic_time", default: "2022-01-21 23:00:00"
    t.datetime "work_time", default: "2022-01-21 22:30:00"
    t.boolean "admin"
    t.boolean "superior", default: false
    t.string "employee_number"
    t.string "uid"
    t.datetime "designated_work_start_time", default: "2022-01-21 22:00:00"
    t.datetime "designated_work_end_time", default: "2022-01-22 09:00:00"
    t.string "user_id"
    t.datetime "basic_work_time", default: "2022-01-21 21:30:00"
    t.string "affiliation"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
