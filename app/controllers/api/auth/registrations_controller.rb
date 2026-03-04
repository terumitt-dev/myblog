# frozen_string_literal: true

module Api
  module Auth
    class RegistrationsController < ApplicationController
      def create
        # 管理者登録用パスワードの検証
        signup_password = params[:signup_password].to_s
        expected_password =
          Rails.application.credentials.dig(:admin_signup, :password) || ENV['ADMIN_SIGNUP_PASSWORD']

        if expected_password.blank?
          return render json: {
            status: 'error',
            message: 'Admin signup is not configured'
          }, status: :forbidden
        end

        valid_signup_password =
          signup_password.bytesize == expected_password.bytesize &&
          ActiveSupport::SecurityUtils.secure_compare(signup_password, expected_password)

        unless valid_signup_password
          return render json: {
            status: 'error',
            message: 'Invalid signup password'
          }, status: :forbidden
        end

        @admin = Admin.new(admin_params)

        if @admin.save
          # 登録成功。ログインはクライアント側でsign_inエンドポイントを呼ぶ設計とする。
          # sign_up直後の自動ログイン（warden.set_user）は行わない：
          # dispatch_requestsの対象外のパスでJWTが発行されない可能性があり、
          # クライアント側の期待と不一致になるリスクがあるため。
          render json: {
            status: 'success',
            message: 'Admin registered successfully. Please sign in.',
            data: {
              id: @admin.id,
              email: @admin.email
            }
          }, status: :created
        else
          render json: {
            status: 'error',
            message: 'Registration failed',
            errors: @admin.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def admin_params
        params.require(:admin).permit(:email, :password, :password_confirmation)
      end
    end
  end
end
