# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  include Devise::Controllers::Helpers

  before_action :set_locale
  before_action :set_default_cache_control
  after_action :apply_pending_cache_control

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  private

  def set_locale
    I18n.locale = :ja
  end

  # デフォルトはキャッシュ禁止（認証・変更系エンドポイント向け）
  # パブリック GET はコントローラー側で set_cdn_cacheable を呼んで許可フラグを立てる
  def set_default_cache_control
    response.headers['Cache-Control'] = 'no-store'
  end

  # パブリック GET エンドポイントで before_action から呼び出す
  # 実際の Cache-Control 設定は after_action で成功時のみ行う（誤キャッシュ防止）
  def set_cdn_cacheable
    request.env['cdn_cacheable'] = true
  end

  # CDN（Cloudflare等）に5分キャッシュさせるが、ブラウザはキャッシュしない。
  # 以下の条件を全て満たす場合のみ適用：
  # - set_cdn_cacheable でフラグが立っている
  # - GET リクエスト
  # - レスポンスが 2xx または 304（404/422 等のエラーレスポンスをキャッシュさせない）
  # - 認証情報（Authorization / Cookie）がない（個人化レスポンスを共有キャッシュさせない）
  # - レスポンスに Set-Cookie がない（個別状態を共有キャッシュに保存させない）
  def apply_pending_cache_control
    return unless request.env['cdn_cacheable']
    return unless request.get?
    return unless response.successful? || response.status == 304
    return if request.authorization.present? ||
              request.headers['Cookie'].present? ||
              response.headers['Set-Cookie'].present?

    response.headers['Cache-Control'] = 'public, s-maxage=300, max-age=0'
    # 既存の Vary を保持しつつ Authorization と Cookie を追加（他middlewareとの共存）
    vary_values = response.headers['Vary'].to_s.split(',').map(&:strip)
    response.headers['Vary'] = (vary_values + ['Authorization', 'Cookie']).reject(&:empty?).uniq.join(', ')
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
