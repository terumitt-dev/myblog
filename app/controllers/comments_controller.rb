# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_blog, only: [:create]

  # POST /comments or /comments.json
  def create
    @comment = Comment.new(comment_params)

    respond_to do |format|
      if @comment.save
        format.html { redirect_to blog_url(@blog), notice: 'Comment was successfully created.' }
        format.json { render :show, status: :created, location: @comment }
      else
        # format.html { render :new, status: :unprocessable_entity }
        format.html { redirect_to blog_url(@blog), notice: 'Comment was not created.' }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  
  def set_blog
    @blog = Blog.find(params[:blog_id])
  end

  # Only allow a list of trusted parameters through.
  def comment_params
    params.require(:comment).permit(:other_user_name, :comment).merge(blog_id: @blog.id)
  end
end
