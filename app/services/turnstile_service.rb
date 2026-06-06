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

  # ENV.fetch は未設定だけ弾くので blank? でガードしてからフリーズ
  # (空文字 "TURNSTILE_SECRET_KEY=" で渡された場合に boot 時に気付くため)。
  SECRET_KEY = ENV.fetch('TURNSTILE_SECRET_KEY').tap do |value|
    raise 'TURNSTILE_SECRET_KEY must not be blank' if value.blank?
  end.freeze

  # siteverify 応答の `hostname` を照合する allow-list (カンマ区切り)。
  # Cloudflare 側で site key は domain に紐付くため一次防御は済んでいるが、
  # site key 漏洩 + 別ホストへの差し替えなどの edge case に備えた多層防御。
  # 未設定 (空 list) の場合はチェックをスキップする (dev / test 用途)。
  ALLOWED_HOSTNAMES = ENV.fetch('TURNSTILE_ALLOWED_HOSTNAMES', '')
                        .split(',').map(&:strip).reject(&:blank?).freeze

  # @param token [String, nil] フォームから submit された Turnstile token
  # @param remote_ip [String, nil] 検証対象のクライアント IP (任意・推奨)
  # @return [Boolean]
  def self.verify(token, remote_ip: nil)
    return false if token.blank?

    response = post_siteverify(token, remote_ip)
    return false unless response.is_a?(Net::HTTPSuccess)

    result = JSON.parse(response.body)
    return false unless result['success'] == true
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
