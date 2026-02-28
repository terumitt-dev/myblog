# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*ALLOWED_ORIGINS)
    resource '*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options],
             expose: ['Authorization'],
             max_age: 3600
  end
end
