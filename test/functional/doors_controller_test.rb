require 'test_helper'

class DoorsControllerTest < ActionController::TestCase
  def setup
    @user = FactoryGirl.create(:user, login: 'user')
    @admin = FactoryGirl.create(:user, login: 'admin')

    @controller_role = FactoryGirl.create(:righter_role, name: 'doors_controller')
    @controller_right = FactoryGirl.create(:righter_right, name: 'all_door_actions', controller: 'doors', actions: ['*'])
    @controller_role.add_right(@controller_right)

    @admin_role = FactoryGirl.create(:righter_role, name: 'admin')
    @user_role = FactoryGirl.create(:righter_role, name: 'user')

    @admin.add_role(@controller_role)
    @admin.add_role(@admin_role)

    @user.add_role(@controller_role)
    @user.add_role(@user_role)

    @admin.reload
    @user.reload

    sign_out
  end

  test 'signed_out user cannot access the controller - enforced by controller access rights' do
    door = FactoryGirl.create(:door)
    sign_out
    assert_raises(RighterNoUserError) do
      get :show, id: door.id
    end
  end

  test 'signed in user with authorization controller actions will be examined to access resources' do
    door = FactoryGirl.create(:door)

    # @user is authorized to:
    # - access the controller
    # - open the door
    sign_in(@user)

    assert_nothing_raised do
      get :show, id: door.id
      get :open, id: door.id
    end
    assert_raises(RighterError) do
      get :change, id: door.id
    end

    # @admin is authorized to:
    # - access the controller
    # - open the door
    # - change the door
    sign_in(@admin)

    assert_nothing_raised do
      get :show, id: door.id
      get :open, id: door.id
      get :change, id: door.id
    end
  end

  test 'signed in user with authorization can access simple controller action' do
    door = FactoryGirl.create(:door)
    sign_in(@user) # authorized user
    assert_nothing_raised do
      get :show, id: door.id
    end
  end
end
