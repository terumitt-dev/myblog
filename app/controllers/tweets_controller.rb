# frozen_string_literal: true

class TweetsController < ApplicationController
  def tweet
    client = Rails.application.config.twitter_client
    @blog = Blog.find(params[:id])
    # client.update_with_media(@blog.title, open(@blog.image_url), @blog.url)
    client.update_with_media(@blog.title, @blog.url)
    redirect_to @blog, notice: 'Blog was successfully tweeted.'
  end
end
