require_relative "boot"

require "rails/all"

# Audited gem compatibility fix
# Compatibilidade temporaria para gems que ainda chamam
# `belongs_to_required_by_default` no Rails 8.
if defined?(ActiveRecord::Base) &&
   ActiveRecord::Base.respond_to?(:belongs_to_required_by_default?) &&
   !ActiveRecord::Base.respond_to?(:belongs_to_required_by_default)
  class << ActiveRecord::Base
    def belongs_to_required_by_default
      belongs_to_required_by_default?
    end
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dokivo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.active_record.yaml_column_permitted_classes = [
      Symbol,
      Date,
      Time,
      DateTime,
      ActiveSupport::TimeWithZone,
      BigDecimal
    ]

    config.i18n.available_locales = [ :"pt-BR", :en ]
    config.i18n.default_locale = :"pt-BR"
    # Devise ships en-only; use English strings when a pt-BR key is missing.
    config.i18n.fallbacks = { :"pt-BR" => [ :en ] }
  end
end
