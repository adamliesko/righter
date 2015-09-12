class User < ActiveRecord::Base
  include RighterForUser
  cattr_accessor :current_user
end
