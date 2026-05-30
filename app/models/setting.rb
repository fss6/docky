# frozen_string_literal: true

# == Schema Information
#
# Table name: settings
#
#  id                                      :bigint           not null, primary key
#  generate_tags_automatically             :boolean          default(TRUE), not null
#  onboarding_share_email_body_template    :text
#  onboarding_share_email_subject_template :string
#  onboarding_share_whatsapp_template      :text
#  upload_share_email_body_template        :text             not null
#  upload_share_email_subject_template     :string           not null
#  upload_share_whatsapp_template          :text             not null
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  account_id                              :bigint           not null
#
# Indexes
#
#  index_settings_on_account_id  (account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Setting < ApplicationRecord
  LINK_PLACEHOLDER = "{{link}}"

  DEFAULT_UPLOAD_SHARE_WHATSAPP_TEMPLATE = "Olá! Precisamos dos documentos da empresa {{nome_cliente}} referentes à competência {{competencia}}. Envie por aqui: #{LINK_PLACEHOLDER}"
  DEFAULT_UPLOAD_SHARE_EMAIL_SUBJECT_TEMPLATE = "Envio de documentos — {{nome_cliente}}"
  DEFAULT_UPLOAD_SHARE_EMAIL_BODY_TEMPLATE = <<~TEXT.strip
    Olá,

    Precisamos receber os documentos da empresa {{nome_cliente}} referentes à competência {{competencia}}.

    #{LINK_PLACEHOLDER}
  TEXT

  DEFAULT_ONBOARDING_SHARE_WHATSAPP_TEMPLATE = "Olá! Para concluir a abertura da conta de {{nome_cliente}}, envie os documentos pelo link: #{LINK_PLACEHOLDER} (progresso: {{progresso}})"
  DEFAULT_ONBOARDING_SHARE_EMAIL_SUBJECT_TEMPLATE = "Documentos iniciais — {{nome_cliente}}"
  DEFAULT_ONBOARDING_SHARE_EMAIL_BODY_TEMPLATE = <<~TEXT.strip
    Olá,

    Para concluir a configuração da conta de {{nome_cliente}}, envie os documentos iniciais.

    #{LINK_PLACEHOLDER}

    Progresso atual: {{progresso}}

    Obrigado.
  TEXT

  belongs_to :account

  validates :upload_share_whatsapp_template, presence: true, length: { maximum: 2000 }
  validates :upload_share_email_subject_template, presence: true, length: { maximum: 500 }
  validates :upload_share_email_body_template, presence: true, length: { maximum: 2000 }
  validates :onboarding_share_whatsapp_template, presence: true, length: { maximum: 2000 }
  validates :onboarding_share_email_subject_template, presence: true, length: { maximum: 500 }
  validates :onboarding_share_email_body_template, presence: true, length: { maximum: 2000 }
  validate :upload_share_templates_include_link_placeholder
  validate :onboarding_share_templates_include_link_placeholder

  after_initialize :apply_upload_share_defaults, if: :new_record?
  after_initialize :apply_onboarding_share_defaults, if: :new_record?

  def self.upload_share_defaults
    {
      whatsapp: DEFAULT_UPLOAD_SHARE_WHATSAPP_TEMPLATE,
      email_subject: DEFAULT_UPLOAD_SHARE_EMAIL_SUBJECT_TEMPLATE,
      email_body: DEFAULT_UPLOAD_SHARE_EMAIL_BODY_TEMPLATE
    }
  end

  def self.onboarding_share_defaults
    {
      whatsapp: DEFAULT_ONBOARDING_SHARE_WHATSAPP_TEMPLATE,
      email_subject: DEFAULT_ONBOARDING_SHARE_EMAIL_SUBJECT_TEMPLATE,
      email_body: DEFAULT_ONBOARDING_SHARE_EMAIL_BODY_TEMPLATE
    }
  end

  private

  def apply_upload_share_defaults
    self.upload_share_whatsapp_template ||= DEFAULT_UPLOAD_SHARE_WHATSAPP_TEMPLATE
    self.upload_share_email_subject_template ||= DEFAULT_UPLOAD_SHARE_EMAIL_SUBJECT_TEMPLATE
    self.upload_share_email_body_template ||= DEFAULT_UPLOAD_SHARE_EMAIL_BODY_TEMPLATE
  end

  def apply_onboarding_share_defaults
    self.onboarding_share_whatsapp_template ||= DEFAULT_ONBOARDING_SHARE_WHATSAPP_TEMPLATE
    self.onboarding_share_email_subject_template ||= DEFAULT_ONBOARDING_SHARE_EMAIL_SUBJECT_TEMPLATE
    self.onboarding_share_email_body_template ||= DEFAULT_ONBOARDING_SHARE_EMAIL_BODY_TEMPLATE
  end

  def upload_share_templates_include_link_placeholder
    %i[upload_share_whatsapp_template upload_share_email_body_template].each do |attr|
      value = self[attr].to_s
      next if value.blank?

      errors.add(attr, "deve incluir #{LINK_PLACEHOLDER}") unless value.include?(LINK_PLACEHOLDER)
    end
  end

  def onboarding_share_templates_include_link_placeholder
    %i[onboarding_share_whatsapp_template onboarding_share_email_body_template].each do |attr|
      value = self[attr].to_s
      next if value.blank?

      errors.add(attr, "deve incluir #{LINK_PLACEHOLDER}") unless value.include?(LINK_PLACEHOLDER)
    end
  end
end
