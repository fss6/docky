# frozen_string_literal: true

class TaxId
  CNPJ_FORMAT = /\A[0-9A-Z]{12}\d{2}\z/
  CPF_FORMAT = /\A\d{11}\z/
  MASK_CHARS = /[.\/\-\s]/i

  class << self
    def normalize(value)
      raw = value.to_s.gsub(MASK_CHARS, "").upcase
      return "" if raw.blank?

      if cpf_candidate?(raw)
        raw.gsub(/\D/, "")
      else
        raw.gsub(/[^0-9A-Z]/, "")
      end
    end

    def cpf?(normalized)
      normalized.present? && normalized.match?(CPF_FORMAT)
    end

    def cnpj?(normalized)
      normalized.present? && normalized.match?(CNPJ_FORMAT)
    end

    def valid?(value)
      normalized = normalize(value)
      return false if normalized.blank?

      cpf?(normalized) ? valid_cpf?(normalized) : cnpj?(normalized) ? valid_cnpj?(normalized) : false
    end

    def format(value)
      normalized = normalize(value)
      return "—" if normalized.blank?

      if cpf?(normalized)
        normalized.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4')
      elsif cnpj?(normalized)
        normalized.gsub(/([0-9A-Z]{2})([0-9A-Z]{3})([0-9A-Z]{3})([0-9A-Z]{4})(\d{2})/, '\1.\2.\3/\4-\5')
      else
        normalized
      end
    end

    def search_normalize(term)
      raw = term.to_s.gsub(MASK_CHARS, "").upcase
      return "" if raw.blank?

      if raw.match?(/\A\d+\z/) && raw.length <= 11
        raw.gsub(/\D/, "")
      else
        raw.gsub(/[^0-9A-Z]/, "")
      end
    end

    def cnpj_char_value(char)
      char.ord - 48
    end

    def valid_cpf?(normalized)
      return false unless cpf?(normalized)
      return false if normalized.chars.uniq.length == 1

      verify_cpf_check_digits(normalized)
    end

    def valid_cnpj?(normalized)
      return false unless cnpj?(normalized)
      return false if normalized.chars.uniq.length == 1

      verify_cnpj_check_digits(normalized)
    end

    def verify_cpf_check_digits(digits)
      first_weights = [10, 9, 8, 7, 6, 5, 4, 3, 2]
      second_weights = [11, 10, 9, 8, 7, 6, 5, 4, 3, 2]

      first_sum = digits.chars.first(9).each_with_index.sum { |d, i| d.to_i * first_weights[i] }
      first_digit = check_digit_from_remainder(first_sum % 11)

      second_sum = digits.chars.first(10).each_with_index.sum { |d, i| d.to_i * second_weights[i] }
      second_digit = check_digit_from_remainder(second_sum % 11)

      digits[9].to_i == first_digit && digits[10].to_i == second_digit
    end

    def verify_cnpj_check_digits(normalized)
      first_weights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      second_weights = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

      first_sum = normalized.chars.first(12).each_with_index.sum { |char, i| cnpj_char_value(char) * first_weights[i] }
      first_digit = check_digit_from_remainder(first_sum % 11)

      second_sum = normalized.chars.first(13).each_with_index.sum { |char, i| cnpj_char_value(char) * second_weights[i] }
      second_digit = check_digit_from_remainder(second_sum % 11)

      normalized[12].to_i == first_digit && normalized[13].to_i == second_digit
    end

    private

    def cpf_candidate?(raw)
      raw.match?(/\A\d+\z/) && raw.length <= 11
    end

    def check_digit_from_remainder(remainder)
      remainder < 2 ? 0 : 11 - remainder
    end
  end
end
