# frozen_string_literal: true

class BlogsController < ApplicationController
  before_action :set_blog, only: %i[show edit update destroy]
  before_action :authenticate_admin!, only: [:import_mt]

  MAX_UPLOAD_SIZE = 5.megabytes
  ALLOWED_EXTENSIONS = %w[.txt]
  ALLOWED_MIME_TYPES = %w[text/plain]

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
    if uploaded_file.blank?
      redirect_to admin_root_path, alert: t('controllers.common.alert_no_file') and return
    end

    if uploaded_file.size > MAX_UPLOAD_SIZE
      redirect_to admin_root_path, alert: t('controllers.common.alert_file_too_large') and return
    end

    # MIME判定
    detected_type = Marcel::MimeType.for(uploaded_file, name: uploaded_file.original_filename) || ""
    unless ALLOWED_MIME_TYPES.include?(detected_type)
      redirect_to admin_root_path, alert: t('controllers.common.alert_invalid_file') and return
    end

    # 拡張子チェック（小文字化）
    ext = File.extname(uploaded_file.original_filename.to_s).downcase
    unless ALLOWED_EXTENSIONS.include?(ext)
      redirect_to admin_root_path, alert: t('controllers.common.alert_invalid_file') and return
    end

    Rails.logger.info "MT import started by Admin##{current_admin.id}"
    count = Blog.import_from_mt(uploaded_file)
    Rails.logger.info "MT import finished: #{count} entries created"

    if count.zero?
      redirect_to admin_root_path, alert: t('controllers.common.alert_invalid_file')
    else
      redirect_to admin_root_path, notice: t('controllers.common.notice_import', name: Blog.model_name.human, count: count)
    end
  rescue => e
    Rails.logger.error "MT import failed: #{e.message}"
    redirect_to admin_root_path, alert: t('controllers.common.alert_import_failed')
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
