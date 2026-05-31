# frozen_string_literal: true

module TestTaxIds
  def valid_test_client_email
    "client-#{SecureRandom.hex(5)}@example.com"
  end

  def unique_valid_test_tax_id(account:)
    raise ArgumentError, "account is required" if account.blank?

    used = Client.where(account: account).pluck(:tax_id).to_set
    100.times do |attempt|
      seed = Zlib.crc32("#{account.id}-#{Process.pid}-#{Thread.current.object_id}-#{attempt}")
      candidate = generate_valid_cpf(seed)
      return candidate unless used.include?(candidate)
    end

    raise "Could not generate unique test tax_id for account #{account.id}"
  end

  def generate_valid_cpf(seed)
    base = format("%09d", seed % 1_000_000_000)
    base = "123456789" if base.chars.uniq.length == 1

    first_digit = cpf_check_digit(base, [10, 9, 8, 7, 6, 5, 4, 3, 2])
    second_digit = cpf_check_digit("#{base}#{first_digit}", [11, 10, 9, 8, 7, 6, 5, 4, 3, 2])
    "#{base}#{first_digit}#{second_digit}"
  end

  def cpf_check_digit(body, weights)
    sum = body.chars.each_with_index.sum { |digit, index| digit.to_i * weights[index] }
    remainder = sum % 11
    remainder < 2 ? 0 : 11 - remainder
  end
end
