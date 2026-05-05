# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Myblog
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # API モードを有効化
    config.api_only = true

    # Rack::Attack をミドルウェアに追加（レートリミット）
    config.middleware.use Rack::Attack

    # 日本語をデフォルトのlocaleに設定
    config.i18n.default_locale = :ja

    # 利用可能なlocalesを設定
    config.i18n.available_locales = %i[ja en]

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
    config.time_zone = 'Tokyo'
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
