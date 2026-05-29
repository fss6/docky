# frozen_string_literal: true

module Seeds
  module Clients
    module_function

    TOTAL_CLIENTS = 50
    ACTIVE_CLIENTS = 30
    ONBOARDING_CLIENTS = TOTAL_CLIENTS - ACTIVE_CLIENTS
    BASE_MONTHLY_ITEMS = [
      "Extrato bancario",
      "Notas fiscais de servico",
      "Notas fiscais de produto",
      "Relatorio de vendas",
      "Comprovantes de despesas",
      "Folha de pagamento",
      "Guia de impostos",
      "Comprovantes de pro-labore"
    ].freeze
    BASE_ONBOARDING_ITEMS = [
      "Contrato social",
      "Cartao CNPJ",
      "Inscricao municipal",
      "Certificado digital",
      "Acesso prefeitura",
      "Acesso gov.br",
      "Dados bancarios da empresa",
      "Documentos dos socios"
    ].freeze
    ONBOARDING_KINDS = Client::ONBOARDING_KINDS.freeze

    def run!(total_clients: TOTAL_CLIENTS)
      ensure_default_plan!
      account = ensure_account!
      seeded_clients = 0
      seeded_onboarding = 0
      seeded_periods = 0
      seeded_invites = 0
      seeded_folders = 0

      ActsAsTenant.with_tenant(account) do
        owner = ensure_owner_user!(account)

        total_clients.times do |index|
          sequence = index + 1
          onboarding = index < ONBOARDING_CLIENTS
          client = upsert_client!(account: account, sequence: sequence, onboarding: onboarding)
          seeded_clients += 1 if client.previous_changes.key?("id")

          seeded_folders += seed_folders_for!(client)
          seed_client_checklist_items_for!(client)
          seeded_periods += seed_periods_for!(client, owner: owner)
          seeded_invites += seed_upload_invites_for!(client, owner: owner)
          seeded_onboarding += seed_onboarding_for!(client) if onboarding
        end
      end

      puts <<~MSG
        [seeds:clients] Account usada: #{account.name.inspect} (id=#{account.id})
        [seeds:clients] Clientes alvo: #{total_clients}
        [seeds:clients] Checklists onboarding criados/garantidos: #{seeded_onboarding}
        [seeds:clients] Pastas criadas: #{seeded_folders}
        [seeds:clients] Competencias criadas: #{seeded_periods}
        [seeds:clients] Convites criados: #{seeded_invites}
      MSG
    end

    def ensure_default_plan!
      plan = Plan.find_or_initialize_by(name: "Plano seed")
      plan.assign_attributes(price: 0, status: "active")
      plan.save!
      plan
    end

    def ensure_account!
      existing_account = Account.first
      return existing_account if existing_account.present?

      Account.create!(
        name: "Conta seed clientes",
        active: true,
        plan: Plan.first || ensure_default_plan!
      )
    end

    def ensure_owner_user!(account)
      user = User.find_or_initialize_by(email: "owner-seed@docfy.test")
      user.assign_attributes(
        account: account,
        name: "Owner Seed",
        role: :owner,
        active: true
      )

      if user.new_record?
        user.password = "owner-seed@docfy.test"
        user.password_confirmation = "owner-seed@docfy.test"
      end

      user.save!
      user
    end

    def upsert_client!(account:, sequence:, onboarding:)
      suffix = format("%02d", sequence)
      tax_id = format("9000000000%04d", sequence)

      client = Client.find_or_initialize_by(account: account, tax_id: tax_id)
      client.assign_attributes(
        name: "Cliente Seed #{suffix} LTDA",
        email: "cliente#{suffix}@seed.docfy.test",
        phone: "+55 11 9#{format('%08d', sequence)}",
        notes: build_notes(sequence: sequence, onboarding: onboarding),
        monthly_deadline_day: (sequence % 28) + 1,
        status: onboarding ? :onboarding : :active,
        onboarding_kind: onboarding ? ONBOARDING_KINDS[sequence % ONBOARDING_KINDS.size] : nil
      )
      client.save!
      client
    end

    def build_notes(sequence:, onboarding:)
      lines = []
      lines << "Cliente seed ##{sequence}"
      lines << (onboarding ? "Status inicial: onboarding" : "Status inicial: active")
      lines << "Canal principal: WhatsApp"
      lines << "Regime tributario: Simples Nacional"
      lines.join("\n")
    end

    def seed_folders_for!(client)
      folders_created = 0
      folder_names = [
        "Recebidos #{Date.current.year}",
        "Fiscal #{Date.current.year}",
        "Financeiro #{Date.current.year}",
        "Documentos societarios"
      ]

      folder_names.each do |folder_name|
        folder = Folder.find_or_initialize_by(account_id: client.account_id, client_id: client.id, name: folder_name)
        folder.visible = true if folder.new_record?
        folders_created += 1 if folder.new_record?
        folder.save!
      end

      folders_created
    end

    def seed_client_checklist_items_for!(client)
      BASE_MONTHLY_ITEMS.each_with_index do |item_name, index|
        item = ClientChecklistItem.find_or_initialize_by(
          account_id: client.account_id,
          client_id: client.id,
          name: item_name
        )
        item.assign_attributes(
          position: index,
          active: true,
          match_terms: [item_name.downcase, "cliente-#{client.id}", "seed"]
        )
        item.save!
      end
    end

    def seed_periods_for!(client, owner:)
      periods_created = 0
      [Date.current.beginning_of_month, 1.month.ago.to_date.beginning_of_month].each do |period_date|
        period = Period.find_or_initialize_by(
          account_id: client.account_id,
          client_id: client.id,
          period: period_date
        )
        periods_created += 1 if period.new_record?
        period.assign_attributes(
          opened_at: period.opened_at || Time.current,
          status: period_date == Date.current.beginning_of_month ? :open : :closed,
          closed_at: (period_date == Date.current.beginning_of_month ? nil : Time.current),
          closed_by_user: (period_date == Date.current.beginning_of_month ? nil : owner)
        )
        period.save!
        seed_competency_items_for!(period, owner: owner)
      end
      periods_created
    end

    def seed_competency_items_for!(period, owner:)
      period.client.client_checklist_items.active_only.each do |template_item|
        item = CompetencyChecklistItem.find_or_initialize_by(
          competency_checklist_id: period.id,
          client_checklist_item_id: template_item.id
        )
        item.assign_attributes(
          name_snapshot: template_item.name,
          state: period.closed? ? :validated : :pending,
          validated_by_user: (period.closed? ? owner : nil),
          validated_at: (period.closed? ? Time.current : nil),
          match_terms: template_item.match_terms
        )
        item.save!
      end
    end

    def seed_upload_invites_for!(client, owner:)
      invites_created = 0

      monthly = UploadInvite.find_or_initialize_by(
        account_id: client.account_id,
        client_id: client.id,
        purpose: :monthly,
        period: Date.current.beginning_of_month
      )
      invites_created += 1 if monthly.new_record?
      monthly.assign_attributes(
        created_by_user: owner,
        expires_at: 15.days.from_now,
        revoked_at: nil
      )
      monthly.save!

      onboarding = UploadInvite.find_or_initialize_by(
        account_id: client.account_id,
        client_id: client.id,
        purpose: :onboarding
      )
      invites_created += 1 if onboarding.new_record?
      onboarding.assign_attributes(
        created_by_user: owner,
        expires_at: 45.days.from_now,
        revoked_at: nil
      )
      onboarding.save!

      invites_created
    end

    def seed_onboarding_for!(client)
      checklist = OnboardingChecklist.find_or_initialize_by(
        account_id: client.account_id,
        client_id: client.id
      )
      checklist.assign_attributes(
        onboarding_kind: client.onboarding_kind || ONBOARDING_KINDS.first,
        status: :in_progress,
        started_at: checklist.started_at || rand(5..40).days.ago
      )
      checklist.save!

      BASE_ONBOARDING_ITEMS.each_with_index do |item_name, index|
        item = OnboardingChecklistItem.find_or_initialize_by(
          onboarding_checklist_id: checklist.id,
          name: item_name
        )
        item.assign_attributes(
          position: index,
          help_text: "Item seed para onboarding do cliente #{client.name}",
          state: (index < 2 ? :received : :pending),
          received_at: (index < 2 ? rand(1..10).days.ago : nil)
        )
        item.save!
      end

      1
    end
  end
end
