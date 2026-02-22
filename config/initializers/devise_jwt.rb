# frozen_string_literal: true

Devise.setup do |config|
  config.jwt do |jwt|
    jwt.secret = Rails.application.secret_key_base
    jwt.dispatch_requests = [
      ['POST', %r{^/api/auth/sign_in$}],
      ['POST', %r{^/api/auth/sign_up$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/auth/sign_out$}]
    ]
    jwt.expiration_time = 1.hour.to_i
  end
end
