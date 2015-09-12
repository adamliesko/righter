# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :door do
    name 'The Door'
    active true

    house
  end
end
