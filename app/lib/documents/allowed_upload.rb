# frozen_string_literal: true

module Documents
  module AllowedUpload
    EXTENSIONS = %w[pdf xml jpg jpeg png doc docx xls xlsx].freeze

    CONTENT_TYPES = %w[
      application/pdf
      application/xml
      text/xml
      image/jpeg
      image/png
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/vnd.ms-excel
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    ].freeze

    GENERIC_CONTENT_TYPES = %w[application/octet-stream binary/octet-stream].freeze

    CLIENT_FACING_LABEL = "PDF, XML, imagens (JPG, PNG) e arquivos Word e Excel."

    module_function

    def allowed?(uploaded_file)
      return false if uploaded_file.blank?

      filename = extract_filename(uploaded_file)
      content_type = extract_content_type(uploaded_file)

      extension_allowed?(filename) && content_type_allowed?(content_type)
    end

    def allowed_blob?(blob)
      return false if blob.blank?

      extension_allowed?(blob.filename.to_s) && content_type_allowed?(blob.content_type.to_s)
    end

    def accept_attribute
      extension_tokens = EXTENSIONS.uniq.map { |ext| ".#{ext}" }
      (extension_tokens + CONTENT_TYPES).join(",")
    end

    def client_facing_label
      CLIENT_FACING_LABEL
    end

    def validation_error_message
      "Formato não aceito. Envie #{CLIENT_FACING_LABEL.chomp('.')}."
    end

    def extension_allowed?(filename)
      extension = File.extname(filename.to_s).delete_prefix(".").downcase
      EXTENSIONS.include?(extension)
    end

    def content_type_allowed?(content_type)
      normalized = content_type.to_s.downcase.split(";").first.to_s.strip
      return true if CONTENT_TYPES.include?(normalized)
      return true if GENERIC_CONTENT_TYPES.include?(normalized)

      false
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
