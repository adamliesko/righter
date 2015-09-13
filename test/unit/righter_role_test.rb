require 'test_helper'

class RighterRoleTest < ActiveSupport::TestCase
  fixtures :righter_rights, :righter_roles

  def setup
    RighterRightsRighterRole.delete_all
    RighterRoleGrant.delete_all
  end

  test 'add_right to role creates new entry in RighterRolesRighterRights table' do
    r = righter_rights :kill
    r1 = righter_roles :secret_agent
    assert_difference 'r1.reload.righter_rights.size', 1 do
      r1.add_right r
    end

    assert_no_difference 'r1.righter_rights.size' do
      r1.add_right r
    end
  end

  test 'add_self_and_children_rights to role creates according entries in RighterRolesRighterRights table' do
    role = FactoryGirl.create :righter_role
    r1 = FactoryGirl.create :righter_right, name: 'Parent right'
    FactoryGirl.create :righter_right, name: 'Child right one', parent_id: r1.id
    FactoryGirl.create :righter_right, name: 'Child right two', parent_id: r1.id

    assert_difference 'role.reload.righter_rights.size', 3 do
      role.add_self_and_child_rights r1
    end
  end

  test 'remove_right removes association between role and right but keep the right itself' do
    ro1 = righter_roles :secret_agent
    r1 = righter_rights :kill

    ro1.add_right r1
    assert ro1.righter_rights.include?(r1)

    ro1.remove_right r1
    assert !ro1.reload.righter_rights.include?(r1)

    assert r1.reload
  end

  test 'unique role name is enforced' do
    ro1 = righter_roles :secret_agent
    assert_raise ActiveRecord::RecordInvalid do
      RighterRole.create! name: :secret_agent
    end
  end

  test 'add_right and remove_right will raise error for bad input' do
    ro1 = righter_roles :secret_agent
    assert_raise RighterError do
      ro1.add_right 'smth'
    end
    assert_raise RighterError do
      ro1.remove_right 'smth2'
    end
  end

  test 'right-role association is removed when right is deleted' do
    ro1 = righter_roles :secret_agent
    r1 = righter_rights :kill
    assert !RighterRightsRighterRole.exists?(righter_role_id: ro1.id, righter_right_id: r1.id)

    assert_difference 'RighterRightsRighterRole.count', 1 do
      ro1.add_right r1
    end
    assert_difference 'RighterRightsRighterRole.count', -1 do
      r1.destroy
    end
  end

  test 'right-role association is removed when role is deleted' do
    ro1 = righter_roles :secret_agent
    r1 = righter_rights :kill
    assert !RighterRightsRighterRole.exists?(righter_role_id: ro1.id, righter_right_id: r1.id)
    ro1.add_right r1

    assert_difference 'RighterRightsRighterRole.count', -1 do
      ro1.destroy
    end
  end

  test 'parent right is assigned automatically if any of children rights is assigned to role' do
    r1 = RighterRight.create! name: '1'
    r11 = RighterRight.create! name: '11', parent_id: r1.id

    roleA = RighterRole.create! name: 'A', human_name: 'hmmm'
    assert !roleA.righter_rights.include?(r1)
    roleA.add_right r11
    assert roleA.reload.righter_rights.include?(r1)
  end

  test 'all children rights are deassigned if parent right is deassigned from role' do
    r1 = RighterRight.create! name: '1'
    r11 = RighterRight.create! name: '11', parent_id: r1.id
    r12 = RighterRight.create! name: '12', parent_id: r1.id
    r121 = RighterRight.create! name: '121', parent_id: r12.id

    roleA = RighterRole.create! name: 'A', human_name: 'b'
    roleA.add_right r1
    roleA.add_right r11
    roleA.add_right r121

    assert roleA.reload.righter_rights.include?(r1)
    assert roleA.reload.righter_rights.include?(r11)
    assert roleA.reload.righter_rights.include?(r121)

    roleA.remove_right r1

    assert !roleA.reload.righter_rights.include?(r1)
    assert !roleA.reload.righter_rights.include?(r11)
    assert !roleA.reload.righter_rights.include?(r121)
  end

  test 'righter_role.allow_to_grant_role will add only unique entry to RighterRoleGrant' do
    r1 = righter_roles :one
    r2 = righter_roles :two

    assert_difference 'RighterRoleGrant.count', 1 do
      r1.allow_to_grant_role r2
    end
    assert_no_difference 'RighterRoleGrant.count' do
      r1.allow_to_grant_role r2
    end
    assert_difference 'RighterRoleGrant.count', -1 do
      r1.destroy
    end
    assert_difference 'RighterRoleGrant.count', 4 do # FIXME: no difference shall be here
      RighterRoleGrant.create(righter_role_id: r1.id, grantable_righter_role_id: r2.id)
      RighterRoleGrant.create(righter_role_id: r1.id, grantable_righter_role_id: r2.id)
      RighterRoleGrant.create(righter_role_id: r1.id, grantable_righter_role_id: r2.id)
      RighterRoleGrant.create(righter_role_id: r1.id, grantable_righter_role_id: r2.id)
    end
  end

  test 'righter_role.disallow_to_grant_role is silent when removing ungranted role' do
    r1 = righter_roles :one
    r2 = righter_roles :two

    r1.allow_to_grant_role r2

    assert_difference 'RighterRoleGrant.count', -1 do
      r1.disallow_to_grant_role r2
    end

    assert_no_difference 'RighterRoleGrant.count', 0 do
      r1.disallow_to_grant_role r2
    end
  end

  test 'righter_role.grantable_roles reflects the state in RighterRoleGrant table' do
    r1 = righter_roles :one
    r2 = righter_roles :two
    assert !r1.grantable_roles.include?(r2)
    r1.allow_to_grant_role r2
    assert r1.reload.grantable_roles.include?(r2)
    r1.disallow_to_grant_role r2
    assert !r1.grantable_roles.include?(r2)
    assert !r1.reload.grantable_roles.include?(r2)
  end

  test 'disallow_all_granted_roles removes all granted roles associated to role' do
    r1 = righter_roles :one
    r2 = righter_roles :two
    r1.allow_to_grant_role r2
    assert r1.grantable_roles.include?(r2), 'grantable role added'
    assert r1.reload.grantable_roles.include?(r2), 'grantable role added and saved'
    r1.disallow_all_granted_roles
    assert !r1.reload.grantable_roles.include?(r2), 'and it is saved'
  end

  test 'all associated entries in role_grants are deleted on role destroy' do
    r1 = righter_roles :one
    r2 = righter_roles :two
    r3 = righter_roles :three
    r1.allow_to_grant_role r2
    r2.allow_to_grant_role r3

    assert_difference 'RighterRoleGrant.count', -2 do
      r2.destroy
    end
  end

  test 'unique names' do
    r1 = righter_roles :one
    ri = righter_rights :kill

    assert_difference 'RighterRightsRighterRole.count' do
      r1.add_right ri
    end
  end

  test '#create_or_update_with_grants' do
    roleA = RighterRole.create! name: 'A', human_name: 'a'
    roleB = RighterRole.create! name: 'B', human_name: 'b'

    assert RighterRole.new.create_or_update_with_grants('Ax', 'ax', [roleA.name])

    another_role = RighterRole.find_by(name: 'Ax')

    assert roleA.create_or_update_with_grants('A', 'a', [roleB.name])
    assert another_role.grantable_righter_roles, [roleB]
    assert roleA.create_or_update_with_grants('A', 'a', [roleB.name, another_role.name])
    assert another_role.grantable_righter_roles, [roleB, another_role]
  end
end
