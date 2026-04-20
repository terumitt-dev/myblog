# frozen_string_literal: true

# Rack::Attack レートリミット設定
# パスワードリセット等のセンシティブエンドポイントへの総当たり攻撃を防止
class Rack::Attack
  # 実クライアントIPを取得
  # K8s Ingress/ALB/Cloudflare を経由すると req.ip はプロキシIPを返すため、
  # X-Forwarded-For ヘッダーの先頭（最も元のクライアント側）を使用する
  def self.client_ip(req)
    req.env['HTTP_X_FORWARDED_FOR']&.split(',')&.first&.strip || req.ip
  end

  # パスワードリセット要求（SECRET 検証）: 同一IPから1時間に5回まで
  # - SECRET のブルートフォースを抑制
  # - メール爆撃の二重防御
  throttle('password_reset/ip', limit: 5, period: 1.hour) do |req|
    client_ip(req) if req.path == '/api/auth/password' && req.post?
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
