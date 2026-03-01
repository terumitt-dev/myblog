# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  include Devise::Controllers::Helpers

  before_action :set_locale

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  private

  def set_locale
    I18n.locale = :ja
  end

  def record_not_found(exception)
    render json: {
      status: 'error',
      message: 'Record not found'
    }, status: :not_found
  end

  def parameter_missing(exception)
    render json: {
      status: 'error',
      message: "Missing parameter: #{exception.param}"
    }, status: :bad_request
  end
end
