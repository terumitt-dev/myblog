# frozen_string_literal: true

Devise.setup do |config|
  config.jwt do |jwt|
    # JWT専用の秘密鍵を使用（secret_key_baseとは分離）
    # 本番環境では必ずJWT_SECRET_KEYを設定すること
    # 開発環境: rails secretで生成した値を.envに設定
    # 本番環境: 環境変数またはRails credentialsで管理
    jwt.secret = ENV.fetch('JWT_SECRET_KEY') { Rails.application.secret_key_base }
    jwt.dispatch_requests = [
      ['POST', %r{^/api/auth/sign_in$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/auth/sign_out$}]
    ]
    jwt.expiration_time = 1.hour.to_i
  end
end
