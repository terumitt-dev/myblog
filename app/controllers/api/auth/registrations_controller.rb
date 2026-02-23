# frozen_string_literal: true

module Api
  module Auth
    class RegistrationsController < ApplicationController
      def create
        @admin = Admin.new(admin_params)

        if @admin.save
          request.env['warden'].set_user(@admin, scope: :admin)
          render json: {
            status: 'success',
            message: 'Admin registered successfully',
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
