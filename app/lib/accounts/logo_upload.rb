# frozen_string_literal: true

module Accounts
  module LogoUpload
    EXTENSIONS = %w[jpg jpeg png webp].freeze

    CONTENT_TYPES = %w[
      image/jpeg
      image/png
      image/webp
    ].freeze

    MAX_SIZE = 2.megabytes

    module_function

    def allowed?(uploaded_file)
      return false if uploaded_file.blank?
      return false unless size_allowed?(uploaded_file)

      filename = extract_filename(uploaded_file)
      content_type = extract_content_type(uploaded_file)

      extension_allowed?(filename) && content_type_allowed?(content_type)
    end

    def allowed_blob?(blob)
      return false if blob.blank?
      return false unless blob.byte_size <= MAX_SIZE

      extension_allowed?(blob.filename.to_s) && content_type_allowed?(blob.content_type.to_s)
    end

    def accept_attribute
      extension_tokens = EXTENSIONS.uniq.map { |ext| ".#{ext}" }
      (extension_tokens + CONTENT_TYPES).join(",")
    end

    def validation_error_message
      I18n.t("account_profiles.errors.logo_invalid")
    end

    def extension_allowed?(filename)
      extension = File.extname(filename.to_s).delete_prefix(".").downcase
      EXTENSIONS.include?(extension)
    end

    def content_type_allowed?(content_type)
      normalized = content_type.to_s.downcase.split(";").first.to_s.strip
      CONTENT_TYPES.include?(normalized)
    end

    def size_allowed?(uploaded_file)
      size = if uploaded_file.respond_to?(:size)
        uploaded_file.size
      elsif uploaded_file.respond_to?(:byte_size)
        uploaded_file.byte_size
      end

      size.present? && size <= MAX_SIZE
    end

    def extract_filename(uploaded_file)
      if uploaded_file.respond_to?(:original_filename)
        uploaded_file.original_filename
      elsif uploaded_file.respond_to?(:filename)
        uploaded_file.filename
      else
        ""
      end
    end

    def extract_content_type(uploaded_file)
      uploaded_file.content_type if uploaded_file.respond_to?(:content_type)
    end
  end
end
