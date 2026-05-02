# frozen_string_literal: true

# Rack::Attack レートリミット設定
# パスワードリセット等のセンシティブエンドポイントへの総当たり攻撃を防止
#
# カウンタは Rails.cache (本番では SolidCache) に保存することで、
# 複数 Puma worker / 複数 Pod 構成でもプロセスをまたいで共有される。
# プロセスローカルな MemoryStore のままだと password_reset/global などの
# 全体スロットリングがプロセスごとに分断され、実質的に Pod 数 × worker 数倍の
# 回数を通せてしまう。本番ではこの設定漏れを起動時に fail-fast で検知する。
if Rails.env.production? && Rails.cache.is_a?(ActiveSupport::Cache::MemoryStore)
  raise 'Rack::Attack requires a shared cache store in production ' \
        '(set config.cache_store to :solid_cache_store or another shared backend)'
end

Rack::Attack.cache.store = Rails.cache

class Rack::Attack
  # 実クライアントIPを取得
  # ActionDispatch::Request#remote_ip は Rails の trusted_proxies 設定を
  # 考慮して安全にクライアントIPを返すため、XFFの偽装攻撃にも対応できる。
  # 不正な X-Forwarded-For ヘッダで例外化するケースがあるため、
  # その場合は REMOTE_ADDR (実コネクションIP) にフォールバックする。
  # req.ip だと XFF 由来の偽装値を再利用する余地があるため避ける。
  # 例外を上に伝えると 500 になり DoS の踏み台になるためフォールバックは必須。
  def self.client_ip(req)
    ActionDispatch::Request.new(req.env).remote_ip.to_s
  rescue StandardError
    req.get_header('REMOTE_ADDR').to_s
  end

  # /api/auth/password と /api/auth/password.json などのフォーマット付き URL を
  # 同一エンドポイントとして判定する。req.path の完全一致だと、Rails のルーティングが
  # 暗黙に許す .json 等のフォーマット拡張で rate limit を回避されうるため。
  PASSWORD_ENDPOINT = %r{\A/api/auth/password(?:\.[^/]+)?/?\z}.freeze

  def self.password_endpoint?(req)
    req.path.match?(PASSWORD_ENDPOINT)
  end

  # パスワードリセット要求（SECRET 検証）: 同一IPから1時間に5回まで
  # - SECRET のブルートフォースを抑制
  # - メール爆撃の二重防御
  throttle('password_reset/ip', limit: 5, period: 1.hour) do |req|
    client_ip(req) if password_endpoint?(req) && req.post?
  end

  # パスワードリセット要求（全体）: 1時間に20回まで
  # - 分散IP攻撃による admin へのメール爆撃を防止
  # - 正規ユーザー（admin 1人）に対する影響はゼロに等しい
  throttle('password_reset/global', limit: 20, period: 1.hour) do |req|
    'password_reset' if password_endpoint?(req) && req.post?
  end

  # パスワードリセット実行（トークン検証）: 同一IPから1時間に10回まで
  # Devise のトークンは十分長いが多層防御として追加
  throttle('password_reset_update/ip', limit: 10, period: 1.hour) do |req|
    client_ip(req) if password_endpoint?(req) && req.patch?
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
