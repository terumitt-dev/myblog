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
    # 永続キュー実装のみを allow-list で許可する。
    # deny-list 方式 (forbidden = %i[async inline]) だと :test など想定外の
    # 非永続アダプタがすり抜ける余地があるため、Rack::Attack の cache 判定や
    # SOLID_QUEUE_IN_PUMA の真偽値判定と同じく allow-list で固める方針。
    #
    # 許可するアダプタは「Pod 再起動を跨いでジョブが永続化され、deliver_later が
    # 確実に処理される」ものに限定する。新規アダプタ追加時はここに足す運用を取る。
    # - :solid_queue → 本リポジトリで採用、Postgres 永続化
    # - :sidekiq    → Redis 永続化、業界標準
    # - :resque     → Redis 永続化
    # - :delayed_job → DB 永続化
    # - :good_job   → Postgres 永続化
    #
    # `Rails.application.config.active_job.queue_adapter` の戻り値はシンボル指定なら
    # シンボル、文字列指定なら文字列、インスタンス/クラス指定ならそのオブジェクトを
    # 返すため、`.to_sym` がインスタンス/クラスで NoMethodError を起こす経路がある。
    # `ActiveJob::Base.queue_adapter_name` は Rails が resolve 後の正規化済みアダプタ名
    # (常に String) を返す canonical API なので、設定方法に依らず安定して判定できる。
    adapter = ActiveJob::Base.queue_adapter_name.to_sym
    allowed = %i[solid_queue sidekiq resque delayed_job good_job]

    unless allowed.include?(adapter)
      raise "Configure a durable async Active Job adapter before deploying to production. " \
            "Got: #{adapter.inspect} (allowed: #{allowed.inspect})"
    end
  end
end
