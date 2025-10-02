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

    count = Blog.import_from_mt(uploaded_file)

    if count.zero?
      redirect_to admin_root_path, alert: t('controllers.common.alert_no_entries')
    else
      redirect_to admin_root_path, notice: t('controllers.common.notice_import', name: "ブログ", count: count)
    end

  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error({
      context: "Blog import failed (validation)",
      error_class: e.class.name,
      model: e.record.class.name,
      errors: e.record.errors.to_hash,
      time: Time.current.iso8601
    }.to_json)
    redirect_to admin_root_path, alert: t('controllers.common.alert_import_failed_validation')

  rescue ArgumentError => e
    Rails.logger.error({
      context: "Blog import failed (argument error)",
      message: e.message,
      backtrace: e.backtrace.take(5),
      time: Time.current.iso8601
    }.to_json)
    redirect_to admin_root_path, alert: t('controllers.common.alert_import_failed_format')

  rescue StandardError => e
    Rails.logger.error({
      context: "Blog import failed (unexpected)",
      error_class: e.class.name,
      message: e.message,
      backtrace: e.backtrace.take(5),
      time: Time.current.iso8601
    }.to_json)
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
