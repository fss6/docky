# frozen_string_literal: true

module EnvHelper
  def with_env(vars)
    previous = {}
    vars.each do |key, value|
      previous[key] = ENV.key?(key) ? ENV[key] : :missing
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
    yield
  ensure
    previous.each do |key, value|
      if value == :missing
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end
end

ActiveSupport::TestCase.include(EnvHelper)
