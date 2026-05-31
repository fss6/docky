# frozen_string_literal: true

module AccountProfilesHelper
  def account_initials(account)
    parts = account.name.to_s.split(/\s+/).reject(&:blank?).first(2)
    parts.map { |part| part[0] }.join.upcase.presence || "?"
  end

  def account_logo(account, size: :sm)
    size_class = size == :lg ? "account-logo--lg" : "account-logo--sm"
    base_class = "account-logo #{size_class}"

    if account_logo_displayable?(account)
      image_tag account.logo,
                alt: "",
                class: "#{base_class} object-cover",
                aria: { hidden: true }
    else
      tag.div account_initials(account), class: base_class, aria: { hidden: true }
    end
  end

  def account_logo_displayable?(account)
    account.logo.attached? && account.logo.blob&.persisted?
  end

  def client_facing_account_logo(account, size: :sm)
    size_class = size == :lg ? "client-brand-logo--lg" : "client-brand-logo--sm"
    base_class = "client-brand-logo #{size_class}"

    if account_logo_displayable?(account)
      image_tag account.logo,
                alt: account.name,
                class: "#{base_class} object-contain"
    else
      image_tag "/brand/logo.svg",
                alt: "Dokivo",
                class: "#{base_class} opacity-70"
    end
  end

  def subscription_status_label(subscription)
    return t("account_profiles.subscription.none") if subscription.blank?

    I18n.t("activerecord.enums.subscription.status.#{subscription.status}", default: subscription.status.humanize)
  end
end
