# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_blog, only: [:create]

  # POST /comments or /comments.json
  def create
    @comment = Comment.new(comment_params)

    if @comment.save
      redirect_to blog_url(@blog), notice: t('controllers.common.notice_create', name: Comment.model_name.human)
    else
      redirect_to blog_url(@blog), alert: t('controllers.common.alert_create', name: Comment.model_name.human)
    end
  end

  private

  def set_blog
    @blog = Blog.find(params[:blog_id])
  end

  # Only allow a list of trusted parameters through.
  def comment_params
    params.require(:comment).permit(:user_name, :comment).merge(blog_id: @blog.id)
  end
end
