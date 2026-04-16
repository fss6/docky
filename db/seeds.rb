# frozen_string_literal: true

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
  end

  puts <<~MSG
    [seeds:dev] Plano: #{plan.name.inspect} (id=#{plan.id})
    [seeds:dev] Conta: #{account.name.inspect} (id=#{account.id})
    [seeds:dev] Utilizador: dev@dev.com / dev@dev.com (owner)
  MSG
end
