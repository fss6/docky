# frozen_string_literal: true

require_relative "seeds/clients"

# Dados mínimos só em desenvolvimento (idempotente).
if Rails.env.development?
  plan = Plan.find_or_initialize_by(name: "Desenvolvimento")
  plan.assign_attributes(price: 0, status: "active")
  plan.save!

  account = Account.find_or_initialize_by(name: "Conta de desenvolvimento")
  account.assign_attributes(plan: plan, active: true)
  account.save!
  Institution.seed_defaults_for!(account)

  ActsAsTenant.with_tenant(account) do
    user = User.find_or_initialize_by(email: "dev@dev.com")
    user.assign_attributes(
      account: account,
      name: "Developer",
      role: :owner,
      active: true
    )
    if user.new_record?
      user.password = "dev@dev.com"
      user.password_confirmation = "dev@dev.com"
    end
    user.save!

    client = Client.find_or_initialize_by(account: account, name: "Pão de Forma LTDA")
    client.assign_attributes(
      tax_id: "12345678901234",
      email: "contato@paodeforma.test"
    )
    client.save!
  end

  puts <<~MSG
    [seeds:dev] Plano: #{plan.name.inspect} (id=#{plan.id})
    [seeds:dev] Conta: #{account.name.inspect} (id=#{account.id})
    [seeds:dev] Utilizador: dev@dev.com / dev@dev.com (owner)
    [seeds:dev] Cliente: "Pão de Forma LTDA"
  MSG

  Seeds::Clients.run!
end
