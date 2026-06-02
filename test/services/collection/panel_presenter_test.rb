# frozen_string_literal: true

require "test_helper"

module Collection
  class PanelPresenterTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:one)
      @client = clients(:alpha)
      ActsAsTenant.current_tenant = @account
      CollectionSetting.ensure_for!(@account)
      Collection::SeedDefaultSteps.call(account: @account)
    end

    test "returns one row per open period with pending items" do
      may = create_open_period!(month: Date.new(2026, 5, 1))
      june = create_open_period!(month: Date.new(2026, 6, 1))
      add_pending_item!(may, "Extrato maio")
      add_pending_item!(june, "NF junho")

      rows = PanelPresenter.call(account: @account)[:rows]

      assert_equal 2, rows.size
      assert_equal [may.id, june.id].sort, rows.map { |r| r.period_record.id }.sort
    end

    test "sorts by days_offset descending" do
      travel_to Date.new(2026, 6, 15) do
        @client.update!(monthly_deadline_day: 10)
        old_period = create_open_period!(month: Date.new(2026, 4, 1))
        recent_period = create_open_period!(month: Date.new(2026, 6, 1))
        add_pending_item!(old_period, "Antigo")
        add_pending_item!(recent_period, "Recente")

        rows = PanelPresenter.call(account: @account)[:rows]

        assert rows.first.days_offset >= rows.last.days_offset
        assert_equal old_period.id, rows.first.period_record.id
      end
    end

    test "filters by status late" do
      travel_to Date.new(2026, 6, 15) do
        @client.update!(monthly_deadline_day: 10)
        late_period = create_open_period!(month: Date.new(2026, 4, 1))
        soon_period = create_open_period!(month: Date.new(2026, 8, 1))
        add_pending_item!(late_period, "Atraso")
        add_pending_item!(soon_period, "Futuro")

        rows = PanelPresenter.call(account: @account, status: "late")[:rows]

        assert_equal 1, rows.size
        assert_predicate rows.first.days_offset, :positive?
      end
    end

    test "on_track counts clients without any pending open period" do
      travel_to Date.new(2026, 6, 15) do
        may = create_open_period!(month: Date.new(2026, 5, 1))
        add_pending_item!(may, "Pendente")

        kpis = PanelPresenter.call(account: @account)[:kpis]
        active_count = @account.clients.kept.where(status: :active).count
        clients_with_pending = 1

        assert_equal active_count - clients_with_pending, kpis[:on_track]
      end
    end

    private

    def create_open_period!(month:)
      Period.create!(
        account: @account,
        client: @client,
        period: month.beginning_of_month,
        status: :open,
        opened_at: Time.current
      )
    end

    def add_pending_item!(period_record, name)
      period_record.items.create!(
        name_snapshot: name,
        match_terms: [name.downcase],
        state: :pending
      )
    end
  end
end
