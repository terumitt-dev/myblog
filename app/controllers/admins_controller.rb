# frozen_string_literal: true

class AdminsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @blogs = Blog.all
  end

  def new
    @blog = Blog.new
  end
end
