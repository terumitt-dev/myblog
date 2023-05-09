# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :admins, controllers: { registrations: 'admins/registrations' }, path: "admins"

  authenticated :admin do
    root to: 'admins#index', as: :admin_root
    resources :blogs
  end

  resources :blogs, only: %i[index, show]do
    resources :comments
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  get '*path', to: redirect('/')
  root 'blogs#index'
end
