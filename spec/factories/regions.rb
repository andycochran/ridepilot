require 'faker'

FactoryGirl.define do
  factory :region do
    name  { Faker::Lorem.words(2).join(' ') }
  end
end
