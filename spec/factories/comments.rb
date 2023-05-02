# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    other_user_name { 'hogehoge' }
    comment { 'testimonials' }
  end
end
