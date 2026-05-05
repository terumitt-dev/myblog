# frozen_string_literal: true

# パスワードリセット要求の処理を非同期化するためのジョブ。
#
# 役割:
# - PasswordsController#create が valid/invalid いずれの secret でも同じ work
#   (このジョブの enqueue) を行うことで、controller の応答時間を完全に揃える
# - 実際にトークン発行 + メール送信を行うかどうかは send_reset フラグで分岐
#
# 設計上の前提:
# - admin_id は controller 側で limit(2) して 1 件のみだった場合のみ渡される。
#   それ以外は nil を渡す (件数異常時はジョブ側で何もしない統一動作)
# - send_reset = false 時はジョブ側で即 return。invalid secret や singleton 崩壊時の no-op パス
class PasswordResetRequestJob < ApplicationJob
  queue_as :default

  def perform(admin_id:, send_reset:)
    return unless send_reset
    return if admin_id.nil?

    # ::Admin と明示するのは passwords_controller.rb と同じ理由
    # (Api::Admin namespace 衝突回避)。ジョブクラスは namespace 衝突しないが、
    # 一貫性と将来の移動耐性のため明示する。
    admin = ::Admin.find_by(id: admin_id)

    # admin_id 付きでこの分岐に到達するのは「controller で admins.one? を確認した
    # 直後にもかかわらず、ジョブ実行時点で admin が消えている」異常状態。
    # singleton 設計上ほぼ起き得ないが、起きた場合に「ジョブが何もせず終わった」を
    # 後から追跡できないと運用で詰まるためログを残す。
    # passwords_controller.rb の "Unexpected admin count" ログと同じ防御パターン。
    unless admin
      Rails.logger.error("PasswordResetRequestJob: admin not found (id=#{admin_id})")
      return
    end

    # send_reset_password_instructions は内部で:
    # 1. set_reset_password_token (DB UPDATE で token + sent_at を保存)
    # 2. send_devise_notification (Admin#send_devise_notification override で deliver_later)
    # の2段で動く。1 の DB UPDATE はこのジョブ内で同期実行されるが、
    # controller のリクエスト処理時間からは切り離されているため、
    # 応答時間オラクルには寄与しない。
    admin.send_reset_password_instructions
  end
end
