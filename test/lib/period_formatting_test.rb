# frozen_string_literal: true

require "test_helper"

class PeriodFormattingTest < ActiveSupport::TestCase
  def setup_fixtures
  end

  def teardown_fixtures
  end

  test "display_label formats date as month/year" do
    assert_equal "Maio/2026", PeriodFormatting.display_label(Date.new(2026, 5, 15))
  end

  test "display_label accepts YYYY-MM string" do
    assert_equal "Maio/2026", PeriodFormatting.display_label("2026-05")
  end

  test "picker_value uses Y/m for flatpickr" do
    assert_equal "2026/05", PeriodFormatting.picker_value(Date.new(2026, 5, 1))
  end
end
