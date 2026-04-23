# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_04_23_123000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.bigint "plan_id", null: false
    t.boolean "active"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_accounts_on_plan_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_events", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id"
    t.string "event_type", null: false
    t.string "subject_type", null: false
    t.bigint "subject_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "event_type", "created_at"], name: "index_audit_events_on_account_event_and_created_at"
    t.index ["account_id"], name: "index_audit_events_on_account_id"
    t.index ["subject_type", "subject_id"], name: "index_audit_events_on_subject"
    t.index ["user_id", "created_at"], name: "index_audit_events_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_audit_events_on_user_id"
  end

  create_table "audits", force: :cascade do |t|
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.bigint "associated_id"
    t.string "associated_type"
    t.bigint "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at", null: false
    t.bigint "account_id"
    t.index ["account_id", "created_at"], name: "index_audits_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_audits_on_account_id"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "bank_statement_imports", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.string "status", default: "pending", null: false
    t.jsonb "metadata", default: {}, null: false
    t.text "ocr_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "institution_id", null: false
    t.index ["account_id"], name: "index_bank_statement_imports_on_account_id"
    t.index ["client_id", "created_at"], name: "index_bank_statement_imports_on_client_id_and_created_at"
    t.index ["client_id"], name: "index_bank_statement_imports_on_client_id"
    t.index ["institution_id"], name: "index_bank_statement_imports_on_institution_id"
    t.index ["status"], name: "index_bank_statement_imports_on_status"
  end

  create_table "bank_statements", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.bigint "bank_statement_import_id", null: false
    t.date "occurred_on", null: false
    t.decimal "amount", precision: 16, scale: 2, null: false
    t.string "transaction_type", null: false
    t.bigint "institution_id", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "possible_duplicate", default: false, null: false
    t.index ["account_id"], name: "index_bank_statements_on_account_id"
    t.index ["bank_statement_import_id"], name: "index_bank_statements_on_bank_statement_import_id"
    t.index ["client_id", "occurred_on"], name: "index_bank_statements_on_client_id_and_occurred_on"
    t.index ["client_id"], name: "index_bank_statements_on_client_id"
    t.index ["institution_id"], name: "index_bank_statements_on_institution_id"
  end

  create_table "client_checklist_items", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.jsonb "match_terms", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "client_id", "active"], name: "idx_on_account_id_client_id_active_80dda41374"
    t.index ["account_id", "client_id", "position"], name: "idx_on_account_id_client_id_position_7f36bb5353"
    t.index ["account_id"], name: "index_client_checklist_items_on_account_id"
    t.index ["client_id"], name: "index_client_checklist_items_on_client_id"
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.string "tax_id"
    t.string "email"
    t.string "phone"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "tax_id"], name: "index_clients_on_account_id_and_tax_id", unique: true, where: "((tax_id IS NOT NULL) AND ((tax_id)::text <> ''::text))"
    t.index ["account_id"], name: "index_clients_on_account_id"
  end

  create_table "competency_checklist_items", force: :cascade do |t|
    t.bigint "competency_checklist_id", null: false
    t.bigint "client_checklist_item_id"
    t.bigint "last_document_id"
    t.bigint "validated_by_user_id"
    t.string "name_snapshot", null: false
    t.string "state", default: "pending", null: false
    t.datetime "received_at"
    t.datetime "validated_at"
    t.text "validation_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "match_terms", default: [], null: false
    t.index ["client_checklist_item_id"], name: "index_competency_checklist_items_on_client_checklist_item_id"
    t.index ["competency_checklist_id", "client_checklist_item_id"], name: "idx_comp_checklist_items_on_competency_and_template", unique: true
    t.index ["competency_checklist_id"], name: "index_competency_checklist_items_on_competency_checklist_id"
    t.index ["last_document_id"], name: "index_competency_checklist_items_on_last_document_id"
    t.index ["state"], name: "index_competency_checklist_items_on_state"
    t.index ["validated_by_user_id"], name: "index_competency_checklist_items_on_validated_by_user_id"
  end

  create_table "competency_checklists", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.date "period", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "client_id", "period"], name: "idx_on_account_id_client_id_period_7cc7b2bb99", unique: true
    t.index ["account_id"], name: "index_competency_checklists_on_account_id"
    t.index ["client_id"], name: "index_competency_checklists_on_client_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.string "title"
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_conversations_on_account_id"
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.bigint "folder_id", null: false
    t.text "content"
    t.text "summary"
    t.string "status"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "tags", default: [], null: false
    t.index ["account_id"], name: "index_documents_on_account_id"
    t.index ["folder_id"], name: "index_documents_on_folder_id"
    t.index ["tags"], name: "index_documents_on_tags", using: :gin
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "embedding_records", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "document_id"
    t.text "content"
    t.vector "embedding", limit: 1536
    t.string "recordable_type"
    t.bigint "recordable_id"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "document_id"], name: "index_embedding_records_on_account_id_and_document_id"
    t.index ["account_id"], name: "index_embedding_records_on_account_id"
    t.index ["embedding"], name: "index_embedding_records_on_embedding", opclass: :vector_cosine_ops, using: :ivfflat
    t.index ["recordable_type", "recordable_id"], name: "index_embedding_records_on_recordable"
    t.index ["recordable_type", "recordable_id"], name: "index_embedding_records_on_wiki_page_unique", unique: true, where: "((recordable_type)::text = 'WikiPage'::text)"
  end

  create_table "folders", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id"
    t.boolean "visible", default: false, null: false
    t.string "public_upload_token"
    t.datetime "public_upload_token_expires_at"
    t.index ["account_id"], name: "index_folders_on_account_id"
    t.index ["client_id"], name: "index_folders_on_client_id"
    t.index ["public_upload_token"], name: "index_folders_on_public_upload_token", unique: true
  end

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_group_memberships_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_groups_on_account_id"
  end

  create_table "institutions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.boolean "system", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_institutions_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_institutions_on_account_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.string "role"
    t.text "content"
    t.jsonb "sources"
    t.jsonb "metadata", default: {}, null: false
    t.boolean "streaming", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name"
    t.integer "price"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "generate_tags_automatically", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_settings_on_account_id", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "plan_id", null: false
    t.string "status"
    t.datetime "current_period_end"
    t.datetime "trial_ends_at"
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_subscriptions_on_account_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "email"
    t.string "name"
    t.string "role"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "wiki_links", force: :cascade do |t|
    t.bigint "source_page_id", null: false
    t.bigint "target_page_id", null: false
    t.string "link_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_page_id", "target_page_id"], name: "index_wiki_links_on_source_page_id_and_target_page_id", unique: true
    t.index ["source_page_id"], name: "index_wiki_links_on_source_page_id"
    t.index ["target_page_id"], name: "index_wiki_links_on_target_page_id"
  end

  create_table "wiki_logs", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "operation", null: false
    t.integer "document_id"
    t.integer "wiki_page_id"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_wiki_logs_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_wiki_logs_on_account_id"
  end

  create_table "wiki_pages", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.text "content"
    t.string "page_type", null: false
    t.integer "source_document_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "source_bank_statement_import_id"
    t.index ["account_id", "slug"], name: "index_wiki_pages_on_account_id_and_slug", unique: true
    t.index ["account_id"], name: "index_wiki_pages_on_account_id"
    t.index ["page_type"], name: "index_wiki_pages_on_page_type"
    t.index ["source_bank_statement_import_id"], name: "index_wiki_pages_on_source_bank_statement_import_id"
  end

  create_table "wiki_schemas", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.text "instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_wiki_schemas_on_account_id"
  end

  add_foreign_key "accounts", "plans"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_events", "accounts"
  add_foreign_key "audit_events", "users"
  add_foreign_key "audits", "accounts"
  add_foreign_key "bank_statement_imports", "accounts"
  add_foreign_key "bank_statement_imports", "clients"
  add_foreign_key "bank_statement_imports", "institutions"
  add_foreign_key "bank_statements", "accounts"
  add_foreign_key "bank_statements", "bank_statement_imports"
  add_foreign_key "bank_statements", "clients"
  add_foreign_key "bank_statements", "institutions"
  add_foreign_key "client_checklist_items", "accounts"
  add_foreign_key "client_checklist_items", "clients"
  add_foreign_key "clients", "accounts"
  add_foreign_key "competency_checklist_items", "client_checklist_items"
  add_foreign_key "competency_checklist_items", "competency_checklists"
  add_foreign_key "competency_checklist_items", "documents", column: "last_document_id"
  add_foreign_key "competency_checklist_items", "users", column: "validated_by_user_id"
  add_foreign_key "competency_checklists", "accounts"
  add_foreign_key "competency_checklists", "clients"
  add_foreign_key "conversations", "accounts"
  add_foreign_key "conversations", "users"
  add_foreign_key "documents", "accounts"
  add_foreign_key "documents", "folders"
  add_foreign_key "documents", "users"
  add_foreign_key "embedding_records", "accounts"
  add_foreign_key "folders", "accounts"
  add_foreign_key "folders", "clients"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "groups", "accounts"
  add_foreign_key "institutions", "accounts"
  add_foreign_key "messages", "conversations"
  add_foreign_key "settings", "accounts"
  add_foreign_key "subscriptions", "accounts"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "users", "accounts"
  add_foreign_key "wiki_links", "wiki_pages", column: "source_page_id"
  add_foreign_key "wiki_links", "wiki_pages", column: "target_page_id"
  add_foreign_key "wiki_logs", "accounts"
  add_foreign_key "wiki_pages", "accounts"
  add_foreign_key "wiki_pages", "bank_statement_imports", column: "source_bank_statement_import_id"
  add_foreign_key "wiki_schemas", "accounts"
end
