# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :admins, skip: [:sessions, :registrations]

  namespace :api do
    namespace :auth do
      post 'sign_up', to: 'registrations#create'
      post 'sign_in', to: 'sessions#create'
      delete 'sign_out', to: 'sessions#destroy'
      get 'current_user', to: 'current_users#show'
    end

    resources :blogs, only: %i[index show] do
      resources :comments, only: %i[create]
    end

    namespace :admin do
      resources :blogs do
        collection do
          post :import_mt
        end
      end
    end
  end
end
