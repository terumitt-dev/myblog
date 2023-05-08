# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    get 'home/index'
  end
  resources :blogs
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
