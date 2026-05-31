# frozen_string_literal: true

class LinkOnboardingToTemplates < ActiveRecord::Migration[8.0]
  KIND_MAP = {
    "new_client" => "new_company",
    "migration" => "migration"
  }.freeze

  def up
    add_column :onboarding_templates, :description, :text

    add_reference :clients, :onboarding_template, foreign_key: true, index: true
    add_reference :onboarding_checklists, :onboarding_template, foreign_key: true, index: true

    migrate_onboarding_kinds!

    remove_column :clients, :onboarding_kind, :string
    remove_column :onboarding_checklists, :onboarding_kind, :string
  end

  def down
    add_column :clients, :onboarding_kind, :string
    add_column :onboarding_checklists, :onboarding_kind, :string, null: false, default: "new_client"

    Client.reset_column_information
    OnboardingChecklist.reset_column_information
    OnboardingTemplate.reset_column_information

    Client.find_each do |client|
      next if client.onboarding_template_id.blank?

      kind = client.read_attribute(:onboarding_template_id) &&
        OnboardingTemplate.find_by(id: client.onboarding_template_id)&.kind
      onboarding_kind = reverse_kind(kind, client)
      client.update_columns(onboarding_kind: onboarding_kind)
    end

    OnboardingChecklist.find_each do |checklist|
      next if checklist.onboarding_template_id.blank?

      kind = OnboardingTemplate.find_by(id: checklist.onboarding_template_id)&.kind
      onboarding_kind = kind == "migration" ? "migration" : "new_client"
      checklist.update_columns(onboarding_kind: onboarding_kind)
    end

    remove_reference :onboarding_checklists, :onboarding_template, foreign_key: true
    remove_reference :clients, :onboarding_template, foreign_key: true
    remove_column :onboarding_templates, :description, :text
  end

  private

  def migrate_onboarding_kinds!
    Client.reset_column_information
    OnboardingChecklist.reset_column_information

    Client.find_each do |client|
      template_id = resolve_template_id(
        account_id: client.account_id,
        onboarding_kind: client.onboarding_kind,
        skipped: client.onboarding_kind == "skipped" || (client.onboarding_kind.blank? && client.status == "active")
      )
      client.update_columns(onboarding_template_id: template_id) if template_id || client.onboarding_kind == "skipped"
    end

    OnboardingChecklist.find_each do |checklist|
      template_id = resolve_template_id(
        account_id: checklist.account_id,
        onboarding_kind: checklist.onboarding_kind
      )
      next if template_id.blank?

      checklist.update_columns(onboarding_template_id: template_id)
    end
  end

  def resolve_template_id(account_id:, onboarding_kind:, skipped: false)
    return nil if skipped

    template_kind = KIND_MAP.fetch(onboarding_kind.to_s, "new_company")
    OnboardingTemplate.find_by(account_id: account_id, kind: template_kind)&.id
  end

  def reverse_kind(template_kind, client)
    return "skipped" if client.onboarding_template_id.blank? && client.status == "active"

    template_kind == "migration" ? "migration" : "new_client"
  end
end
