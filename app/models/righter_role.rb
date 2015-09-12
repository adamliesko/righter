class RighterRole < ActiveRecord::Base
  has_many :righter_rights_righter_roles, dependent: :destroy
  has_many :righter_rights, through: :righter_rights_righter_roles
  has_many :righter_role_grants, dependent: :destroy
  has_many :grantable_righter_roles, -> { uniq }, through: :righter_role_grants

  validates :name, :human_name, uniqueness: true, presence: true

  scope :visible, lambda {
    where hidden: [false, nil]
  }

  after_destroy do
    RighterRoleGrant.where(righter_role_id: id).destroy_all
    RighterRoleGrant.where(grantable_righter_role_id: id).destroy_all
  end

  def add_right(right)
    unless right.is_a?(RighterRight)
      fail RighterError.new("RighterRole.add_right accepts only RighterRight instance as input (provided :#{right.class.inspect})")
    end
    righter_rights << right unless righter_rights.include?(right)
    save!

    if right.parent
      add_right right.parent unless righter_rights.include?(right.parent)
    end
  end

  def add_self_and_child_rights(right)
    add_right right
    right.children.each { |r| add_self_and_child_rights r }
  end

  def remove_right(right)
    unless right.is_a?(RighterRight)
      fail RighterError.new("RighterRole.remove_right accepts only RighterRight instance as input (provided :#{right.class.inspect})")
    end

    righter_rights.delete right

    right.children.each do |child_r|
      remove_right child_r
    end
  end

  def allow_to_grant_role(role)
    grantable_righter_roles << role unless grantable_righter_roles.include?(role)
  end

  def disallow_to_grant_role(role)
    grantable_righter_roles.destroy(role)
  end

  def disallow_all_granted_roles
    grantable_righter_roles.destroy_all
  end

  alias_method :grantable_roles, :grantable_righter_roles

  def create_or_update_with_grants(name, human_name, granted_role_names)
    passed_validation = false

    self.name = name
    self.human_name = human_name
    self.class.transaction do
      if save
        passed_validation = true

        disallow_all_granted_roles
        if granted_role_names
          granted_role_names.each do |role_name|
            role_to_grant = self.class.find_by_name role_name # this is badly inneficient
            allow_to_grant_role role_to_grant if role_to_grant
          end
        end
      end
    end

    passed_validation
  end
end
