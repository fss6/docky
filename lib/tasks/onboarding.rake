# frozen_string_literal: true

namespace :onboarding do
  desc "Seed default onboarding templates for all accounts"
  task seed_templates: :environment do
    Account.find_each do |account|
      Onboarding::SeedDefaultTemplates.call(account: account)
      puts "Seeded onboarding templates for account #{account.id}"
    end
  end

  desc "Backfill onboarding share message defaults on settings"
  task backfill_settings: :environment do
    Setting.find_each do |setting|
      setting.send(:apply_onboarding_share_defaults) if setting.onboarding_share_whatsapp_template.blank?
      setting.save!(validate: false) if setting.changed?
    end
    puts "Backfilled onboarding share settings"
  end
end
