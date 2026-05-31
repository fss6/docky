# frozen_string_literal: true

require "test_helper"

class TaxIdTest < ActiveSupport::TestCase
  test "normalize strips cpf mask" do
    assert_equal "39053344705", TaxId.normalize("390.533.447-05")
  end

  test "normalize uppercase alphanumeric cnpj" do
    assert_equal OnboardingTestHelper::VALID_TEST_ALPHANUMERIC_CNPJ,
                 TaxId.normalize("12.abc.345/01de-35")
  end

  test "format masks cpf and cnpj" do
    assert_equal "390.533.447-05", TaxId.format("39053344705")
    assert_equal "19.131.243/0001-97", TaxId.format("19131243000197")
    assert_equal "12.ABC.345/01DE-35", TaxId.format(OnboardingTestHelper::VALID_TEST_ALPHANUMERIC_CNPJ)
  end

  test "valid numeric cnpj" do
    assert TaxId.valid?("19131243000197")
    assert TaxId.valid?("19.131.243/0001-97")
  end

  test "valid alphanumeric cnpj" do
    assert TaxId.valid?(OnboardingTestHelper::VALID_TEST_ALPHANUMERIC_CNPJ)
  end

  test "rejects invalid alphanumeric cnpj checksum" do
    assert_not TaxId.valid?("12ABC34501DE99")
  end

  test "rejects letters in cpf length" do
    assert_not TaxId.valid?("3905334470A")
  end
end
