# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :authenticate_admin!

  def index
    @blogs = Blog.all
  end
end
