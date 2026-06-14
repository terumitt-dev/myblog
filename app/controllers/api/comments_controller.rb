# frozen_string_literal: true

module Api
  class CommentsController < ApplicationController
    # create のみ verify_turnstile! を set_blog より先に走らせる。
    # bot による無効 token + 任意 blog_id のスパムで DB 参照を発生させない目的:
    # - DB 負荷の抑制 (検証通過しない POST は DB に到達しない)
    # - blog_id の存在推測の防止 (Turnstile 失敗時は 404/422 の差が出ない)
    # Cloudflare siteverify はレート制限が緩い (Free 100万/日) ため、
    # 存在しない blog_id で 1 回外部 API を叩くコストは許容できる。
    before_action :verify_turnstile!, only: [:create]
    before_action :set_blog
    before_action :set_cdn_cacheable, only: [:index]

    # GET /api/blogs/:blog_id/comments
    def index
      page = params[:page].to_i
      page = 1 if page < 1

      limit = params[:limit].to_i
      limit = 50 if limit < 1
      limit = [limit, 200].min

      offset = (page - 1) * limit

      comments = @blog.comments.order(created_at: :desc).limit(limit).offset(offset).map do |c|
        {
          id: c.id,
          user_name: c.user_name,
          comment: c.comment,
          created_at: c.created_at
        }
      end

      render json: { comments: comments }, status: :ok
    end

    # POST /api/blogs/:blog_id/comments
    def create
      @comment = @blog.comments.build(comment_params)

      if @comment.save
        render json: {
          id: @comment.id,
          user_name: @comment.user_name,
          comment: @comment.comment,
          created_at: @comment.created_at
        }, status: :created
      else
        render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_blog
      @blog = Blog.find(params[:blog_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Blog not found' }, status: :not_found and return
    end

    def comment_params
      params.require(:comment).permit(:user_name, :comment)
    end

    # Cloudflare Turnstile token を検証して bot / spam を弾く。
    # token は body の top-level に `turnstile_token` として渡される想定:
    #   { "comment": { "user_name": "...", "comment": "..." }, "turnstile_token": "..." }
    # 不正・失効・未送信のいずれも 422 で同じレスポンスを返す
    # (個別のエラー差分から検証ロジックを推測されないようにする)。
    def verify_turnstile!
      return if TurnstileService.verify(params[:turnstile_token], remote_ip: safe_remote_ip)

      render json: { errors: ['認証に失敗しました。再度お試しください。'] }, status: :unprocessable_entity
    end

    # request.remote_ip は X-Forwarded-For の異常 (IpSpoofAttackError) で raise しうる。
    # remote_ip は Turnstile では optional フィールドなので、取得失敗時は nil で続行し、
    # 攻撃者の XFF 偽装による 500 量産を防ぐ (rack_attack.rb の client_ip と同じパターン)。
    def safe_remote_ip
      request.remote_ip
    rescue StandardError
      nil
    end
  end
end
