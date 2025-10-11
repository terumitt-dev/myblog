# frozen_string_literal: true

class BlogsController < ApplicationController
  before_action :set_blog, only: %i[show edit update destroy]
  before_action :authenticate_admin!, only: [:import_mt]

  # GET /blogs or /blogs.json
  def index
    @blogs = Blog.all
  end

  # GET /blogs/1 or /blogs/1.json
  def show
    @comment = Comment.new
    set_blog
  end

  # GET /blogs/new
  def new
    @blog = Blog.new
  end

  # GET /blogs/1/edit
  def edit; end

  # POST /blogs or /blogs.json
  def create
    @blog = Blog.new(blog_params)

    if @blog.save
      redirect_to blog_url(@blog), notice: t('controllers.common.notice_create', name: Blog.model_name.human)
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /blogs/1 or /blogs/1.json
  def update
    if @blog.update(blog_params)
      redirect_to blog_url(@blog), notice: t('controllers.common.notice_update', name: Blog.model_name.human)
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /blogs/1 or /blogs/1.json
  def destroy
    @blog.destroy
    redirect_to admin_root_url, notice: t('controllers.common.notice_destroy', name: Blog.model_name.human)
  end

  # POST /blogs/import_mt
  def import_mt
    uploaded_file = params[:file]

    if uploaded_file.blank? || uploaded_file.size.zero? || uploaded_file.size > Blog::MAX_UPLOAD_SIZE
      redirect_to admin_root_path, alert: t('controllers.common.alert_invalid_file') and return
    end

    unless Blog.valid_mt_file?(uploaded_file)
      redirect_to admin_root_path, alert: t('controllers.common.alert_invalid_file') and return
    end

    import_result = Blog.import_from_mt(uploaded_file)

    case
    when import_result[:success].zero? && import_result[:errors].any? { |e| e.include?("No valid entries found") }
      redirect_to admin_root_path, alert: t('controllers.common.alert_no_entries')
    when import_result[:success].zero? && import_result[:errors].any? { |e| e.include?("Too many entries") }
      redirect_to admin_root_path, alert: t('controllers.common.alert_too_many_entries')
    when import_result[:success].zero?
      Rails.logger.warn "Import failed: #{import_result[:errors].join('; ')}"
      redirect_to admin_root_path, alert: t('controllers.common.alert_import_failed_general')
    else
      success_message = t('controllers.common.notice_import', name: "ブログ", count: import_result[:success])
      if import_result[:errors].any?
        warning_message = "#{success_message} (#{import_result[:errors].size}件でエラー)"
        redirect_to admin_root_path, notice: warning_message
      else
        redirect_to admin_root_path, notice: success_message
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_blog
    @blog = Blog.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def blog_params
    params.require(:blog).permit(:title, :content, :category)
  end
end
