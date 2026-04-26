# frozen_string_literal: true

# Rack::Attack レートリミット設定
# パスワードリセット等のセンシティブエンドポイントへの総当たり攻撃を防止
class Rack::Attack
  # 実クライアントIPを取得
  # ActionDispatch::Request#remote_ip は Rails の trusted_proxies 設定を
  # 考慮して安全にクライアントIPを返すため、XFFの偽装攻撃にも対応できる。
  # 不正な X-Forwarded-For ヘッダで例外化するケースがあるため、
  # その場合は req.ip にフォールバックしてレートリミット処理は継続させる
  # （例外を上に伝えると 500 になり DoS の踏み台になる）。
  def self.client_ip(req)
    ActionDispatch::Request.new(req.env).remote_ip.to_s
  rescue StandardError
    req.ip.to_s
  end

  # パスワードリセット要求（SECRET 検証）: 同一IPから1時間に5回まで
  # - SECRET のブルートフォースを抑制
  # - メール爆撃の二重防御
  throttle('password_reset/ip', limit: 5, period: 1.hour) do |req|
    client_ip(req) if req.path == '/api/auth/password' && req.post?
  end

  # パスワードリセット要求（全体）: 1時間に20回まで
  # - 分散IP攻撃による admin へのメール爆撃を防止
  # - 正規ユーザー（admin 1人）に対する影響はゼロに等しい
  throttle('password_reset/global', limit: 20, period: 1.hour) do |req|
    'password_reset' if req.path == '/api/auth/password' && req.post?
  end

  # パスワードリセット実行（トークン検証）: 同一IPから1時間に10回まで
  # Devise のトークンは十分長いが多層防御として追加
  throttle('password_reset_update/ip', limit: 10, period: 1.hour) do |req|
    client_ip(req) if req.path == '/api/auth/password' && req.patch?
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
