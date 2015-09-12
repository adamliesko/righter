class RighterRoleGrant < ActiveRecord::Base
  belongs_to :righter_role
  belongs_to :grantable_righter_role, class_name: 'RighterRole'

  validates :righter_role_id, presence: true
  validates :grantable_righter_role_id, presence: true
end
