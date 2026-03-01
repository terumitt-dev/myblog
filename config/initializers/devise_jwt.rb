# frozen_string_literal: true

Devise.setup do |config|
  config.jwt do |jwt|
    # JWT専用の秘密鍵を使用（secret_key_baseとは分離）
    # 本番環境: rails credentials:edit で jwt.secret_key を設定済み
    # 開発/テスト環境: フォールバックでsecret_key_baseを使用
    jwt_secret = Rails.application.credentials.dig(:jwt, :secret_key) || ENV['JWT_SECRET_KEY']
    
    if Rails.env.production? && jwt_secret.blank?
      raise 'JWT secret key is not configured. Please set jwt.secret_key in credentials or JWT_SECRET_KEY environment variable.'
    end
    
    jwt.secret = jwt_secret || Rails.application.secret_key_base
    jwt.dispatch_requests = [
      ['POST', %r{^/api/auth/sign_in$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/auth/sign_out$}]
    ]
    jwt.expiration_time = 1.hour.to_i
  end
end
