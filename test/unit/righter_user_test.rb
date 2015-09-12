require 'test_helper'

class RighterUserTest < ActiveSupport::TestCase
  fixtures :righter_rights, :righter_roles, :users, :players

  def setup
    RighterRight.clear_cache
  end

  test 'righter_accessible? :role checks if user has appropriate role' do
    u = users :one
    r = righter_roles(:secret_agent)
    assert !u.righter_accessible?(role: :secret_agent)
    u.add_role r
    assert u.righter_accessible?(role: :secret_agent)
  end

  test 'righter_accessible? :right checks if user has appropriate right' do
    u = users :one
    r = righter_rights(:kill)
    ro = righter_roles(:secret_agent)
    ro.add_right r

    assert !u.righter_accessible?(right: :kill)
    u.add_role ro
    assert u.reload.righter_accessible?(right: :kill)
  end

  test 'righter_accessible? :controller/:action checks if user has any role with :controller/:action' do
    u = users :one
    ro = righter_roles(:secret_agent)
    right_to_kill = righter_rights(:kill)
    ro.add_right right_to_kill
    u.add_role ro

    assert !u.reload.righter_accessible?(controller: :james, action: :bond)
    right_to_kill.add_access_to controller: :james, actions: [:bond]

    assert u.reload.righter_accessible?(controller: :james, action: :bond)
  end

  test 'righter_accessible? :controller/:action : wildcards are correctly expanded in action names' do
    RighterRightsRighterRole.delete_all
    RighterRolesUser.delete_all
    r = righter_rights :kill
    r.add_access_to controller: :villains, actions: [:'francisco_*']
    u = users :one
    role_secret_agent = righter_roles(:secret_agent)
    u.add_role role_secret_agent
    role_secret_agent.add_right r

    assert u.reload.righter_accessible?(controller: :villains, action: :francisco_scaramanga)
    assert !u.righter_accessible?(controller: :villains, action: :goldfinder)

    r2 = righter_rights :vamp
    role_bond_girl = righter_roles(:bond_girl)
    role_bond_girl.add_right r2
    u2 = users :two
    u2.add_role role_bond_girl
    r2.add_access_to controller: :men, actions: [:'*']

    assert u2.reload.righter_accessible?(controller: :men, action: :any_man_in_the_world)
    assert !u.reload.righter_accessible?(controller: :men, action: :any_man_in_the_world)
  end

  test 'righter_accessible?: namespace/controller/action works with wildcards' do
    r = righter_rights :kill
    role_secret_agent = righter_roles(:secret_agent)
    role_secret_agent.add_right r
    r.add_access_to controller: :'evil/world', actions: [:'make_*']

    u = users :one
    u.add_role role_secret_agent

    assert u.reload.righter_accessible?(controller: :'evil/world', action: :make_peace)
  end

  test 'righter_accessible?: resource rights' do
    admin_role = FactoryGirl.create(:righter_role, name: 'admin')
    user_role = FactoryGirl.create(:righter_role, name: 'user')
    door = FactoryGirl.create(:door) # this creates paint_Door_{id}, change_Door_{id}, open_Door_{id}

    admin = FactoryGirl.create(:user)
    admin.add_role admin_role

    user = FactoryGirl.create(:user)
    user.add_role user_role

    guest = FactoryGirl.create(:user) # has no roles

    assert_raises(RighterError) do
      admin.reload.righter_accessible?(resource: door) # no right given
    end

    assert_raises(RighterError) do
      admin.reload.righter_accessible?(resource: door, right: :unknown_right)
    end

    assert !admin.righter_accessible?(resource: door, right: :paint) # known right but without priviledge
    assert admin.righter_accessible?(resource: door, right: :change)
    assert admin.righter_accessible?(resource: door, right: :open)

    assert !user.righter_accessible?(resource: door, right: :paint) # known right but without priviledge
    assert !user.righter_accessible?(resource: door, right: :change) # known right but without priviledge
    assert user.righter_accessible?(resource: door, right: :open)

    assert !guest.righter_accessible?(resource: door, right: :paint) # known right but without priviledge
    assert !guest.righter_accessible?(resource: door, right: :change) # known right but without priviledge
    assert !guest.righter_accessible?(resource: door, right: :open)
  end

  test 'add_role/remove_role will raise error for non existing role' do
    u = users :one
    assert_raise RighterError do
      u.add_role 'smth'
    end
    assert_raise RighterError do
      u.remove_role 'smth2'
    end
  end

  test 'remove_role will remove association between role and user but will keep the role' do
    u = users :one
    r = righter_roles :bond_girl
    u.add_role r
    assert u.righter_roles.include?(r)

    assert_no_difference 'RighterRole.count', 'The role itself should not be deleted - only the association' do
      u.remove_role r
      assert !u.reload.righter_roles.include?(r)
    end
  end

  test 'association is removed when role is deleted' do
    user = users :one
    role = righter_roles :bond_girl
    assert_difference 'RighterRolesUser.count', 1 do
      user.add_role role
    end
    assert_equal 1, user.righter_roles.size
    assert_difference 'RighterRolesUser.count', -1 do
      role.destroy
    end
    assert_equal 0, user.reload.righter_roles.size
  end

  test 'delete user' do
    u = users :one
    assert_difference 'User.count', -1 do
      u.destroy
    end
  end

  test 'association is removed when user is deleted' do
    u = users :one
    r = righter_roles :bond_girl
    assert_difference 'RighterRolesUser.count', 1 do
      u.add_role r
    end
    assert_equal 1, r.users.size
    assert_difference 'RighterRolesUser.count', -1 do
      u.destroy
    end
    assert_equal 0, r.reload.users.size
  end

  test 'righter_accessible? :right will raise error if asking for non existing right' do
    u = users :one
    assert_raise RighterError do
      u.righter_accessible? right: :nonexistingright
    end
  end

  test 'update_roles_with_respect_to_grants takes care that user-role can be paired only according to role grants' do
    judi_dench = users :one
    roger_moore = users :two
    olga_kurylenko = users :three

    role_mi6_boss = righter_roles :one
    role_secret_agent = righter_roles :secret_agent
    role_bond_girl = righter_roles :bond_girl

    RighterRolesUser.delete_all
    RighterRoleGrant.delete_all

    judi_dench.add_role role_mi6_boss
    role_mi6_boss.allow_to_grant_role role_secret_agent
    role_secret_agent.allow_to_grant_role role_bond_girl

    assert_equal [role_mi6_boss], judi_dench.reload.righter_roles
    assert_equal [], roger_moore.reload.righter_roles
    assert_equal [], olga_kurylenko.reload.righter_roles

    User.current_user = judi_dench

    roger_moore.update_roles_with_respect_to_grants [role_secret_agent]
    assert_equal [role_mi6_boss], judi_dench.reload.righter_roles
    assert_equal [role_secret_agent], roger_moore.reload.righter_roles
    assert_equal [], olga_kurylenko.reload.righter_roles

    olga_kurylenko.update_roles_with_respect_to_grants [role_bond_girl]
    assert_equal [role_mi6_boss], judi_dench.reload.righter_roles
    assert_equal [role_secret_agent], roger_moore.reload.righter_roles
    assert_equal [], olga_kurylenko.reload.righter_roles

    User.current_user = roger_moore.reload

    olga_kurylenko.update_roles_with_respect_to_grants [role_bond_girl]
    assert_equal [role_mi6_boss], judi_dench.reload.righter_roles
    assert_equal [role_secret_agent], roger_moore.reload.righter_roles
    assert_equal [role_bond_girl], olga_kurylenko.reload.righter_roles

    judi_dench.update_roles_with_respect_to_grants [role_secret_agent]
    assert_equal [role_mi6_boss], judi_dench.reload.righter_roles
    assert_equal [role_secret_agent], roger_moore.reload.righter_roles
    assert_equal [role_bond_girl], olga_kurylenko.reload.righter_roles

    User.current_user = olga_kurylenko.reload

    judi_dench.update_roles_with_respect_to_grants [role_bond_girl]
    assert_equal [role_mi6_boss], judi_dench.reload.righter_roles
    assert_equal [role_secret_agent], roger_moore.reload.righter_roles
    assert_equal [role_bond_girl], olga_kurylenko.reload.righter_roles

    olga_kurylenko.update_roles_with_respect_to_grants [role_secret_agent]
    assert_equal [role_mi6_boss], judi_dench.reload.righter_roles
    assert_equal [role_secret_agent], roger_moore.reload.righter_roles
    assert_equal [role_bond_girl], olga_kurylenko.reload.righter_roles
  end

  test 'righter_player_roles' do
    assert_nil Player.reflections[:righter_roles]
    assert_nil RighterRole.reflections[:players]

    Player.send :include, RighterForUser

    assert Player.reflections['righter_roles'], 'Player should have association with RighterRoles'
    assert RighterRole.reflections['players'], 'RighterRoles should have association with Players'

    batman = players :batman
    r = righter_roles(:secret_agent)
    assert !batman.righter_accessible?(role: :secret_agent)
    batman.add_role r
    assert batman.righter_accessible?(role: :secret_agent)
  end

  test 'can? method' do
    admin_role = FactoryGirl.create(:righter_role, name: 'admin')
    user_role  = FactoryGirl.create(:righter_role, name: 'user')
    user = FactoryGirl.create(:user, login: 'user')
    admin = FactoryGirl.create(:user, login: 'admin')

    user.add_role(user_role)
    admin.add_role(admin_role)

    door = FactoryGirl.create(:door)

    # Door:
    # auto_manage_righter_right :paint
    # auto_manage_righter_right :change, {auto_associate_roles: [:admin]}
    # auto_manage_righter_right :open,   {auto_associate_roles: [:admin, :user]}

    assert !user.can?(:paint, door)
    assert !user.can?(:change, door)
    assert user.can?(:open, door)

    assert !admin.can?(:paint, door)
    assert admin.can?(:change, door)
    assert admin.can?(:open, door)
  end
end
