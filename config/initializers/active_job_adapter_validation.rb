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
    # 非永続/同期実行のアダプタを deny list で拒否する。
    # - :async  → in-process / 非永続 (Pod 再起動で消失)
    # - :inline → 同期実行 (deliver_later の意味が消えて応答時間差オラクルに戻る)
    # 他のアダプタ (:solid_queue, :sidekiq, :resque 等) は永続キュー前提なので許可。
    #
    # `Rails.application.config.active_job.queue_adapter` の戻り値はシンボル指定なら
    # シンボル、文字列指定なら文字列、インスタンス/クラス指定ならそのオブジェクトを
    # 返すため、`.to_sym` がインスタンス/クラスで NoMethodError を起こす経路がある。
    # `ActiveJob::Base.queue_adapter_name` は Rails が resolve 後の正規化済みアダプタ名
    # (常に String) を返す canonical API なので、設定方法に依らず安定して判定できる。
    adapter = ActiveJob::Base.queue_adapter_name.to_sym
    forbidden = %i[async inline]

    if forbidden.include?(adapter)
      raise "Configure a durable async Active Job adapter (e.g. SolidQueue) before deploying to production. Got: #{adapter.inspect}"
    end
  end
end
