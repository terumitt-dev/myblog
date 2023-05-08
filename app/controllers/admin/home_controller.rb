class Admin::HomeController < ApplicationController
  before_action :authenticate_admin!
  
  def index
    @blogs = Blog.all
  end

end
