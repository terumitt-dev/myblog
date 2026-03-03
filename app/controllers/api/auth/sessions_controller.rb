# frozen_string_literal: true

module Api
  module Auth
    class SessionsController < ApplicationController
      def create
        # Devise標準の認証フローを使用
        @admin = Admin.find_by(email: session_params[:email])

        if @admin&.valid_password?(session_params[:password])
          # Deviseの制約チェック（lockable, confirmable等）を考慮
          if @admin.active_for_authentication?
            sign_in(:admin, @admin, store: false)
            render json: {
              status: 'success',
              message: 'Logged in successfully',
              data: {
                id: @admin.id,
                email: @admin.email
              }
            }, status: :ok
          else
            render json: {
              status: 'error',
              message: @admin.inactive_message
            }, status: :unauthorized
          end
        else
          render json: {
            status: 'error',
            message: 'Invalid email or password'
          }, status: :unauthorized
        end
      end

      def destroy
        # JWTが付与されている場合のみ認証を走らせ、revocation middlewareに必要な情報をセットする
        # （未認証でも200を返すidempotent設計は維持）
        warden.authenticate(scope: :admin) if request.headers['Authorization'].present?

        warden.logout(:admin)
        render json: {
          status: 'success',
          message: 'Logged out successfully'
        }, status: :ok
      end

      private

      def session_params
        params.require(:admin).permit(:email, :password)
      end
    end
  end
end
