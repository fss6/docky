# frozen_string_literal: true

require "digest"

module Documents
  module ContentFingerprint
    CHUNK = 64.kilobytes

    module_function

    def sha256_hex(io)
      digest = Digest::SHA256.new
      while (chunk = io.read(CHUNK))
        digest << chunk
      end
      digest.hexdigest
    end

    def from_upload(uploaded_file)
      io = uploaded_file.respond_to?(:tempfile) ? uploaded_file.tempfile : uploaded_file
      io.rewind
      sha256_hex(io).tap { io.rewind }
    end

    def from_blob(blob)
      blob.open { |io| sha256_hex(io) }
    end
  end
end
