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
      def create
        unless valid_secret?(params[:secret])
          render json: { error: 'Invalid secret' }, status: :unauthorized
          return
        end

        # singleton 前提が崩れている場合（0件 or 複数件）は誤送信を避けるため明示的にエラー
        # Admin モデルは only_one_admin_allowed でバリデーションしているが、
        # データ不整合に備えて二重チェック
        admins = Admin.limit(2).to_a
        if admins.empty?
          render json: { error: 'Admin not found' }, status: :not_found
          return
        end
        if admins.size > 1
          Rails.logger.error('Unexpected multiple admins found for password reset')
          render json: { error: 'Admin configuration error' }, status: :internal_server_error
          return
        end

        admin = admins.first

        begin
          admin.send_reset_password_instructions
          render json: { message: 'Password reset email sent' }, status: :ok
        rescue StandardError => e
          # SMTP 認証失敗・タイムアウト等でメール送信に失敗した場合
          Rails.logger.error("Failed to send password reset email: #{e.class}: #{e.message}")
          render json: { error: 'Failed to send email' }, status: :internal_server_error
        end
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
