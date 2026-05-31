# frozen_string_literal: true

module TaxIdValidatable
  extend ActiveSupport::Concern

  included do
    validate :tax_id_must_be_valid_cpf_or_cnpj
  end

  class_methods do
    def valid_tax_id?(value)
      digits = digits_only(value)
      return false if digits.blank?

      cpf?(digits) ? valid_cpf?(digits) : cnpj?(digits) ? valid_cnpj?(digits) : false
    end

    def digits_only(str)
      str.to_s.gsub(/\D/, "")
    end

    def cpf?(digits)
      digits.length == 11
    end

    def cnpj?(digits)
      digits.length == 14
    end

    def valid_cpf?(digits)
      return false unless cpf?(digits)
      return false if digits.chars.uniq.length == 1

      verify_cpf_check_digits(digits)
    end

    def valid_cnpj?(digits)
      return false unless cnpj?(digits)
      return false if digits.chars.uniq.length == 1

      verify_cnpj_check_digits(digits)
    end

    def verify_cpf_check_digits(digits)
      first_weights = [10, 9, 8, 7, 6, 5, 4, 3, 2]
      second_weights = [11, 10, 9, 8, 7, 6, 5, 4, 3, 2]

      first_sum = digits.chars.first(9).each_with_index.sum { |d, i| d.to_i * first_weights[i] }
      first_remainder = first_sum % 11
      first_digit = first_remainder < 2 ? 0 : 11 - first_remainder

      second_sum = digits.chars.first(10).each_with_index.sum { |d, i| d.to_i * second_weights[i] }
      second_remainder = second_sum % 11
      second_digit = second_remainder < 2 ? 0 : 11 - second_remainder

      digits[9].to_i == first_digit && digits[10].to_i == second_digit
    end

    def verify_cnpj_check_digits(digits)
      first_weights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      second_weights = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

      first_sum = digits.chars.first(12).each_with_index.sum { |d, i| d.to_i * first_weights[i] }
      first_remainder = first_sum % 11
      first_digit = first_remainder < 2 ? 0 : 11 - first_remainder

      second_sum = digits.chars.first(13).each_with_index.sum { |d, i| d.to_i * second_weights[i] }
      second_remainder = second_sum % 11
      second_digit = second_remainder < 2 ? 0 : 11 - second_remainder

      digits[12].to_i == first_digit && digits[13].to_i == second_digit
    end
  end

  private

  def tax_id_must_be_valid_cpf_or_cnpj
    return if tax_id.blank?

    digits = self.class.digits_only(tax_id)
    unless self.class.cpf?(digits) || self.class.cnpj?(digits)
      errors.add(:tax_id, :invalid_format)
      return
    end

    return if self.class.valid_tax_id?(digits)

    errors.add(:tax_id, :invalid)
  end
end
