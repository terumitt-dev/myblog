# frozen_string_literal: true

# require 'nokogiri'

class BlogsController < ApplicationController
  before_action :set_blog, only: %i[show edit update destroy]

  # GET /blogs or /blogs.json
  def index
    @blogs = Blog.all
  end

  # GET /blogs/1 or /blogs/1.json
  def show; end

  # GET /blogs/new
  def new
    @blog = Blog.new
  end

  # GET /blogs/1/edit
  def edit; end

  # POST /blogs or /blogs.json
  def create
    @blog = Blog.new(blog_params)

    respond_to do |format|
      if @blog.save
        format.html { redirect_to blog_url(@blog), notice: 'Blog was successfully created.' }
        format.json { render :show, status: :created, location: @blog }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /blogs/1 or /blogs/1.json
  def update
    respond_to do |format|
      if @blog.update(blog_params)
        format.html { redirect_to blog_url(@blog), notice: 'Blog was successfully updated.' }
        format.json { render :show, status: :ok, location: @blog }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /blogs/1 or /blogs/1.json
  def destroy
    @blog.destroy

    respond_to do |format|
      format.html { redirect_to blogs_url, notice: 'Blog was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def data_port
    file = File.open(params[:file], 'r')
    content = file.read

    blog_regex = /^(TITLE:[^\n]+\nBODY:[^\n]+\n)+/m

    matches = content.scan(blog_regex)
    blogs = matches.map do |match|
      title_regex = /^TITLE:\s*(.*)$/m
      body_regex = /^BODY:\s*\r?\n(.*)$/m

      title = match.match(title_regex)[1]
      body = match.match(body_regex)[1]

      Blog.new(title:, content: body)
    end

    if blogs.all?(&:save)
      redirect_to blogs_path, notice: 'Blogs were successfully imported.'
    else
      render :new, alert: 'Failed to import blog.'
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
