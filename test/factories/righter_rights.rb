# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :righter_right do
    sequence(:name) { |n| "right_#{n}" }
    human_name 'Any actions done in doors_controller'
    controller 'doors'
    actions ['*']
    hidden false
  end
end
