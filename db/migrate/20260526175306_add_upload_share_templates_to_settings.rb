# frozen_string_literal: true

class AddUploadShareTemplatesToSettings < ActiveRecord::Migration[8.0]
  WHATSAPP_DEFAULT = "Olá! Envie seus documentos de {{nome_cliente}} pelo link: {{link}}"
  EMAIL_SUBJECT_DEFAULT = "Envio de documentos — {{nome_cliente}}"
  EMAIL_BODY_DEFAULT = <<~TEXT.strip
    Olá,

    Por favor, envie os documentos de {{nome_cliente}} referentes à competência {{competencia}} pelo link abaixo:

    {{link}}

    Obrigado.
  TEXT

  def up
    add_column :settings, :upload_share_whatsapp_template, :text
    add_column :settings, :upload_share_email_subject_template, :string
    add_column :settings, :upload_share_email_body_template, :text

    backfill_defaults

    change_column_null :settings, :upload_share_whatsapp_template, false
    change_column_null :settings, :upload_share_email_subject_template, false
    change_column_null :settings, :upload_share_email_body_template, false
  end

  def down
    remove_column :settings, :upload_share_whatsapp_template
    remove_column :settings, :upload_share_email_subject_template
    remove_column :settings, :upload_share_email_body_template
  end

  private

  def backfill_defaults
    whatsapp = connection.quote(WHATSAPP_DEFAULT)
    subject = connection.quote(EMAIL_SUBJECT_DEFAULT)
    body = connection.quote(EMAIL_BODY_DEFAULT)

    execute <<-SQL.squish
      UPDATE settings
      SET upload_share_whatsapp_template = #{whatsapp},
          upload_share_email_subject_template = #{subject},
          upload_share_email_body_template = #{body}
    SQL
  end
end
