# frozen_string_literal: true

module Api
  module Auth
    class RegistrationsController < ApplicationController
      def create
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
