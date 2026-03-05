# frozen_string_literal: true

module Api
  module Auth
    class SessionsController < ApplicationController
      before_action :set_devise_mapping

      def create
        request.env['devise.allow_params_authentication'] = true

        # 入力をここで確定（adminキー欠如時はParameterMissing→400）
        params[:admin] = session_params

        admin = warden.authenticate!(scope: :admin, store: false)
        sign_in(:admin, admin, store: false)

        render json: {
          status: 'success',
          message: 'Logged in successfully',
          data: {
            id: admin.id,
            email: admin.email
          }
        }, status: :ok
      end

      def destroy
        # JWTが付与されている場合のみ認証を走らせ、revocation middlewareに必要な情報をセットする
        # （未認証でも200を返すidempotent設計は維持）
        if request.headers['Authorization'].present?
          begin
            admin = warden.authenticate(:jwt, scope: :admin)
            sign_out(:admin) if admin
          rescue StandardError => e
            Rails.logger.warn("[api/auth/sign_out] logout failed: #{e.class}: #{e.message}")
          end
        end

        render json: {
          status: 'success',
          message: 'Logged out successfully'
        }, status: :ok
      end

      private

      def set_devise_mapping
        request.env['devise.mapping'] = Devise.mappings[:admin]
      end

      def session_params
        params.require(:admin).permit(:email, :password)
      end
    end
  end
end
