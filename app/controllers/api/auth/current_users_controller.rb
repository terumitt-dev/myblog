# frozen_string_literal: true

module Api
  module Auth
    class CurrentUsersController < ApplicationController
      before_action :set_devise_mapping
      before_action :authenticate_admin!

      def show
        render json: {
          status: 'success',
          data: {
            id: current_admin.id,
            email: current_admin.email
          }
        }, status: :ok
      end

      private

      def set_devise_mapping
        request.env['devise.mapping'] = Devise.mappings[:admin]
      end
    end
  end
end
