# frozen_string_literal: true

module PeriodFormatting
  module_function

  def display_label(period)
    date = parse_period(period).beginning_of_month
    month_name = I18n.l(date, format: "%B")
    "#{month_name.capitalize}/#{date.year}"
  end

  def picker_value(period)
    date = parse_period(period).beginning_of_month
    "#{date.year}/#{format('%02d', date.month)}"
  end

  def parse_period(period)
    case period
    when String
      Date.strptime(period, "%Y-%m")
    else
      period.to_date
    end
  end
end
