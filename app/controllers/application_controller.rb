# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  include Devise::Controllers::Helpers

  before_action :set_locale
  before_action :set_default_cache_control

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  private

  def set_locale
    I18n.locale = :ja
  end

  # デフォルトはキャッシュ禁止（認証・変更系エンドポイント向け）
  # パブリック GET はコントローラー側で上書きする
  def set_default_cache_control
    response.headers['Cache-Control'] = 'no-store'
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
