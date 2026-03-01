# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # 環境ごとに許可オリジンを分離
  allowed_origins = if Rails.env.production?
    # 本番環境: 本番ドメインのみ許可
    ['https://go-lilaregard.com', 'https://www.go-lilaregard.com']
  else
    # 開発/テスト環境: ローカルホストを許可
    ['http://localhost:5173', 'http://localhost:3000', 'http://127.0.0.1:5173', 'http://127.0.0.1:3000']
  end

  allow do
    origins(*allowed_origins)
    resource '*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options],
             expose: ['Authorization'],
             max_age: 3600
  end
end
