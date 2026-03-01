# frozen_string_literal: true

Devise.setup do |config|
  config.jwt do |jwt|
    # JWT専用の秘密鍵を使用（secret_key_baseとは分離）
    # 全環境で jwt.secret_key または JWT_SECRET_KEY を必須化
    # credentials優先、ENV['JWT_SECRET_KEY']をフォールバックとして許可
    jwt_secret = Rails.application.credentials.dig(:jwt, :secret_key) || ENV['JWT_SECRET_KEY']
    
    if jwt_secret.blank?
      raise 'JWT secret key is not configured. Please set jwt.secret_key in credentials or JWT_SECRET_KEY environment variable.'
    end
    
    jwt.secret = jwt_secret
    jwt.dispatch_requests = [
      ['POST', %r{^/api/auth/sign_in$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/auth/sign_out$}]
    ]
    jwt.expiration_time = 1.hour.to_i
  end
end
