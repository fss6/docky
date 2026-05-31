# frozen_string_literal: true

module ProfilesHelper
  def user_initials(user)
    parts = user.name.to_s.split(/\s+/).reject(&:blank?).first(2)
    parts.map { |part| part[0] }.join.upcase.presence || "?"
  end

  def user_avatar(user, size: :sm)
    size_class = size == :lg ? "user-avatar--lg" : "user-avatar--sm"
    base_class = "user-avatar #{size_class}"

    if user_avatar_displayable?(user)
      image_tag user.avatar,
                alt: "",
                class: "#{base_class} object-cover",
                aria: { hidden: true }
    else
      tag.div user_initials(user), class: base_class, aria: { hidden: true }
    end
  end

  def user_avatar_displayable?(user)
    user.avatar.attached? && user.avatar.blob&.persisted?
  end
end
