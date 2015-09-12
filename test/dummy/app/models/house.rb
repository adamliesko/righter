class House < ActiveRecord::Base
  include RighterForResource

  auto_manage_righter_right :build

  has_many :doors
end
