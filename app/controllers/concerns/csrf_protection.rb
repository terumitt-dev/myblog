# frozen_string_literal: true

module CsrfProtection
  extend ActiveSupport::Concern

  included do
    before_action :verify_origin, if: :state_changing_request?
  end

  private

  def state_changing_request?
    request.post? || request.put? || request.patch? || request.delete?
  end

  def verify_origin
    origin = request.headers['Origin']

    # JWT専用API: 全てのリクエストでOriginヘッダー必須
    # ブラウザからのリクエストは必ずOriginを送信する
    # 非ブラウザクライアント（モバイルアプリ等）は現状サポート対象外
    if origin.blank?
      render json: {
        status: 'error',
        message: 'Origin header required'
      }, status: :forbidden
      return
    end

    return if ALLOWED_ORIGINS.include?(origin)

    render json: {
      status: 'error',
      message: 'Origin not allowed'
    }, status: :forbidden
  end
end
