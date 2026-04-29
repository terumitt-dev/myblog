# frozen_string_literal: true

# 本番環境で ActiveJob の queue_adapter が :async (in-process / 非永続) のままだと、
# Pod 再起動でジョブが消失して「リセット申請したのにメール届かない」事故になる。
# boot 時に fail-fast で検知して、永続キュー (SolidQueue 等) の設定漏れを防ぐ。
#
# Admin#send_devise_notification 内に同等のチェックを置くと、
# PasswordsController#create の rescue StandardError に飲み込まれて
# 「ログだけ残して 202 を返す」silent fail になるため initializer で boot 時に止める。
if Rails.env.production?
  Rails.application.config.after_initialize do
    if Rails.application.config.active_job.queue_adapter.to_sym == :async
      raise 'Configure a durable Active Job adapter (e.g. SolidQueue) before deploying to production'
    end
  end
end
