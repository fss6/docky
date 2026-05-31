# frozen_string_literal: true

module TaxIdValidatable
  extend ActiveSupport::Concern

  included do
    validate :tax_id_must_be_valid_cpf_or_cnpj
  end

  class_methods do
    def valid_tax_id?(value)
      TaxId.valid?(value)
    end

    def digits_only(str)
      TaxId.normalize(str)
    end
  end

  private

  def tax_id_must_be_valid_cpf_or_cnpj
    return if tax_id.blank?

    normalized = TaxId.normalize(tax_id)
    unless TaxId.cpf?(normalized) || TaxId.cnpj?(normalized)
      errors.add(:tax_id, :invalid_format)
      return
    end

    return if TaxId.valid?(normalized)

    errors.add(:tax_id, :invalid)
  end
end
