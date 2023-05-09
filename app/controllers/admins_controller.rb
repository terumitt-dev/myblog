# frozen_string_literal: true

class AdminsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @blogs = Blog.all
    @blog = Blog.new
  end

end
