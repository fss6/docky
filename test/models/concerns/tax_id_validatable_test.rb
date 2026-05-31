# frozen_string_literal: true

require "test_helper"

class TaxIdValidatableTest < ActiveSupport::TestCase
  test "validates known cpf" do
    assert Client.valid_tax_id?("39053344705")
    assert Client.valid_tax_id?("390.533.447-05")
  end

  test "validates known cnpj" do
    assert Client.valid_tax_id?("19131243000197")
    assert Client.valid_tax_id?("19.131.243/0001-97")
  end

  test "validates alphanumeric cnpj" do
    assert Client.valid_tax_id?(OnboardingTestHelper::VALID_TEST_ALPHANUMERIC_CNPJ)
    assert Client.valid_tax_id?("12.abc.345/01de-35")
  end

  test "rejects invalid cpf checksum" do
    assert_not Client.valid_tax_id?("39053344706")
  end

  test "rejects invalid cnpj checksum" do
    assert_not Client.valid_tax_id?("19131243000198")
    assert_not Client.valid_tax_id?("12ABC34501DE99")
  end

  test "rejects repeated digits" do
    assert_not Client.valid_tax_id?("11111111111")
    assert_not Client.valid_tax_id?("11111111111111")
  end

  test "rejects invalid format" do
    assert_not Client.valid_tax_id?("12ABC34501DEXX")
  end
end
