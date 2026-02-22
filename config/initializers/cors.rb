# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:5173', 'localhost:3000', '127.0.0.1:5173', '127.0.0.1:3000'
    resource '*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options],
             credentials: true,
             max_age: 3600
  end

  allow do
    origins 'go-lilaregard.com', 'www.go-lilaregard.com'
    resource '*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options],
             credentials: true,
             max_age: 3600
  end
end
