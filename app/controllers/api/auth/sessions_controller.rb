# frozen_string_literal: true

module Api
  module Auth
    class SessionsController < ApplicationController
      before_action :authenticate_admin!, only: [:destroy]

      def create
        @admin = Admin.find_by(email: session_params[:email])

        if @admin&.valid_password?(session_params[:password])
          sign_in(@admin, store: false)
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
            message: 'Invalid email or password'
          }, status: :unauthorized
        end
      end

      def destroy
        if current_admin
          # devise-jwt の revocation_requests 設定により、
          # DELETE /api/auth/sign_out へのリクエスト時にミドルウェア層で
          # 自動的にトークンがブラックリスト登録される。
          # ここで手動登録すると二重登録になるため、wardenでサインアウトのみ行う。
          request.env['warden'].logout(:admin)
          render json: {
            status: 'success',
            message: 'Logged out successfully'
          }, status: :ok
        else
          render json: {
            status: 'error',
            message: 'Not authenticated'
          }, status: :unauthorized
        end
      end

      private

      def session_params
        params.require(:admin).permit(:email, :password)
      end
    end
  end
end
