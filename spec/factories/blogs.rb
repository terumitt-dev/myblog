FactoryBot.define do
  factory :blog do
    title { 'Test Blog' }
    category { 'hobby' }
    content { 'Lorem ipsum' }
  end
end
