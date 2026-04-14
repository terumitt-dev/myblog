# frozen_string_literal: true

module Api
  class CommentsController < ApplicationController
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
  end
end
