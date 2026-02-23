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

    # Originヘッダーがない場合はブラウザ外クライアント（curlやモバイルアプリ等）からのリクエスト。
    # JWT認証で保護されているため、Originなしリクエストも許可する。
    # ブラウザからのリクエストは必ずOriginを送るため、CSRFリスクはない。
    return if origin.blank?

    allowed_origins = if Rails.env.production?
                        [
                          'https://go-lilaregard.com',
                          'https://www.go-lilaregard.com'
                        ]
                      else
                        [
                          'http://localhost:5173',
                          'http://localhost:3000',
                          'http://127.0.0.1:5173',
                          'http://127.0.0.1:3000'
                        ]
                      end

    return if allowed_origins.include?(origin)

    render json: {
      status: 'error',
      message: 'Origin not allowed'
    }, status: :forbidden
  end
end
