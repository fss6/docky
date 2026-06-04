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

ActiveRecord::Schema[8.0].define(version: 2026_06_04_094529) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "account_permission_grants", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "capability_key", null: false
    t.string "role", default: "member", null: false
    t.boolean "granted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "capability_key", "role"], name: "index_account_permission_grants_unique", unique: true
    t.index ["account_id"], name: "index_account_permission_grants_on_account_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.bigint "plan_id", null: false
    t.boolean "active"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "contact_email"
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

  create_table "client_collection_preferences", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "email_opted_out_at"
    t.datetime "whatsapp_opted_out_at"
    t.string "whatsapp_opt_out_source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_collection_preferences_on_client_id", unique: true
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
    t.integer "monthly_deadline_day", default: 10, null: false
    t.string "status", default: "active", null: false
    t.datetime "archived_at"
    t.bigint "archived_by_user_id"
    t.bigint "onboarding_template_id"
    t.index ["account_id", "tax_id"], name: "index_clients_on_account_id_and_tax_id", unique: true, where: "((tax_id IS NOT NULL) AND ((tax_id)::text <> ''::text))"
    t.index ["account_id"], name: "index_clients_on_account_id"
    t.index ["archived_at"], name: "index_clients_on_archived_at"
    t.index ["archived_by_user_id"], name: "index_clients_on_archived_by_user_id"
    t.index ["onboarding_template_id"], name: "index_clients_on_onboarding_template_id"
    t.index ["status"], name: "index_clients_on_status"
  end

  create_table "collection_delivery_events", force: :cascade do |t|
    t.bigint "collection_dispatch_id", null: false
    t.string "event", null: false
    t.datetime "occurred_at", null: false
    t.string "reliability_tier", default: "strong", null: false
    t.jsonb "raw_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_dispatch_id", "event", "occurred_at"], name: "index_collection_delivery_events_on_dispatch_event"
    t.index ["collection_dispatch_id"], name: "index_collection_delivery_events_on_collection_dispatch_id"
  end

  create_table "collection_dispatches", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.bigint "period_id", null: false
    t.bigint "collection_step_id", null: false
    t.string "channel", null: false
    t.string "status", default: "scheduled", null: false
    t.string "skip_reason"
    t.string "rendered_subject"
    t.text "rendered_body"
    t.string "provider_message_id"
    t.datetime "sent_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "status", "created_at"], name: "idx_on_account_id_status_created_at_e8df138900"
    t.index ["account_id"], name: "index_collection_dispatches_on_account_id"
    t.index ["client_id", "period_id", "collection_step_id", "channel"], name: "index_collection_dispatches_unique_per_cycle", unique: true
    t.index ["client_id"], name: "index_collection_dispatches_on_client_id"
    t.index ["collection_step_id"], name: "index_collection_dispatches_on_collection_step_id"
    t.index ["period_id"], name: "index_collection_dispatches_on_period_id"
    t.index ["provider_message_id"], name: "index_collection_dispatches_on_provider_message_id"
  end

  create_table "collection_settings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "enabled", default: false, null: false
    t.time "quiet_hours_start", default: "2000-01-01 08:00:00", null: false
    t.time "quiet_hours_end", default: "2000-01-01 19:00:00", null: false
    t.integer "max_messages_per_client_per_day", default: 1, null: false
    t.string "timezone", default: "America/Sao_Paulo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_collection_settings_on_account_id", unique: true
  end

  create_table "collection_steps", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "offset_days", null: false
    t.string "name", null: false
    t.string "kind", default: "client_reminder", null: false
    t.boolean "email_enabled", default: false, null: false
    t.boolean "whatsapp_enabled", default: false, null: false
    t.string "email_subject_template"
    t.text "email_body_template"
    t.text "whatsapp_body_template"
    t.string "whatsapp_template_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "offset_days"], name: "index_collection_steps_on_account_id_and_offset_days", unique: true
    t.index ["account_id", "position"], name: "index_collection_steps_on_account_id_and_position"
    t.index ["account_id"], name: "index_collection_steps_on_account_id"
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
    t.string "status", default: "open", null: false
    t.datetime "opened_at", null: false
    t.datetime "closed_at"
    t.bigint "closed_by_user_id"
    t.index ["account_id", "client_id", "period"], name: "idx_on_account_id_client_id_period_7cc7b2bb99", unique: true
    t.index ["account_id"], name: "index_competency_checklists_on_account_id"
    t.index ["client_id"], name: "index_competency_checklists_on_client_id"
    t.index ["closed_by_user_id"], name: "index_competency_checklists_on_closed_by_user_id"
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
    t.bigint "client_id"
    t.date "collection_period"
    t.bigint "period_id"
    t.string "content_sha256", limit: 64
    t.index ["account_id", "content_sha256"], name: "index_documents_on_account_content_sha256_processed", where: "(((status)::text = 'processed'::text) AND (content_sha256 IS NOT NULL))"
    t.index ["account_id"], name: "index_documents_on_account_id"
    t.index ["client_id", "collection_period", "created_at"], name: "index_documents_on_client_collection_created"
    t.index ["client_id", "period_id", "created_at"], name: "index_documents_on_client_period_created"
    t.index ["client_id"], name: "index_documents_on_client_id"
    t.index ["folder_id"], name: "index_documents_on_folder_id"
    t.index ["period_id"], name: "index_documents_on_period_id"
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

  create_table "fiscal_certificates", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.text "cert_password_ciphertext"
    t.string "holder_name"
    t.string "cnpj", null: false
    t.string "issuer"
    t.datetime "valid_from"
    t.datetime "valid_until", null: false
    t.string "fingerprint_sha1"
    t.string "cert_type", default: "A1", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "cnpj"], name: "index_fiscal_certificates_on_account_id_and_cnpj"
    t.index ["account_id"], name: "index_fiscal_certificates_on_account_id"
    t.index ["client_id", "status"], name: "index_fiscal_certificates_on_client_id_and_status"
    t.index ["client_id"], name: "index_fiscal_certificates_on_client_id"
  end

  create_table "fiscal_documents", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.string "chave", limit: 44, null: false
    t.string "nsu", null: false
    t.string "emit_name"
    t.string "emit_cnpj"
    t.string "numero"
    t.string "serie"
    t.string "modelo", default: "55"
    t.datetime "emitted_at"
    t.decimal "valor_total", precision: 15, scale: 2
    t.string "lifecycle_state", default: "resumo_recebido", null: false
    t.datetime "received_at"
    t.datetime "manifested_at"
    t.datetime "classified_at"
    t.string "provider_document_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "chave"], name: "index_fiscal_documents_on_account_id_and_chave", unique: true
    t.index ["account_id"], name: "index_fiscal_documents_on_account_id"
    t.index ["client_id", "lifecycle_state"], name: "index_fiscal_documents_on_client_id_and_lifecycle_state"
    t.index ["client_id", "nsu"], name: "index_fiscal_documents_on_client_id_and_nsu"
    t.index ["client_id"], name: "index_fiscal_documents_on_client_id"
  end

  create_table "fiscal_sync_runs", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.integer "docs_fetched", default: 0, null: false
    t.string "result"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_fiscal_sync_runs_on_account_id"
    t.index ["client_id", "started_at"], name: "index_fiscal_sync_runs_on_client_id_and_started_at"
    t.index ["client_id"], name: "index_fiscal_sync_runs_on_client_id"
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

  create_table "nfe_sync_states", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.string "last_nsu", default: "000000000000", null: false
    t.string "max_nsu_seen"
    t.datetime "last_sync_at"
    t.string "sync_status", default: "ok", null: false
    t.text "last_error"
    t.integer "consecutive_failures", default: 0, null: false
    t.boolean "auto_manifest", default: true, null: false
    t.boolean "fetch_history_on_first_sync", default: true, null: false
    t.boolean "first_sync_completed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_nfe_sync_states_on_account_id"
    t.index ["client_id"], name: "index_nfe_sync_states_on_client_id", unique: true
  end

  create_table "onboarding_checklist_items", force: :cascade do |t|
    t.bigint "onboarding_checklist_id", null: false
    t.string "name", null: false
    t.text "help_text"
    t.integer "position", default: 0, null: false
    t.string "state", default: "pending", null: false
    t.bigint "last_document_id"
    t.bigint "validated_by_user_id"
    t.datetime "received_at"
    t.datetime "validated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_document_id"], name: "index_onboarding_checklist_items_on_last_document_id"
    t.index ["onboarding_checklist_id"], name: "index_onboarding_checklist_items_on_onboarding_checklist_id"
  end

  create_table "onboarding_checklists", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.string "status", default: "in_progress", null: false
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "onboarding_template_id"
    t.index ["account_id"], name: "index_onboarding_checklists_on_account_id"
    t.index ["client_id"], name: "index_onboarding_checklists_on_client_id", unique: true
    t.index ["onboarding_template_id"], name: "index_onboarding_checklists_on_onboarding_template_id"
  end

  create_table "onboarding_template_items", force: :cascade do |t|
    t.bigint "onboarding_template_id", null: false
    t.string "name", null: false
    t.text "help_text"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["onboarding_template_id", "position"], name: "index_onboarding_template_items_on_template_and_position"
  end

  create_table "onboarding_templates", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.string "kind", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "system", default: false, null: false
    t.text "description"
    t.index ["account_id", "kind"], name: "index_onboarding_templates_on_account_id_and_kind", unique: true
    t.index ["account_id"], name: "index_onboarding_templates_on_account_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name"
    t.integer "price"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "platform_settings", primary_key: "singleton_key", id: :string, default: "default", force: :cascade do |t|
    t.string "mail_delivery"
    t.string "smtp_address"
    t.integer "smtp_port"
    t.string "smtp_domain"
    t.string "smtp_username"
    t.string "smtp_authentication", default: "plain"
    t.string "mailer_from"
    t.text "smtp_password"
    t.string "whatsapp_phone_number_id"
    t.string "whatsapp_waba_id"
    t.string "whatsapp_api_version", default: "v21.0"
    t.string "whatsapp_verify_token"
    t.text "whatsapp_access_token"
    t.text "whatsapp_app_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "generate_tags_automatically", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "upload_share_whatsapp_template", null: false
    t.string "upload_share_email_subject_template", null: false
    t.text "upload_share_email_body_template", null: false
    t.text "onboarding_share_whatsapp_template"
    t.string "onboarding_share_email_subject_template"
    t.text "onboarding_share_email_body_template"
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

  create_table "upload_invites", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.date "period"
    t.string "token", null: false
    t.bigint "created_by_user_id"
    t.datetime "expires_at"
    t.datetime "revoked_at"
    t.integer "access_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "purpose", default: "monthly", null: false
    t.index ["account_id"], name: "index_upload_invites_on_account_id"
    t.index ["client_id", "period", "created_at"], name: "index_upload_invites_on_client_period_created"
    t.index ["client_id", "purpose"], name: "index_upload_invites_on_client_purpose_active", where: "(revoked_at IS NULL)"
    t.index ["client_id"], name: "index_upload_invites_on_client_id"
    t.index ["created_by_user_id"], name: "index_upload_invites_on_created_by_user_id"
    t.index ["token"], name: "index_upload_invites_on_token", unique: true
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
    t.boolean "founding_user", default: false, null: false
    t.index ["account_id", "founding_user"], name: "index_users_on_account_id_founding_user", unique: true, where: "(founding_user = true)"
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
    t.index ["account_id", "slug"], name: "index_wiki_pages_on_account_id_and_slug", unique: true
    t.index ["account_id"], name: "index_wiki_pages_on_account_id"
    t.index ["page_type"], name: "index_wiki_pages_on_page_type"
  end

  create_table "wiki_schemas", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.text "instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_wiki_schemas_on_account_id"
  end

  add_foreign_key "account_permission_grants", "accounts"
  add_foreign_key "accounts", "plans"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_events", "accounts"
  add_foreign_key "audit_events", "users"
  add_foreign_key "audits", "accounts"
  add_foreign_key "client_checklist_items", "accounts"
  add_foreign_key "client_checklist_items", "clients"
  add_foreign_key "client_collection_preferences", "clients"
  add_foreign_key "clients", "accounts"
  add_foreign_key "clients", "onboarding_templates"
  add_foreign_key "clients", "users", column: "archived_by_user_id"
  add_foreign_key "collection_delivery_events", "collection_dispatches"
  add_foreign_key "collection_dispatches", "accounts"
  add_foreign_key "collection_dispatches", "clients"
  add_foreign_key "collection_dispatches", "collection_steps"
  add_foreign_key "collection_dispatches", "competency_checklists", column: "period_id"
  add_foreign_key "collection_settings", "accounts"
  add_foreign_key "collection_steps", "accounts"
  add_foreign_key "competency_checklist_items", "client_checklist_items"
  add_foreign_key "competency_checklist_items", "competency_checklists"
  add_foreign_key "competency_checklist_items", "documents", column: "last_document_id"
  add_foreign_key "competency_checklist_items", "users", column: "validated_by_user_id"
  add_foreign_key "competency_checklists", "accounts"
  add_foreign_key "competency_checklists", "clients"
  add_foreign_key "competency_checklists", "users", column: "closed_by_user_id"
  add_foreign_key "conversations", "accounts"
  add_foreign_key "conversations", "users"
  add_foreign_key "documents", "accounts"
  add_foreign_key "documents", "clients"
  add_foreign_key "documents", "competency_checklists", column: "period_id"
  add_foreign_key "documents", "folders"
  add_foreign_key "documents", "users"
  add_foreign_key "embedding_records", "accounts"
  add_foreign_key "fiscal_certificates", "accounts"
  add_foreign_key "fiscal_certificates", "clients"
  add_foreign_key "fiscal_documents", "accounts"
  add_foreign_key "fiscal_documents", "clients"
  add_foreign_key "fiscal_sync_runs", "accounts"
  add_foreign_key "fiscal_sync_runs", "clients"
  add_foreign_key "folders", "accounts"
  add_foreign_key "folders", "clients"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "groups", "accounts"
  add_foreign_key "institutions", "accounts"
  add_foreign_key "messages", "conversations"
  add_foreign_key "nfe_sync_states", "accounts"
  add_foreign_key "nfe_sync_states", "clients"
  add_foreign_key "onboarding_checklist_items", "documents", column: "last_document_id"
  add_foreign_key "onboarding_checklist_items", "onboarding_checklists"
  add_foreign_key "onboarding_checklist_items", "users", column: "validated_by_user_id"
  add_foreign_key "onboarding_checklists", "accounts"
  add_foreign_key "onboarding_checklists", "clients"
  add_foreign_key "onboarding_checklists", "onboarding_templates"
  add_foreign_key "onboarding_template_items", "onboarding_templates"
  add_foreign_key "onboarding_templates", "accounts"
  add_foreign_key "settings", "accounts"
  add_foreign_key "subscriptions", "accounts"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "upload_invites", "accounts"
  add_foreign_key "upload_invites", "clients"
  add_foreign_key "upload_invites", "users", column: "created_by_user_id"
  add_foreign_key "users", "accounts"
  add_foreign_key "wiki_links", "wiki_pages", column: "source_page_id"
  add_foreign_key "wiki_links", "wiki_pages", column: "target_page_id"
  add_foreign_key "wiki_logs", "accounts"
  add_foreign_key "wiki_pages", "accounts"
  add_foreign_key "wiki_schemas", "accounts"
end
