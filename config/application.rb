# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require 'action_mailbox/engine'
# require 'action_text/engine'
require 'action_view/railtie'
# require 'action_cable/engine'
require 'sprockets/railtie'

# custom
require_relative '../lib/capture_error'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Yeti
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # changing defaults
    Rails.application.config.action_view.default_enforce_utf8 = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    #    config.time_zone = ENV['YETI_TZ'] || 'UTC'
    if !ENV['YETI_TZ'].nil?
      config.time_zone = ENV['YETI_TZ']
    else
      begin
        file = File.open('/etc/timezone', 'r')
        data = file.read
        file.close
        config.time_zone = data.delete!("\n")
      rescue StandardError
        config.time_zone = 'UTC'
      end
    end

    active_record_tz = ENV.fetch('YETI_PG_TZ', :utc).to_sym
    config.active_record.default_timezone = active_record_tz

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    config.active_record.schema_migrations_table_name = 'public.schema_migrations'

    # Controls which database schemas will be dumped when calling db:structure:dump.
    config.active_record.dump_schemas = :all

    config.action_mailer.delivery_method = :smtp

    config.action_mailer.smtp_settings = {
      address: 'smtp.yeti-switch.org',
      port: 25,
      enable_starttls_auto: true,
      openssl_verify_mode: 'none'
    }
    config.action_mailer.default_options = {
      from: 'instance@yeti-switch.org',
      to: 'backtrace@yeti-switch.org'
    }

    config.active_job.queue_adapter = :delayed_job

    # Use RSpec for testing
    config.generators do |g|
      g.test_framework :rspec
      g.integration_tool :rspec
    end
  end
end
