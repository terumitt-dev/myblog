# frozen_string_literal: true

# Rack::Attack レートリミット設定
# パスワードリセット等のセンシティブエンドポイントへの総当たり攻撃を防止
class Rack::Attack
  # パスワードリセット要求: 同一IPから1時間に5回まで
  # - SECRET のブルートフォースを抑制
  # - メール爆撃の二重防御
  throttle('password_reset/ip', limit: 5, period: 1.hour) do |req|
    req.ip if req.path == '/api/auth/password' && req.post?
  end

  # レートリミット超過時のレスポンス
  self.throttled_responder = lambda do |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{ error: 'Too many requests. Please try again later.' }.to_json]
    ]
  end
end
