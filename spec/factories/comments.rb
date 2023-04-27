FactoryBot.define do
  factory :comment do
    other_user_name { 'hogehoge' }
    comment { 'testimonials' }
  end
end
