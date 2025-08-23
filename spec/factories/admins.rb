# frozen_string_literal: true

FactoryBot.define do
  factory :admin do
    email { 'test@email.com' }
    password { 'password123' }
    password_confirmation { 'password123' }
  end
end
