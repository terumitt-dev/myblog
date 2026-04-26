# frozen_string_literal: true

module Api
  module Auth
    # パスワードリセット用コントローラー
    # Admin は singleton（1人のみ）の設計のため、
    # - Email 入力を省略し、ボタン1つでリセット要求できる
    # - ただし誰でもメール送信をトリガーできると爆撃されるため、
    #   PASSWORD_RESET_SECRET 環境変数で保護する
    class PasswordsController < ApplicationController
      # SECRET を検証して OK ならリセットメールを送信
      # POST /api/auth/password
      # Body: { "secret": "..." }
      #
      # セキュリティ方針: SECRET の正誤・Admin 不存在・SMTP 失敗のいずれも
      # 同じレスポンス（202 Accepted）を返す。これにより攻撃者が応答の差分から
      # SECRET やシステム状態を推測する「オラクル攻撃」を防ぐ。
      # 内部エラーはログのみに残す。
      def create
        # クエリ文字列経由で secret を渡されると URL / アクセスログ / Referer 経由で
        # 漏えいする経路が残る。リクエストボディ (JSON / form) からのみ受け付ける。
        secret = request.request_parameters['secret']
        if valid_secret?(secret)
          # singleton 前提が崩れている場合はログのみで握り潰し、レスポンスは統一
          admins = Admin.limit(2).to_a
          if admins.one?
            begin
              admins.first.send_reset_password_instructions
            rescue StandardError => e
              # SMTP 失敗等もレスポンスには反映させずログのみ
              Rails.logger.error("Failed to send password reset email: #{e.class}: #{e.message}")
            end
          else
            Rails.logger.error("Unexpected admin count for password reset: #{admins.size}")
          end
        end

        render json: { message: 'If the request was accepted, a password reset email will be sent' },
               status: :accepted
      end

      # リセットトークンで新しいパスワードを設定
      # PATCH /api/auth/password
      # Body: { "reset_password_token": "...", "password": "...", "password_confirmation": "..." }
      def update
        admin = Admin.reset_password_by_token(reset_params)

        if admin.errors.empty?
          render json: { message: 'Password updated successfully' }, status: :ok
        else
          render json: { errors: admin.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def valid_secret?(input)
        expected = ENV['PASSWORD_RESET_SECRET']
        return false if expected.blank? || input.blank?

        ActiveSupport::SecurityUtils.secure_compare(input.to_s, expected)
      end

      def reset_params
        params.permit(:reset_password_token, :password, :password_confirmation)
      end
    end
  end
end
