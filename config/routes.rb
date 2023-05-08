# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    get 'home/index'
  end
  devise_for :admins
  resources :blogs do
    resources :comments
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
