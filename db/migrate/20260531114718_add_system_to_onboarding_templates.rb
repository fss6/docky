# frozen_string_literal: true

class AddSystemToOnboardingTemplates < ActiveRecord::Migration[8.0]
  def up
    add_column :onboarding_templates, :system, :boolean, null: false, default: false

    execute <<~SQL.squish
      UPDATE onboarding_templates
      SET system = true
      WHERE kind IN ('mei', 'new_company', 'migration')
    SQL
  end

  def down
    remove_column :onboarding_templates, :system
  end
end
