class Door < ActiveRecord::Base
  include RighterForResource

  auto_manage_righter_right :paint
  auto_manage_righter_right :change, auto_associate_roles: [:admin]
  auto_manage_righter_right :open,   auto_associate_roles: [:admin, :user]
  auto_manage_righter_right :close, parent_right: ->(door) { door.house.righter_right(:build).name }

  belongs_to :house
end
