# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

# Cloudflare Turnstile token verifier.
# コメントフォームから送られた token を Cloudflare の siteverify API で検証し、
# bot / spam を k8s 到達前にフィルタする目的。
#
# 設計方針:
# - SECRET_KEY をクラス読み込み時に ENV.fetch で必須化することで、
#   デプロイ時の設定漏れを起動時に fail-fast で検知する (silent failure を防ぐため)。
#   この仕様は全環境共通で、未設定なら起動失敗 (環境分岐は意図的に持たせない)。
# - 例外時は false を返して fail-closed (検証できない以上は弾く)。
#
# 環境別の TURNSTILE_SECRET_KEY 注入経路 (コード外で別途設定):
# - production: app-secrets Secret (Drone CI が SSM 経由で kubectl apply)
# - development: docker-compose.yml で Cloudflare 公開テストキーを env として注入
#                (1x0000000000000000000000000000000AA, always pass)
# - test: spec/rails_helper.rb で `ENV[...] ||= 'test-turnstile-secret'`
class TurnstileService
  SITEVERIFY_URL = URI('https://challenges.cloudflare.com/turnstile/v0/siteverify').freeze
  TIMEOUT = 5

  # Cloudflare Turnstile token のサイズ上限 (公式仕様 ~2048 chars)。
  # 公開エンドポイント経由で過大な値を Cloudflare へ転送する増幅攻撃を防ぐため、
  # 型と byte size を事前検証する。
  MAX_TOKEN_BYTESIZE = 2048

  # Cloudflare が公開しているテスト用 secret key (公式ドキュメントに掲載)。
  #   1x...AA: 常に検証成功 (dev / test の標準キー)
  #   2x...AA: 常に検証失敗 (失敗シナリオの確認用)
  #   3x...FF: 常に spent-token エラー (再利用シナリオの確認用)
  # https://developers.cloudflare.com/turnstile/troubleshooting/testing/
  # docker-compose.yml に always-pass の値が直書きされている関係上、
  # 設定ミスで本番にコピペされる可能性が現実的にあるため、
  # boot 時に本番デプロイを fail-fast で弾く。
  PUBLIC_TEST_SECRET_KEYS = %w[
    1x0000000000000000000000000000000AA
    2x0000000000000000000000000000000AA
    3x0000000000000000000000000000000FF
  ].freeze

  # SECRET_KEY 検証 (boot-time fail-fast)。
  # - 空文字 / 未設定: 全環境共通で raise (silent failure 防止)
  # - 本番 + Cloudflare 公開テストキー: raise (誤デプロイで Turnstile 検証が
  #   実質バイパスされる事故を防ぐ)
  # テスト可能にするため private class method として切り出している。
  def self.validate_secret_key!(value)
    raise 'TURNSTILE_SECRET_KEY must not be blank' if value.blank?
    return unless Rails.env.production? && PUBLIC_TEST_SECRET_KEYS.include?(value)

    raise 'TURNSTILE_SECRET_KEY must not be a public test key in production'
  end
  private_class_method :validate_secret_key!

  SECRET_KEY = ENV.fetch('TURNSTILE_SECRET_KEY').tap { |value| validate_secret_key!(value) }.freeze

  # 本番環境で TURNSTILE_ALLOWED_HOSTNAMES が空なら boot 時に raise する。
  # 設定漏れの silent な hostname 検証無効化を防ぎ、デプロイ時の CrashLoopBackOff
  # で即異常検知できるようにする (SECRET_KEY と同じ fail-fast パターン)。
  # テスト可能にするため private class method として切り出している。
  def self.validate_allowed_hostnames!(raw_value)
    return unless Rails.env.production? && raw_value.blank?

    raise 'TURNSTILE_ALLOWED_HOSTNAMES must not be blank in production'
  end
  private_class_method :validate_allowed_hostnames!

  # siteverify 応答の `hostname` を照合する allow-list (カンマ区切り)。
  # Cloudflare 側で site key は domain に紐付くため一次防御は済んでいるが、
  # site key 漏洩 + 別ホストへの差し替えなどの edge case に備えた多層防御。
  # 未設定 (空 list) の場合は dev / test に限定 (本番は上記 fail-fast で除外)。
  raw_allowed_hostnames = ENV.fetch('TURNSTILE_ALLOWED_HOSTNAMES', '')
  validate_allowed_hostnames!(raw_allowed_hostnames)
  ALLOWED_HOSTNAMES = raw_allowed_hostnames
                        .split(',').map(&:strip).reject(&:blank?).freeze

  # @param token [String, nil] フォームから submit された Turnstile token
  # @param remote_ip [String, nil] 検証対象のクライアント IP (任意・推奨)
  # @return [Boolean]
  def self.verify(token, remote_ip: nil)
    return false unless token.is_a?(String)
    return false if token.blank? || token.bytesize > MAX_TOKEN_BYTESIZE

    response = post_siteverify(token, remote_ip)
    return false unless response.is_a?(Net::HTTPSuccess)

    result = JSON.parse(response.body)
    return false unless result['success'] == true
    # ALLOWED_HOSTNAMES が空なのは dev / test に限られる (本番は boot 時 fail-fast)。
    # その場合は hostname を見ずに success のみで判定する。
    return true if ALLOWED_HOSTNAMES.empty?

    ALLOWED_HOSTNAMES.include?(result['hostname'])
  rescue StandardError => e
    Rails.logger.warn "TurnstileService: verify failed: #{e.message}"
    false
  end

  def self.post_siteverify(token, remote_ip)
    params = { secret: SECRET_KEY, response: token }
    params[:remoteip] = remote_ip if remote_ip.present?

    http = Net::HTTP.new(SITEVERIFY_URL.host, SITEVERIFY_URL.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT
    http.write_timeout = TIMEOUT

    request = Net::HTTP::Post.new(SITEVERIFY_URL.request_uri)
    request.set_form_data(params)
    http.request(request)
  end
  private_class_method :post_siteverify
end
