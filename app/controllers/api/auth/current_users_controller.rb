# frozen_string_literal: true

module Api
  module Auth
    class CurrentUsersController < ApplicationController
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
    end
  end
end
