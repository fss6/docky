# frozen_string_literal: true

require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "requires name" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(name: "   ", tax_id: "39053344705", email: "test@example.com")
      assert_not c.valid?
    end
  end

  test "requires tax_id" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(name: "Cliente Teste", tax_id: "", email: "test@example.com")
      assert_not c.valid?
      assert_includes c.errors[:tax_id], "Informe o CNPJ ou CPF"
    end
  end

  test "requires email" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(name: "Cliente Teste", tax_id: "39053344705", email: "")
      assert_not c.valid?
      assert_includes c.errors[:email], "Informe o e-mail do responsável"
    end
  end

  test "rejects invalid email" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(name: "Cliente Teste", tax_id: "39053344705", email: "invalido")
      assert_not c.valid?
      assert_includes c.errors[:email], "E-mail inválido"
    end
  end

  test "accepts valid email" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(name: "Cliente Teste", tax_id: "52998224725", email: "contato@empresa.com")
      assert c.valid?
    end
  end

  test "normalizes cpf tax_id to digits only" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(name: "Cliente Teste", tax_id: "390.533.447-05", email: "test@example.com")
      c.valid?
      assert_equal "39053344705", c.tax_id
    end
  end

  test "normalizes alphanumeric cnpj to uppercase without mask" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(
        name: "Empresa Alfa",
        tax_id: "12.abc.345/01de-35",
        email: "alfa@example.com"
      )
      c.valid?
      assert_equal OnboardingTestHelper::VALID_TEST_ALPHANUMERIC_CNPJ, c.tax_id
    end
  end

  test "rejects alphanumeric cnpj with invalid checksum" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(
        name: "Empresa Inválida",
        tax_id: "12ABC34501DE99",
        email: "invalida@example.com"
      )
      assert_not c.valid?
      assert_includes c.errors[:tax_id], "CNPJ ou CPF inválido"
    end
  end

  test "rejects invalid tax_id" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(name: "Cliente Teste", tax_id: "12345678901", email: "test@example.com")
      assert_not c.valid?
      assert_includes c.errors[:tax_id], "CNPJ ou CPF inválido"
    end
  end

  test "kept scope excludes archived clients" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alpha = clients(:alpha)
      alpha.update!(archived_at: Time.current, archived_by_user: users(:owner))

      assert_includes Client.kept, clients(:beta)
      assert_not_includes Client.kept, alpha
    end
  end

  test "filtered_by_index_params searches name email and tax_id" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alpha = clients(:alpha)
      beta = clients(:beta)

      results = Client.filtered_by_index_params({ q: "Alpha" })
      assert_includes results, alpha
      assert_not_includes results, beta

      results = Client.filtered_by_index_params({ q: "19131243000197" })
      assert_includes results, alpha
      assert_not_includes results, beta

      results = Client.filtered_by_index_params({ q: "alpha@example.com" })
      assert_includes results, alpha
      assert_not_includes results, beta
    end
  end

  test "filtered_by_index_params searches alphanumeric cnpj fragment" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alfa = Client.create!(
        account: accounts(:one),
        name: "Empresa Alfanumérica",
        tax_id: OnboardingTestHelper::VALID_TEST_ALPHANUMERIC_CNPJ,
        email: "alfanumerica@example.com"
      )

      results = Client.filtered_by_index_params({ q: "12abc" })
      assert_includes results, alfa
      assert_not_includes results, clients(:beta)
    end
  end

  test "filtered_by_index_params includes archived clients" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alpha = clients(:alpha)
      alpha.update!(archived_at: Time.current, archived_by_user: users(:owner))

      results = Client.filtered_by_index_params({})
      assert_includes results, alpha
      assert_includes results, clients(:beta)
    end
  end

  test "filtered_by_index_params status active excludes archived clients" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alpha = clients(:alpha)
      alpha.update!(archived_at: Time.current, archived_by_user: users(:owner), status: :active)

      results = Client.filtered_by_index_params({ status: "active" })
      assert_not_includes results, alpha
      assert_includes results, clients(:beta)
    end
  end
end
