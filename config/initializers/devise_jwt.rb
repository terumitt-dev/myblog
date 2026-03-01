# frozen_string_literal: true

Devise.setup do |config|
  config.jwt do |jwt|
    # JWT専用の秘密鍵を使用（secret_key_baseとは分離）
    # 優先順位: 1. Rails Credentials 2. 環境変数 3. secret_key_base（開発用）
    # 本番環境: rails credentials:edit で jwt.secret_key を設定
    # 開発環境: フォールバックでsecret_key_baseを使用
    jwt.secret = Rails.application.credentials.dig(:jwt, :secret_key) ||
                 ENV.fetch('JWT_SECRET_KEY') { Rails.application.secret_key_base }
    jwt.dispatch_requests = [
      ['POST', %r{^/api/auth/sign_in$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/auth/sign_out$}]
    ]
    jwt.expiration_time = 1.hour.to_i
  end
end
