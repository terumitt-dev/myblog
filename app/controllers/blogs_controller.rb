# frozen_string_literal: true

class BlogsController < ApplicationController
  before_action :set_blog, only: %i[show edit update destroy]

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
      tweet(@blog.title)
      redirect_to blog_url(@blog), notice: 'Blog was successfully created and tweeted.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /blogs/1 or /blogs/1.json
  def update
    if @blog.update(blog_params)
      redirect_to blog_url(@blog), notice: 'Blog was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /blogs/1 or /blogs/1.json
  def destroy
    @blog.destroy
    redirect_to admin_root_url, notice: 'Blog was successfully destroyed.'
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

  # Twitter
  def tweet(title)
    client = Twitter::Client.new {
      config.consumer_key = Rails.application.credentials.twitter[:consumer_key],
      config.consumer_secret = Rails.application.credentials.twitter[:consumer_secret],
      config.access_token = Rails.application.credentials.twitter[:access_token],
      config.access_token_secret = Rails.application.credentials.twitter[:access_token_secret],
    }
    client.post('statuses/update', { status: "New blog post: #{title}" })
  end

end
