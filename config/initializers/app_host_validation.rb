# frozen_string_literal: true

# APP_HOST はパスワードリセットメールのリンク生成や SMTP の HELO/EHLO ドメインに使われるため、
# 「ホスト名のみ（例: go-lilaregard.com）」を期待する。
# スキーム (https://...) やパス、末尾スラッシュが混ざると default_url_options[:host] や
# smtp_settings[:domain] に不正な値が入り、リセットリンク生成や Gmail 接続が壊れる。
#
# K8s Secret 経由で値が来るため、入力ミスを起動時に fail-fast で検知する。
# 本番のみ強制（test/dev 環境ではダミー値や未設定もありうるため緩め）。
# top-level `return` は Ruby/Rails initializer 上で動作はするが、
# 将来の Ruby で deprecation 候補になる可能性があるため if/end で囲む形を採用。
if Rails.env.production?
  app_host = ENV.fetch('APP_HOST', nil)
  if app_host.blank?
    raise 'APP_HOST is required in production'
  elsif app_host.match?(%r{\Ahttps?://}i) || app_host.include?('/')
    raise <<~MSG
      APP_HOST must be hostname only (no scheme or path).
      Got: #{app_host.inspect}
      Expected example: "go-lilaregard.com"
    MSG
  end
end
