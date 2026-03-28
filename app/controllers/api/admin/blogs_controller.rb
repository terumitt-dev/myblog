# frozen_string_literal: true

module Api
  module Admin
    class BlogsController < ApplicationController
      before_action :authenticate_admin!
      before_action :set_blog, only: [:show, :update, :destroy]

      # GET /api/admin/blogs
      def index
        blogs = Blog.order(created_at: :desc)

        page = params[:page].to_i
        page = 1 if page < 1

        limit = params[:limit].to_i
        limit = 50 if limit < 1
        limit = [limit, 200].min

        offset = (page - 1) * limit
        blogs = blogs.limit(limit).offset(offset)

        blogs_with_category = blogs.map do |blog|
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

      # GET /api/admin/blogs/:id
      def show
        render json: {
          id: @blog.id,
          title: @blog.title,
          content: @blog.content,
          category: @blog[:category],
          category_name: @blog.category,
          created_at: @blog.created_at,
          updated_at: @blog.updated_at
        }, status: :ok
      end

      # POST /api/admin/blogs
      def create
        @blog = Blog.new(blog_params)
        @blog.content = sanitize_blog_content(@blog.content)

        if @blog.save
          render json: {
            id: @blog.id,
            title: @blog.title,
            content: @blog.content,
            category: @blog[:category],
            category_name: @blog.category,
            created_at: @blog.created_at,
            updated_at: @blog.updated_at
          }, status: :created
        else
          render json: { errors: @blog.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT/PATCH /api/admin/blogs/:id
      def update
        sanitized_params = blog_params.to_h
        if sanitized_params.key?("content")
          sanitized_params["content"] = sanitize_blog_content(sanitized_params["content"])
        end
        if @blog.update(sanitized_params)
          render json: {
            id: @blog.id,
            title: @blog.title,
            content: @blog.content,
            category: @blog[:category],
            category_name: @blog.category,
            created_at: @blog.created_at,
            updated_at: @blog.updated_at
          }, status: :ok
        else
          render json: { errors: @blog.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/admin/blogs/:id
      def destroy
        @blog.destroy

        if @blog.destroyed?
          head :no_content
        else
          render json: { errors: @blog.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/admin/blogs/import_mt
      def import_mt
        uploaded_file = params[:file]

        unless uploaded_file.present? && uploaded_file.respond_to?(:size)
          return render json: { error: 'Invalid file' }, status: :unprocessable_entity
        end

        if uploaded_file.size.zero? || uploaded_file.size > Blog::MAX_UPLOAD_SIZE
          return render json: { error: 'Invalid file' }, status: :unprocessable_entity
        end

        unless Blog.valid_mt_file?(uploaded_file)
          return render json: { error: 'Invalid file format' }, status: :unprocessable_entity
        end

        begin
          uploaded_file.rewind if uploaded_file.respond_to?(:rewind)
          import_result = Blog.import_from_mt(uploaded_file)
        rescue StandardError => e
          Rails.logger.error("MT import failed: #{e.class}: #{e.message}")
          return render json: { error: 'Import failed' }, status: :unprocessable_entity
        end

        unless import_result.is_a?(Hash)
          Rails.logger.error("MT import failed: unexpected result #{import_result.class}")
          return render json: { error: 'Import failed' }, status: :unprocessable_entity
        end

        success_count = import_result[:success].to_i
        errors_count = Array(import_result[:errors]).size

        if success_count.zero? && import_result[:error_type] == :no_entries
          render json: { error: 'No entries found' }, status: :unprocessable_entity
        elsif success_count.zero? && import_result[:error_type] == :too_many_entries
          render json: { error: 'Too many entries' }, status: :unprocessable_entity
        elsif success_count.zero?
          render json: { error: 'Import failed' }, status: :unprocessable_entity
        else
          render json: {
            message: 'Import completed',
            success: success_count,
            errors: errors_count
          }, status: :ok
        end
      end

      private

      def set_blog
        @blog = Blog.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        return render json: { error: 'Blog not found' }, status: :not_found
      end

      def blog_params
        params.require(:blog).permit(:title, :content, :category)
      end

      def sanitize_blog_content(html)
        ActionController::Base.helpers.sanitize(
          html.to_s,
          tags: Blog::SAFE_TAGS,
          attributes: Blog::SAFE_ATTRIBUTES
        )
      end
    end
  end
end
