# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :admins
  resources :admins

  resources :blogs do
    resources :comments
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'blogs#index'
end
