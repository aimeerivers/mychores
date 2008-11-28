# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20081123160330) do

  create_table "bulletins", :force => true do |t|
    t.text      "message",    :null => false
    t.string    "link"
    t.timestamp "created_on", :null => false
    t.timestamp "updated_on", :null => false
  end

  create_table "completions", :force => true do |t|
    t.integer   "person_id",      :default => 0, :null => false
    t.integer   "task_id",        :default => 0, :null => false
    t.integer   "source",         :default => 0, :null => false
    t.date      "date_completed",                :null => false
    t.timestamp "created_on",                    :null => false
  end

  add_index "completions", ["person_id"], :name => "people_tasks_FKIndex1"
  add_index "completions", ["task_id"], :name => "people_tasks_FKIndex2"

  create_table "emails", :force => true do |t|
    t.string    "to",         :default => "",    :null => false
    t.string    "cc"
    t.string    "bcc"
    t.string    "subject",    :default => "",    :null => false
    t.text      "message",                       :null => false
    t.boolean   "sent",       :default => false, :null => false
    t.timestamp "created_on",                    :null => false
    t.timestamp "updated_on",                    :null => false
  end

  create_table "globalize_countries", :force => true do |t|
    t.string "code",                   :limit => 2
    t.string "english_name"
    t.string "date_format"
    t.string "currency_format"
    t.string "currency_code",          :limit => 3
    t.string "thousands_sep",          :limit => 2
    t.string "decimal_sep",            :limit => 2
    t.string "currency_decimal_sep",   :limit => 2
    t.string "number_grouping_scheme"
  end

  add_index "globalize_countries", ["code"], :name => "index_globalize_countries_on_code"

  create_table "globalize_languages", :force => true do |t|
    t.string  "iso_639_1",             :limit => 2
    t.string  "iso_639_2",             :limit => 3
    t.string  "iso_639_3",             :limit => 3
    t.string  "rfc_3066"
    t.string  "english_name"
    t.string  "english_name_locale"
    t.string  "english_name_modifier"
    t.string  "native_name"
    t.string  "native_name_locale"
    t.string  "native_name_modifier"
    t.boolean "macro_language"
    t.string  "direction"
    t.string  "pluralization"
    t.string  "scope",                 :limit => 1
  end

  add_index "globalize_languages", ["iso_639_1"], :name => "index_globalize_languages_on_iso_639_1"
  add_index "globalize_languages", ["iso_639_2"], :name => "index_globalize_languages_on_iso_639_2"
  add_index "globalize_languages", ["iso_639_3"], :name => "index_globalize_languages_on_iso_639_3"
  add_index "globalize_languages", ["rfc_3066"], :name => "index_globalize_languages_on_rfc_3066"

  create_table "globalize_translations", :force => true do |t|
    t.string  "type"
    t.string  "tr_key"
    t.string  "table_name"
    t.integer "item_id"
    t.string  "facet"
    t.boolean "built_in",            :default => true
    t.integer "language_id"
    t.integer "pluralization_index"
    t.text    "text"
    t.integer "tr_version",          :default => 0,    :null => false
    t.integer "person_id"
    t.string  "namespace"
  end

  add_index "globalize_translations", ["tr_key", "language_id"], :name => "index_globalize_translations_on_tr_key_and_language_id"
  add_index "globalize_translations", ["table_name", "item_id", "language_id"], :name => "globalize_translations_table_name_and_item_and_language"

  create_table "importances", :force => true do |t|
    t.integer "value",               :default => 0,  :null => false
    t.string  "name",  :limit => 20, :default => "", :null => false
  end

  create_table "invitations", :force => true do |t|
    t.integer   "person_id"
    t.integer   "team_id",                  :default => 0,     :null => false
    t.string    "email",                    :default => "",    :null => false
    t.string    "code",       :limit => 40
    t.boolean   "accepted",                 :default => false
    t.timestamp "created_on",                                  :null => false
    t.timestamp "updated_on",                                  :null => false
  end

  add_index "invitations", ["person_id"], :name => "invitations_FKIndex1"
  add_index "invitations", ["team_id"], :name => "invitations_FKIndex2"

  create_table "lists", :force => true do |t|
    t.string    "name",        :limit => 25
    t.text      "description"
    t.integer   "team_id",                   :default => 0,     :null => false
    t.boolean   "quickcreate",               :default => false, :null => false
    t.timestamp "created_on",                                   :null => false
    t.timestamp "updated_on",                                   :null => false
  end

  add_index "lists", ["team_id"], :name => "lists_FKIndex1"

  create_table "memberships", :force => true do |t|
    t.integer "person_id",                  :default => 0, :null => false
    t.integer "team_id",                    :default => 0, :null => false
    t.integer "requested"
    t.integer "invited"
    t.integer "confirmed"
    t.string  "validity_key", :limit => 40
  end

  add_index "memberships", ["person_id"], :name => "people_teams_FKIndex1"
  add_index "memberships", ["team_id"], :name => "people_teams_FKIndex2"

  create_table "messages", :force => true do |t|
    t.text      "content"
    t.integer   "person_id"
    t.string    "email"
    t.string    "name",       :limit => 40
    t.string    "cat",        :limit => 25
    t.timestamp "created_on",               :null => false
  end

  add_index "messages", ["person_id"], :name => "teams_FKIndex1"

  create_table "newsletters", :force => true do |t|
    t.string    "title",      :limit => 50, :default => "", :null => false
    t.text      "content",                                  :null => false
    t.text      "details"
    t.timestamp "created_on",                               :null => false
  end

  create_table "people", :force => true do |t|
    t.string    "login",          :limit => 40
    t.string    "password",       :limit => 40
    t.string    "code",           :limit => 40
    t.string    "email"
    t.string    "email_code",     :limit => 40
    t.boolean   "email_verified",                :default => false,                 :null => false
    t.string    "timezone_name",  :limit => 50,  :default => "London",              :null => false
    t.time      "midnight_gmt",                  :default => '2000-01-01 00:00:00', :null => false
    t.string    "name",           :limit => 40
    t.string    "notifications",  :limit => 10,  :default => "Daily",               :null => false
    t.boolean   "newsletters",                   :default => true,                  :null => false
    t.string    "status",         :limit => 100
    t.boolean   "ads",                           :default => true,                  :null => false
    t.string    "default_view",   :limit => 10,  :default => "Workload",            :null => false
    t.integer   "parent_id",                     :default => 0,                     :null => false
    t.text      "openid_url"
    t.integer   "usertype",                      :default => 1,                     :null => false
    t.timestamp "created_on",                                                       :null => false
    t.timestamp "updated_on",                                                       :null => false
  end

  create_table "pictures", :force => true do |t|
    t.string    "content_type"
    t.string    "filename"
    t.integer   "size"
    t.integer   "parent_id"
    t.string    "thumbnail"
    t.integer   "width"
    t.integer   "height"
    t.integer   "person_id"
    t.integer   "db_file_id"
    t.boolean   "is_public",        :default => false
    t.boolean   "is_flickr_import", :default => false, :null => false
    t.string    "flickr_url"
    t.timestamp "created_on",                          :null => false
  end

  add_index "pictures", ["person_id"], :name => "pictures_FKIndex1"

  create_table "preferences", :force => true do |t|
    t.integer   "person_id"
    t.string    "workload_display",             :limit => 20,  :default => "All tasks"
    t.string    "workload_order_by",            :limit => 20,  :default => "Due date",                                      :null => false
    t.string    "workload_page_size",           :limit => 2,   :default => "20"
    t.integer   "workload_refresh",             :limit => 2,   :default => 0,                                               :null => false
    t.string    "mobile_page_size",             :limit => 2,   :default => "10",                                            :null => false
    t.string    "workload_columns",                            :default => "Listonly, Taskonly, Duedate, Importance_stars"
    t.string    "quick_edit_options",                          :default => "importance"
    t.string    "theme",                        :limit => 20,  :default => "pastels"
    t.boolean   "html_emails",                                 :default => true,                                            :null => false
    t.boolean   "colourful_emails",                            :default => true,                                            :null => false
    t.string    "email_time",                   :limit => 5,   :default => "08:00",                                         :null => false
    t.time      "email_time_gmt",                              :default => '2000-01-01 08:00:00',                           :null => false
    t.boolean   "include_descriptions",                        :default => false,                                           :null => false
    t.string    "twitter_email"
    t.string    "twitter_password",             :limit => 40
    t.boolean   "twitter_receive",                             :default => false,                                           :null => false
    t.string    "twitter_receive_time",         :limit => 5,   :default => "08:00",                                         :null => false
    t.time      "twitter_receive_time_gmt",                    :default => '2000-01-01 08:00:00',                           :null => false
    t.boolean   "twitter_post",                                :default => false,                                           :null => false
    t.string    "twitter_update_string",                       :default => "Doing my chores: {LIST}: {TASK}"
    t.string    "twitter_lists"
    t.string    "flickr_email"
    t.string    "flickr_tag",                   :limit => 25
    t.boolean   "no_js",                                       :default => false,                                           :null => false
    t.boolean   "enable_js",                                   :default => true,                                            :null => false
    t.string    "my_date_format",               :limit => 10,  :default => "%d/%m/%Y",                                      :null => false
    t.string    "language_code",                :limit => 10,  :default => "en",                                            :null => false
    t.boolean   "template_one_off",                            :default => false,                                           :null => false
    t.integer   "template_recurrence_interval",                :default => 3
    t.string    "template_recurrence_measure",  :limit => 6,   :default => "days"
    t.string    "template_recurrence_occur_on", :limit => 50,  :default => "0,1,2,3,4,5,6",                                 :null => false
    t.integer   "template_importance",                         :default => 4,                                               :null => false
    t.string    "template_task_missed_options", :limit => 100, :default => "increase_importance"
    t.timestamp "created_on",                                                                                               :null => false
    t.timestamp "updated_on",                                                                                               :null => false
  end

  add_index "preferences", ["person_id"], :name => "preferences_FKIndex1"

  create_table "questions", :force => true do |t|
    t.string  "question",     :default => "", :null => false
    t.text    "answer"
    t.integer "displayorder", :default => 0,  :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.string   "key"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "tasks", :force => true do |t|
    t.string    "name"
    t.text      "description"
    t.integer   "list_id",                               :default => 0,                     :null => false
    t.integer   "person_id"
    t.string    "status",                 :limit => 15,  :default => "active",              :null => false
    t.boolean   "rotate",                                :default => false,                 :null => false
    t.boolean   "one_off",                               :default => false,                 :null => false
    t.integer   "recurrence_interval",                   :default => 3
    t.string    "recurrence_measure",     :limit => 6,   :default => "days"
    t.boolean   "any_day",                               :default => false,                 :null => false
    t.boolean   "any_date",                              :default => false,                 :null => false
    t.string    "recurrence_weekday",     :limit => 10,  :default => "Monday"
    t.string    "recurrence_occur_on",    :limit => 50,  :default => "0,1,2,3,4,5,6",       :null => false
    t.string    "recurrence_specific",    :limit => 4,   :default => "1st"
    t.string    "recurrence_description", :limit => 50
    t.date      "next_due"
    t.date      "escalation_date"
    t.integer   "default_importance",                    :default => 4,                     :null => false
    t.integer   "current_importance",                    :default => 4,                     :null => false
    t.string    "task_missed_options",    :limit => 100, :default => "increase_importance"
    t.boolean   "quickcreate",                           :default => false,                 :null => false
    t.integer   "picture_id"
    t.timestamp "created_on",                                                               :null => false
    t.timestamp "updated_on",                                                               :null => false
  end

  add_index "tasks", ["list_id"], :name => "tasks_FKIndex1"
  add_index "tasks", ["person_id"], :name => "tasks_FKIndex2"
  add_index "tasks", ["picture_id"], :name => "tasks_FKIndex3"

  create_table "teams", :force => true do |t|
    t.string    "name",        :limit => 25
    t.text      "description"
    t.integer   "person_id"
    t.string    "code",        :limit => 40
    t.boolean   "use_colour",                :default => false,    :null => false
    t.string    "colour",      :limit => 6,  :default => "99DDEE", :null => false
    t.string    "text_colour", :limit => 6,  :default => "444444", :null => false
    t.timestamp "created_on",                                      :null => false
    t.timestamp "updated_on",                                      :null => false
  end

  add_index "teams", ["person_id"], :name => "teams_FKIndex1"

  create_table "testimonials", :force => true do |t|
    t.text      "message",                                        :null => false
    t.text      "short_message"
    t.string    "name",          :limit => 50
    t.string    "link"
    t.string    "login_id",      :limit => 40
    t.boolean   "approved",                    :default => false, :null => false
    t.timestamp "created_on",                                     :null => false
    t.timestamp "updated_on",                                     :null => false
  end

  create_table "tips", :force => true do |t|
    t.integer   "person_id"
    t.string    "short_description"
    t.text      "full_description"
    t.string    "source"
    t.string    "tag_edit"
    t.string    "cached_tag_list"
    t.boolean   "is_anon",           :default => false, :null => false
    t.integer   "effectiveness",     :default => 0,     :null => false
    t.timestamp "created_on",                           :null => false
    t.timestamp "updated_on",                           :null => false
  end

  add_index "tips", ["person_id"], :name => "tips_FKIndex1"

end
