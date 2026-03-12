# frozen_string_literal: true

module Api
  class BlogsController < ApplicationController
    before_action :set_blog, only: [:show]

    # GET /api/blogs
    def index
      @blogs = Blog.all.order(created_at: :desc)

      # カテゴリフィルター
      if params[:category].present?
        category_param = params[:category].to_s
        category_value =
          if category_param.match?(/\A\d+\z/)
            category_param.to_i
          else
            Blog.categories[category_param]
          end

        @blogs = @blogs.where(category: category_value) unless category_value.nil?
      end

      # ページネーション
      page = params[:page].to_i
      page = 1 if page < 1

      limit = params[:limit].to_i
      limit = 20 if limit < 1
      limit = [limit, 100].min # 最大100件

      offset = (page - 1) * limit
      @blogs = @blogs.limit(limit).offset(offset)

      blogs_with_category = @blogs.map do |blog|
        {
          id: blog.id,
          title: blog.title,
          content: blog.content,
          category: blog[:category],
          category_name: blog.category,
          created_at: blog.created_at,
          updated_at: blog.updated_at
        }
      end

      render json: { blogs: blogs_with_category }, status: :ok
    end

    # GET /api/blogs/:id
    def show
      render json: {
        id: @blog.id,
        title: @blog.title,
        content: @blog.content,
        category: @blog.category,
        category_name: @blog.category,
        created_at: @blog.created_at,
        updated_at: @blog.updated_at
      }, status: :ok
    end

    private

    def set_blog
      @blog = Blog.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Blog not found' }, status: :not_found and return
    end
  end
end
