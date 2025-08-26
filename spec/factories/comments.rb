# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    user_name { 'hogehoge' }
    comment { 'testimonials' }
    blog
  end
end
