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
  # パブリック GET はコントローラー側で set_cdn_cacheable を呼んで上書きする
  def set_default_cache_control
    response.headers['Cache-Control'] = 'no-store'
  end

  # CDN（Cloudflare等）に5分キャッシュさせるが、ブラウザはキャッシュしない
  # パブリック GET エンドポイントで before_action から呼び出す
  def set_cdn_cacheable
    response.headers['Cache-Control'] = 'public, s-maxage=300, max-age=0'
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
