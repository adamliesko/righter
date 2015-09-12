# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    login { "user_#{id}" }
    encrypted_password '$2a$10$DC7veLNgRP3J4zFT7nPFfuMAzHau.0/76iK8P9U8DiufyT3R0thuO'
    password_salt '$2a$10$DC7veLNgRP3J4zFT7nPFfu'
  end
end
