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

ActiveRecord::Schema.define(:version => 20121001143439) do

  create_table "ad_accounts", :force => true do |t|
    t.integer "user_id",      :null => false
    t.string  "publisher_id", :null => false
    t.string  "channel_id"
  end

  create_table "adsense_accounts", :force => true do |t|
    t.integer  "user_id",            :null => false
    t.string   "client_id",          :null => false
    t.text     "code_300x250"
    t.string   "email_address"
    t.string   "postal_code"
    t.string   "phone_hint"
    t.string   "account_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "approval_status"
    t.string   "association_status"
    t.text     "code_728x90"
  end

  add_index "adsense_accounts", ["user_id"], :name => "index_adsense_accounts_on_user_id"

  create_table "advergame_scores", :force => true do |t|
    t.integer  "response_id",                :null => false
    t.integer  "contest_id"
    t.integer  "score",       :default => 0
    t.datetime "created_on",                 :null => false
  end

  add_index "advergame_scores", ["response_id"], :name => "index_advergame_scores_on_response_id"

  create_table "answers", :force => true do |t|
    t.integer  "response_id",                           :null => false
    t.integer  "question_id",                           :null => false
    t.integer  "question_option_id"
    t.integer  "points",             :default => 0,     :null => false
    t.datetime "created_on",                            :null => false
    t.boolean  "correct",            :default => false, :null => false
    t.integer  "entry_id"
    t.integer  "loyalty_points"
    t.integer  "rating"
    t.integer  "user_id"
  end

  add_index "answers", ["created_on"], :name => "index_answers_on_created_on"
  add_index "answers", ["question_id"], :name => "index_answers_on_question_id"
  add_index "answers", ["question_option_id"], :name => "index_answers_on_question_option_id"
  add_index "answers", ["response_id", "question_id"], :name => "index_answers_on_response_id_and_question_id", :unique => true
  add_index "answers", ["response_id"], :name => "index_answers_on_response_id"

  create_table "audit_logs", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "user_id"
    t.string   "activity"
    t.datetime "created_on"
    t.integer  "region_id"
  end

  add_index "audit_logs", ["auditable_id"], :name => "index_audit_logs_on_auditable_id"
  add_index "audit_logs", ["created_on"], :name => "index_audit_logs_on_created_on"
  add_index "audit_logs", ["user_id"], :name => "index_audit_logs_on_user_id"

  create_table "banners", :force => true do |t|
    t.string   "location",   :null => false
    t.text     "code",       :null => false
    t.datetime "created_on", :null => false
    t.datetime "updated_on", :null => false
    t.integer  "region_id"
  end

  create_table "bets", :force => true do |t|
    t.integer  "wager",       :null => false
    t.integer  "response_id", :null => false
    t.integer  "user_id",     :null => false
    t.integer  "option_id",   :null => false
    t.datetime "created_on",  :null => false
  end

  add_index "bets", ["option_id"], :name => "index_bets_on_option_id"
  add_index "bets", ["response_id"], :name => "index_bets_on_response_id"

  create_table "bids", :force => true do |t|
    t.integer  "user_id",                         :null => false
    t.integer  "toppled_by_id"
    t.float    "value",                           :null => false
    t.datetime "created_on",                      :null => false
    t.datetime "updated_on",                      :null => false
    t.boolean  "winner"
    t.integer  "contest_prize_id"
    t.integer  "total_bids",       :default => 1, :null => false
  end

  add_index "bids", ["contest_prize_id", "toppled_by_id"], :name => "index_bids_on_contest_prize_id_and_toppled_by_id"
  add_index "bids", ["contest_prize_id", "user_id", "value"], :name => "index_bids_on_contest_prize_id_and_user_id_and_value"
  add_index "bids", ["contest_prize_id", "value"], :name => "index_bids_on_contest_prize_id_and_value", :unique => true

  create_table "brands", :force => true do |t|
    t.string   "name",       :limit => 100,                    :null => false
    t.string   "logo",                                         :null => false
    t.boolean  "expired",                   :default => false, :null => false
    t.datetime "created_on",                                   :null => false
    t.datetime "updated_on",                                   :null => false
    t.boolean  "logo_in_s3",                :default => false, :null => false
    t.string   "url"
  end

  add_index "brands", ["name"], :name => "index_brands_on_name", :unique => true

  create_table "campaign_contest_types", :force => true do |t|
    t.integer "contest_id",   :null => false
    t.string  "contest_type", :null => false
    t.integer "skin_id",      :null => false
  end

  add_index "campaign_contest_types", ["contest_id", "contest_type"], :name => "index_campaign_contest_types_on_contest_id_and_contest_type", :unique => true
  add_index "campaign_contest_types", ["contest_id"], :name => "index_campaign_contest_types_on_contest_id"
  add_index "campaign_contest_types", ["skin_id"], :name => "index_campaign_contest_types_on_skin_id"

  create_table "categories", :force => true do |t|
    t.string   "name",        :limit => 30, :null => false
    t.string   "slug",        :limit => 30, :null => false
    t.string   "description",               :null => false
    t.datetime "created_on",                :null => false
    t.datetime "updated_on",                :null => false
  end

  add_index "categories", ["name"], :name => "index_categories_on_name", :unique => true
  add_index "categories", ["slug"], :name => "index_categories_on_slug", :unique => true

  create_table "categories_contests", :id => false, :force => true do |t|
    t.integer "category_id", :null => false
    t.integer "contest_id",  :null => false
  end

  add_index "categories_contests", ["category_id", "contest_id"], :name => "index_categories_contests_on_category_id_and_contest_id", :unique => true
  add_index "categories_contests", ["contest_id"], :name => "index_categories_contests_on_contest_id"

  create_table "categories_regions", :id => false, :force => true do |t|
    t.integer "category_id", :null => false
    t.integer "region_id",   :null => false
  end

  add_index "categories_regions", ["category_id", "region_id"], :name => "index_categories_regions_on_category_id_and_region_id", :unique => true
  add_index "categories_regions", ["region_id"], :name => "index_categories_regions_on_region_id"

  create_table "classifications", :force => true do |t|
    t.integer "minimum_score", :null => false
    t.integer "maximum_score", :null => false
    t.text    "description",   :null => false
    t.integer "contest_id",    :null => false
  end

  add_index "classifications", ["contest_id"], :name => "index_classifications_on_contest_id"

  create_table "comments", :force => true do |t|
    t.text     "message",                           :null => false
    t.integer  "commentable_id",                    :null => false
    t.integer  "user_id",                           :null => false
    t.datetime "created_on",                        :null => false
    t.integer  "status"
    t.boolean  "sticky",         :default => false, :null => false
    t.string   "username"
  end

  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["status"], :name => "index_comments_on_status"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "contest_prizes", :force => true do |t|
    t.integer  "prize_id",                     :null => false
    t.integer  "contest_id",                   :null => false
    t.integer  "quantity",      :default => 1, :null => false
    t.datetime "created_on",                   :null => false
    t.integer  "created_by_id",                :null => false
    t.date     "from_date",                    :null => false
    t.date     "to_date",                      :null => false
    t.integer  "status",        :default => 0, :null => false
    t.integer  "region_id"
    t.string   "description"
  end

  add_index "contest_prizes", ["contest_id"], :name => "index_contest_prizes_on_contest_id"
  add_index "contest_prizes", ["prize_id"], :name => "index_contest_prizes_on_prize_id"
  add_index "contest_prizes", ["region_id"], :name => "index_contest_prizes_on_region_id"

  create_table "contest_recommendations", :force => true do |t|
    t.string   "from_email_address",               :null => false
    t.string   "from_name",          :limit => 30, :null => false
    t.string   "to_email_addresses",               :null => false
    t.integer  "user_id"
    t.integer  "contest_id",                       :null => false
    t.text     "message",                          :null => false
    t.datetime "created_on",                       :null => false
  end

  add_index "contest_recommendations", ["contest_id"], :name => "index_contest_recommendations_on_contest_id"
  add_index "contest_recommendations", ["user_id"], :name => "index_contest_recommendations_on_user_id"

  create_table "contest_regions", :force => true do |t|
    t.integer "contest_id",             :null => false
    t.integer "region_id",              :null => false
    t.boolean "featured"
    t.boolean "loyalty_points_enabled"
  end

  add_index "contest_regions", ["contest_id"], :name => "index_contest_regions_on_contest_id"
  add_index "contest_regions", ["featured"], :name => "index_contest_regions_on_featured"
  add_index "contest_regions", ["loyalty_points_enabled"], :name => "index_contest_regions_on_loyalty_points_enabled"
  add_index "contest_regions", ["region_id"], :name => "index_contest_regions_on_region_id"

  create_table "contests", :force => true do |t|
    t.string   "title",                     :limit => 100,                                    :null => false
    t.string   "description",               :limit => 350,                                    :null => false
    t.string   "slug",                      :limit => 100,                                    :null => false
    t.string   "type",                                                                        :null => false
    t.string   "content_type",                             :default => "Text",                :null => false
    t.integer  "status",                                   :default => 1,                     :null => false
    t.boolean  "others_can_submit_entries",                :default => false,                 :null => false
    t.date     "starts_on",                                                                   :null => false
    t.date     "ends_on",                                                                     :null => false
    t.integer  "user_id",                                                                     :null => false
    t.integer  "category_id"
    t.datetime "created_on",                                                                  :null => false
    t.datetime "updated_on",                                                                  :null => false
    t.boolean  "featured",                                 :default => false,                 :null => false
    t.string   "external_url"
    t.integer  "prize_id"
    t.integer  "skin_id"
    t.integer  "played",                                   :default => 0,                     :null => false
    t.integer  "favourited",                               :default => 0,                     :null => false
    t.integer  "net_votes",                                :default => 0,                     :null => false
    t.datetime "stats_updated_on",                         :default => '1970-01-01 00:00:00', :null => false
    t.boolean  "loyalty_points_enabled"
    t.integer  "brand_id"
    t.string   "brand_url"
    t.string   "version_number"
    t.string   "username"
    t.boolean  "locked",                                   :default => false,                 :null => false
    t.integer  "campaign_id"
    t.string   "campaign_type"
    t.boolean  "login_required",                           :default => false,                 :null => false
  end

  add_index "contests", ["brand_id"], :name => "index_contests_on_brand_id"
  add_index "contests", ["campaign_id"], :name => "index_contests_on_campaign_id"
  add_index "contests", ["category_id"], :name => "index_contests_on_category_id"
  add_index "contests", ["content_type"], :name => "index_contests_on_content_type"
  add_index "contests", ["favourited"], :name => "index_contests_on_favourited"
  add_index "contests", ["featured"], :name => "index_contests_on_featured"
  add_index "contests", ["loyalty_points_enabled"], :name => "index_contests_on_loyalty_points_enabled"
  add_index "contests", ["net_votes"], :name => "index_contests_on_net_votes"
  add_index "contests", ["played"], :name => "index_contests_on_played"
  add_index "contests", ["prize_id"], :name => "index_contests_on_prize_id"
  add_index "contests", ["skin_id"], :name => "index_contests_on_skin_id"
  add_index "contests", ["starts_on", "ends_on"], :name => "index_contests_on_starts_on_and_ends_on"
  add_index "contests", ["status"], :name => "index_contests_on_status"
  add_index "contests", ["type"], :name => "index_contests_on_type"
  add_index "contests", ["user_id"], :name => "index_contests_on_user_id"

  create_table "credit_transactions", :force => true do |t|
    t.integer  "user_id",                           :null => false
    t.float    "amount",                            :null => false
    t.string   "description",                       :null => false
    t.datetime "created_on",                        :null => false
    t.boolean  "loyalty_points", :default => false, :null => false
    t.integer  "for_id"
    t.string   "for_type"
  end

  add_index "credit_transactions", ["for_type", "for_id"], :name => "index_credit_transactions_on_for_type_and_for_id"
  add_index "credit_transactions", ["loyalty_points"], :name => "index_credit_transactions_on_loyalty_points"
  add_index "credit_transactions", ["user_id"], :name => "index_credit_transactions_on_user_id"

  create_table "crossword_clues", :force => true do |t|
    t.integer "question_id", :null => false
    t.boolean "across",      :null => false
    t.integer "row",         :null => false
    t.integer "col",         :null => false
    t.integer "length",      :null => false
    t.integer "position"
  end

  add_index "crossword_clues", ["question_id"], :name => "index_crossword_clues_on_question_id"

  create_table "crosswords", :force => true do |t|
  end

  create_table "dispatches", :force => true do |t|
    t.integer  "prize_id",                              :null => false
    t.integer  "user_id",                               :null => false
    t.string   "address_line_1",                        :null => false
    t.string   "address_line_2"
    t.string   "city",                                  :null => false
    t.string   "pin_code",                              :null => false
    t.string   "state",                                 :null => false
    t.string   "country",                               :null => false
    t.string   "mobile_number",                         :null => false
    t.string   "phone_number",                          :null => false
    t.integer  "short_listed_winner_id"
    t.integer  "credit_transaction_id"
    t.integer  "status",                 :default => 0, :null => false
    t.string   "cancelation_reason"
    t.string   "payment_type"
    t.string   "payment_number"
    t.float    "payment_amount"
    t.datetime "payment_received_on"
    t.integer  "payment_received_by_id"
    t.datetime "actioned_on"
    t.integer  "actioned_by_id"
    t.datetime "created_on",                            :null => false
    t.string   "paypal_account_id"
    t.string   "ssn"
  end

  add_index "dispatches", ["short_listed_winner_id"], :name => "index_dispatches_on_short_listed_winner_id"

  create_table "entries", :force => true do |t|
    t.integer  "faceoff_id",                                            :null => false
    t.integer  "user_id",                                               :null => false
    t.string   "title",                                                 :null => false
    t.text     "description"
    t.integer  "status",             :default => 0,                     :null => false
    t.string   "video_url"
    t.string   "image"
    t.datetime "created_on",                                            :null => false
    t.datetime "updated_on",         :default => '2013-04-07 19:12:09', :null => false
    t.integer  "video_id"
    t.integer  "total_points",       :default => 0
    t.string   "username"
    t.string   "external_video_url"
    t.string   "content_type"
    t.boolean  "image_in_s3",        :default => false,                 :null => false
  end

  add_index "entries", ["faceoff_id"], :name => "index_entries_on_faceoff_id"
  add_index "entries", ["status"], :name => "index_entries_on_status"
  add_index "entries", ["user_id"], :name => "index_entries_on_user_id"
  add_index "entries", ["video_id"], :name => "index_entries_on_video_id"

  create_table "favourite_topics", :force => true do |t|
    t.string "name", :limit => 30, :null => false
  end

  create_table "favourite_topics_users", :id => false, :force => true do |t|
    t.integer "favourite_topic_id", :null => false
    t.integer "user_id",            :null => false
  end

  add_index "favourite_topics_users", ["favourite_topic_id"], :name => "index_favourite_topics_users_on_favourite_topic_id"
  add_index "favourite_topics_users", ["user_id"], :name => "index_favourite_topics_users_on_user_id"

  create_table "favourites", :force => true do |t|
    t.integer "user_id",    :null => false
    t.integer "contest_id", :null => false
  end

  add_index "favourites", ["contest_id"], :name => "index_favourites_on_contest_id"
  add_index "favourites", ["user_id"], :name => "index_favourites_on_user_id"

  create_table "friendships", :force => true do |t|
    t.integer "user_id",   :null => false
    t.integer "friend_id", :null => false
  end

  add_index "friendships", ["friend_id"], :name => "index_friendships_on_friend_id"
  add_index "friendships", ["user_id"], :name => "index_friendships_on_user_id"

  create_table "guesses", :force => true do |t|
    t.string   "value",                          :null => false
    t.integer  "response_id",                    :null => false
    t.integer  "question_id",                    :null => false
    t.boolean  "correct",     :default => false, :null => false
    t.datetime "created_on",                     :null => false
  end

  add_index "guesses", ["question_id"], :name => "index_guesses_on_question_id"
  add_index "guesses", ["response_id", "question_id"], :name => "index_guesses_on_response_id_and_question_id"

  create_table "ignored_users", :force => true do |t|
    t.integer "user_id",         :null => false
    t.integer "ignored_user_id", :null => false
  end

  add_index "ignored_users", ["ignored_user_id"], :name => "index_ignored_users_on_ignored_user_id"
  add_index "ignored_users", ["user_id"], :name => "index_ignored_users_on_user_id"

  create_table "login_tokens", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.text     "token",      :null => false
    t.datetime "created_on", :null => false
  end

  add_index "login_tokens", ["token"], :name => "index_login_tokens_on_token"
  add_index "login_tokens", ["user_id"], :name => "index_login_tokens_on_user_id"

  create_table "loyalty_points_logs", :force => true do |t|
    t.datetime "ran_on"
  end

  create_table "messages", :force => true do |t|
    t.text     "body",        :null => false
    t.integer  "sender_id",   :null => false
    t.integer  "receiver_id", :null => false
    t.datetime "created_on",  :null => false
  end

  add_index "messages", ["receiver_id", "created_on"], :name => "index_messages_on_receiver_id_and_created_on"
  add_index "messages", ["sender_id"], :name => "index_messages_on_sender_id"

  create_table "old_c2w_users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "pin_code"
    t.string   "contact_number"
    t.string   "gender"
    t.date     "date_of_birth"
    t.string   "email"
    t.date     "date_of_registration"
    t.string   "fmail"
    t.integer  "points"
    t.date     "modified_on"
    t.string   "mobile_number"
    t.datetime "migrated_on"
    t.integer  "new_user_id"
    t.string   "password"
    t.string   "userid"
  end

  add_index "old_c2w_users", ["migrated_on"], :name => "index_old_c2w_users_on_migrated_on"
  add_index "old_c2w_users", ["new_user_id"], :name => "index_old_c2w_users_on_new_user_id"
  add_index "old_c2w_users", [nil], :name => "index_old_c2w_users_on_email"
  add_index "old_c2w_users", [nil], :name => "index_old_c2w_users_on_userid"

  create_table "pending_deletions", :force => true do |t|
    t.string   "key",        :null => false
    t.datetime "created_at"
  end

  create_table "persistent_logins", :force => true do |t|
    t.string   "uid",        :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_on", :null => false
  end

  add_index "persistent_logins", ["uid"], :name => "uid"

  create_table "personalities", :force => true do |t|
    t.integer  "contest_id",                         :null => false
    t.string   "title",                              :null => false
    t.string   "description"
    t.integer  "minimum_score",                      :null => false
    t.integer  "maximum_score",                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "number_of_users", :default => 0
    t.string   "image"
    t.boolean  "image_in_s3",     :default => false, :null => false
  end

  add_index "personalities", ["contest_id"], :name => "index_personalities_on_contest_id"

  create_table "prize_categories", :force => true do |t|
    t.string "name", :limit => 30, :null => false
  end

  add_index "prize_categories", ["name"], :name => "index_prize_categories_on_name"

  create_table "prize_categories_prizes", :id => false, :force => true do |t|
    t.integer "category_id", :null => false
    t.integer "prize_id",    :null => false
  end

  add_index "prize_categories_prizes", ["category_id"], :name => "index_prize_categories_prizes_on_category_id"
  add_index "prize_categories_prizes", ["prize_id"], :name => "index_prize_categories_prizes_on_prize_id"

  create_table "prizes", :force => true do |t|
    t.string   "title",           :limit => 100,                    :null => false
    t.string   "description",                                       :null => false
    t.string   "video_url"
    t.string   "image"
    t.boolean  "disabled",                       :default => false, :null => false
    t.datetime "created_on",                                        :null => false
    t.datetime "updated_on",                                        :null => false
    t.float    "value"
    t.text     "special_note"
    t.string   "item_type"
    t.string   "thumbnail"
    t.float    "credits"
    t.boolean  "most_redeemed"
    t.integer  "region_id"
    t.boolean  "thumbnail_in_s3",                :default => false, :null => false
    t.boolean  "image_in_s3",                    :default => false, :null => false
  end

  add_index "prizes", ["region_id"], :name => "index_prizes_on_region_id"

  create_table "question_options", :force => true do |t|
    t.integer "question_id",                :null => false
    t.integer "entry_id"
    t.integer "position",    :default => 0, :null => false
    t.integer "points",      :default => 0, :null => false
    t.string  "text",                       :null => false
    t.integer "clicks",      :default => 0, :null => false
  end

  add_index "question_options", ["entry_id"], :name => "index_question_options_on_entry_id"
  add_index "question_options", ["question_id"], :name => "index_question_options_on_question_id"

  create_table "questions", :force => true do |t|
    t.integer  "contest_id",                              :null => false
    t.integer  "user_id",                                 :null => false
    t.string   "question",                                :null => false
    t.integer  "status",               :default => 0,     :null => false
    t.string   "external_video_url"
    t.string   "image"
    t.datetime "created_on",                              :null => false
    t.datetime "updated_on",                              :null => false
    t.string   "content_type"
    t.integer  "answers_count",        :default => 0,     :null => false
    t.string   "hint"
    t.integer  "video_id"
    t.integer  "total_rating",         :default => 0
    t.string   "username"
    t.boolean  "image_in_s3",          :default => false, :null => false
    t.datetime "ends_on"
    t.integer  "betting_status"
    t.integer  "betting_limit"
    t.boolean  "reuse_previous_media", :default => false, :null => false
  end

  add_index "questions", ["betting_status"], :name => "index_questions_on_betting_status"
  add_index "questions", ["contest_id"], :name => "index_questions_on_contest_id"
  add_index "questions", ["status"], :name => "index_questions_on_status"
  add_index "questions", ["user_id"], :name => "index_questions_on_user_id"
  add_index "questions", ["video_id"], :name => "index_questions_on_video_id"

  create_table "ranked_entries", :force => true do |t|
    t.integer  "faceoff_id",                     :null => false
    t.integer  "entry_id",                       :null => false
    t.integer  "response_id",                    :null => false
    t.integer  "points",                         :null => false
    t.boolean  "sorted",      :default => false, :null => false
    t.integer  "upper_bound"
    t.integer  "lower_bound"
    t.datetime "created_on",                     :null => false
  end

  add_index "ranked_entries", ["entry_id"], :name => "index_ranked_entries_on_entry_id"
  add_index "ranked_entries", ["faceoff_id"], :name => "index_ranked_entries_on_faceoff_id"
  add_index "ranked_entries", ["response_id", "points"], :name => "index_ranked_entries_on_response_id_and_points"

  create_table "rankings", :force => true do |t|
    t.integer  "user_id",     :null => false
    t.string   "leaderboard", :null => false
    t.integer  "rank",        :null => false
    t.integer  "score",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rankings", ["leaderboard", "rank"], :name => "index_rankings_on_leaderboard_and_rank"
  add_index "rankings", ["leaderboard", "user_id"], :name => "index_rankings_on_leaderboard_and_user_id", :unique => true

  create_table "referrals", :force => true do |t|
    t.integer  "referrer_id"
    t.integer  "referred_id"
    t.string   "referred_username"
    t.datetime "created_on"
    t.datetime "pp_threshold_reached_on"
    t.datetime "creation_threshold_reached_on"
  end

  add_index "referrals", ["created_on"], :name => "index_referrals_on_created_on"
  add_index "referrals", ["creation_threshold_reached_on"], :name => "index_referrals_on_creation_threshold_reached_on"
  add_index "referrals", ["pp_threshold_reached_on"], :name => "index_referrals_on_pp_threshold_reached_on"
  add_index "referrals", ["referred_id"], :name => "index_referrals_on_referred_id"
  add_index "referrals", ["referrer_id"], :name => "index_referrals_on_referrer_id"

  create_table "regions", :force => true do |t|
    t.string "name",          :null => false
    t.string "domain_prefix", :null => false
  end

  add_index "regions", ["domain_prefix"], :name => "index_regions_on_domain_prefix", :unique => true

  create_table "responses", :force => true do |t|
    t.integer  "user_id"
    t.integer  "contest_id",                                               :null => false
    t.integer  "score",                 :default => 0,                     :null => false
    t.datetime "created_on",                                               :null => false
    t.datetime "updated_on",            :default => '2013-04-07 19:08:25', :null => false
    t.integer  "view_level",            :default => 100,                   :null => false
    t.integer  "answers_count",         :default => 0,                     :null => false
    t.string   "session_id"
    t.integer  "correct_answers_count", :default => 0,                     :null => false
    t.string   "type",                  :default => "Response",            :null => false
    t.boolean  "old_response",          :default => false,                 :null => false
    t.datetime "finished_on",           :default => '2013-04-07 19:12:14'
  end

  add_index "responses", ["contest_id"], :name => "index_responses_on_contest_id"
  add_index "responses", ["created_on"], :name => "index_responses_on_created_on"
  add_index "responses", ["session_id"], :name => "index_responses_on_session_id"
  add_index "responses", ["type"], :name => "index_responses_on_type"
  add_index "responses", ["user_id"], :name => "index_responses_on_user_id"

  create_table "settings", :force => true do |t|
    t.string "name",  :null => false
    t.string "value", :null => false
  end

  add_index "settings", ["name"], :name => "index_settings_on_name", :unique => true

  create_table "short_listed_winners", :force => true do |t|
    t.integer  "contest_prize_id", :null => false
    t.integer  "user_id",          :null => false
    t.datetime "created_on",       :null => false
    t.datetime "confirmed_on"
    t.boolean  "accepted"
    t.integer  "entry_id"
    t.string   "entry_type"
  end

  add_index "short_listed_winners", ["accepted"], :name => "index_short_listed_winners_on_accepted"
  add_index "short_listed_winners", ["contest_prize_id"], :name => "index_short_listed_winners_on_contest_prize_id"
  add_index "short_listed_winners", ["created_on"], :name => "index_short_listed_winners_on_created_on"
  add_index "short_listed_winners", ["user_id"], :name => "index_short_listed_winners_on_user_id"

  create_table "skins", :force => true do |t|
    t.string   "name",         :limit => 30,                    :null => false
    t.text     "description",                                   :null => false
    t.string   "contest_type", :limit => 30,                    :null => false
    t.string   "image"
    t.string   "file",                                          :null => false
    t.boolean  "expired",                    :default => false, :null => false
    t.datetime "created_on",                                    :null => false
    t.datetime "updated_on",                                    :null => false
    t.boolean  "only_admin",                 :default => false, :null => false
    t.boolean  "image_in_s3",                :default => false, :null => false
    t.boolean  "file_in_s3",                 :default => false, :null => false
  end

  add_index "skins", ["contest_type", "expired"], :name => "index_skins_on_contest_type_and_expired"
  add_index "skins", ["name"], :name => "index_skins_on_name", :unique => true

  create_table "sms_alerts", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.string   "msisdn",                        :null => false
    t.string   "message"
    t.integer  "attempts",       :default => 0, :null => false
    t.integer  "status",         :default => 0, :null => false
    t.string   "transaction_id"
    t.datetime "sent_on"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sms_alerts", ["status"], :name => "index_sms_alerts_on_status"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id"], :name => "index_taggings_on_taggable_id"
  add_index "taggings", ["taggable_type"], :name => "index_taggings_on_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "user_activation_codes", :force => true do |t|
    t.integer "user_id", :null => false
    t.string  "code",    :null => false
  end

  add_index "user_activation_codes", ["user_id"], :name => "index_user_activation_codes_on_user_id"

  create_table "user_preferences", :force => true do |t|
    t.integer "user_id",         :null => false
    t.integer "preference_type", :null => false
  end

  add_index "user_preferences", ["user_id"], :name => "index_user_preferences_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "username",            :limit => 30,                      :null => false
    t.string   "email",                                                  :null => false
    t.string   "password",                                               :null => false
    t.string   "first_name",          :limit => 30
    t.string   "last_name",           :limit => 30
    t.string   "picture"
    t.string   "gender",              :limit => 10
    t.date     "date_of_birth"
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "city"
    t.string   "pin_code"
    t.string   "state"
    t.string   "phone_number"
    t.string   "mobile_number"
    t.string   "favourite_topics"
    t.string   "favourite_prizes"
    t.integer  "status"
    t.integer  "level"
    t.datetime "last_logged_in_on"
    t.datetime "created_on",                                             :null => false
    t.datetime "updated_on",                                             :null => false
    t.string   "occupation"
    t.integer  "number_of_friends",                 :default => 0,       :null => false
    t.string   "country",                           :default => "India", :null => false
    t.integer  "region_id"
    t.integer  "number_of_responses",               :default => 0
    t.boolean  "picture_in_s3",                     :default => false,   :null => false
    t.integer  "net_pp_earned",                     :default => 0,       :null => false
    t.integer  "last_pp_earned",                    :default => 0,       :null => false
    t.datetime "pp_calculated_at"
    t.integer  "login_attempts"
    t.integer  "fb_id",               :limit => 8
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["fb_id"], :name => "index_users_on_fb_id"
  add_index "users", ["status"], :name => "index_users_on_status"
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

  create_table "videos", :force => true do |t|
    t.string   "title",                                :null => false
    t.string   "original_file",                        :null => false
    t.string   "stream_file"
    t.string   "image"
    t.integer  "status",            :default => 0,     :null => false
    t.integer  "created_by_id",                        :null => false
    t.datetime "created_on",                           :null => false
    t.datetime "updated_on",                           :null => false
    t.boolean  "shared",            :default => false, :null => false
    t.boolean  "stream_file_in_s3", :default => false, :null => false
    t.boolean  "image_in_s3",       :default => false, :null => false
  end

  add_index "videos", ["created_by_id"], :name => "index_videos_on_created_by_id"
  add_index "videos", ["status"], :name => "index_videos_on_status"

  create_table "votes", :force => true do |t|
    t.integer  "voteable_id",                :null => false
    t.integer  "points",      :default => 1, :null => false
    t.integer  "user_id",                    :null => false
    t.datetime "created_on",                 :null => false
  end

  add_index "votes", ["user_id"], :name => "index_votes_on_user_id"
  add_index "votes", ["voteable_id", "user_id"], :name => "index_votes_on_voteable_id_and_user_id", :unique => true
  add_index "votes", ["voteable_id"], :name => "index_votes_on_voteable_id"

end
