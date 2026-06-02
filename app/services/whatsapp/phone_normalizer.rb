# frozen_string_literal: true

module Whatsapp
  class PhoneNormalizer
    def self.normalize(raw)
      new(raw).normalize
    end

    def initialize(raw)
      @raw = raw.to_s
    end

    def normalize
      digits = @raw.gsub(/\D/, "")
      return nil if digits.blank?

      if digits.length == 10 || digits.length == 11
        "55#{digits}"
      else
        digits
      end
    end

    def self.same?(left, right)
      normalize(left) == normalize(right)
    end
  end
end
