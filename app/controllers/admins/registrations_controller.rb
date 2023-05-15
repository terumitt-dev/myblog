# frozen_string_literal: true

module Admins
  class RegistrationsController < Devise::RegistrationsController
    before_action :check_registration_limit, only: %i[new create]

    protected

    def check_registration_limit
      if Admin.count >= 1
        redirect_to root_path, alert: 'Only one admin allowed'
      end
    end
  end
end
