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

        admin = Admin.first
        unless admin
          render json: { error: 'Admin not found' }, status: :not_found
          return
        end

        admin.send_reset_password_instructions
        render json: { message: 'Password reset email sent' }, status: :ok
      end

      # リセットトークンで新しいパスワードを設定
      # PUT /api/auth/password
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
