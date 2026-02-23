# frozen_string_literal: true

module Api
  module Auth
    class SessionsController < ApplicationController
      before_action :authenticate_admin!, only: [:destroy]

      def create
        @admin = Admin.find_by(email: session_params[:email])

        if @admin&.valid_password?(session_params[:password])
          request.env['warden'].set_user(@admin, scope: :admin)
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
          jwt_payload = request.env['warden-jwt_auth.token']
          if jwt_payload
            JwtBlacklist.create(
              jti: jwt_payload['jti'],
              exp: Time.at(jwt_payload['exp'])
            )
          end
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
