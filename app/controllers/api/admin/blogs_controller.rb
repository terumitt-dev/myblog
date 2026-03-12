# frozen_string_literal: true

module Api
  module Admin
    class BlogsController < ApplicationController
      before_action :authenticate_admin!
      before_action :set_blog, only: [:show, :update, :destroy]

      # GET /api/admin/blogs
      def index
        @blogs = Blog.all.order(created_at: :desc)

        blogs_with_category = @blogs.map do |blog|
          {
            id: blog.id,
            title: blog.title,
            content: blog.content,
            category: blog.category,
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
          category: @blog.category,
          category_name: @blog.category,
          created_at: @blog.created_at,
          updated_at: @blog.updated_at
        }, status: :ok
      end

      # POST /api/admin/blogs
      def create
        @blog = Blog.new(blog_params)

        if @blog.save
          render json: {
            id: @blog.id,
            title: @blog.title,
            content: @blog.content,
            category: @blog.category,
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
        if @blog.update(blog_params)
          render json: {
            id: @blog.id,
            title: @blog.title,
            content: @blog.content,
            category: @blog.category,
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
        head :no_content
      end

      # POST /api/admin/blogs/import_mt
      def import_mt
        uploaded_file = params[:file]

        if uploaded_file.blank? || uploaded_file.size.zero? || uploaded_file.size > Blog::MAX_UPLOAD_SIZE
          return render json: { error: 'Invalid file' }, status: :unprocessable_entity
        end

        unless Blog.valid_mt_file?(uploaded_file)
          return render json: { error: 'Invalid file format' }, status: :unprocessable_entity
        end

        io = uploaded_file.respond_to?(:tempfile) ? uploaded_file.tempfile : uploaded_file
        io.rewind if io.respond_to?(:rewind)

        begin
          import_result = Blog.import_from_mt(uploaded_file)
        rescue StandardError => e
          Rails.logger.error("MT import failed: #{e.class}: #{e.message}")
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
    end
  end
end
