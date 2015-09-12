# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :righter_role do
    name 'door_opener'
    human_name { "Human name for #{name}" }
    hidden false
  end
end
