require 'test_helper'

class RighterForResourceTest < ActiveSupport::TestCase
  class TestNonARResource
    include RighterForResource

    def initialize(id)
      @id = id
    end

    def righter_right_resource_id
      @id
    end
  end

  test 'methods are defined' do
    instance = TestNonARResource.new(1)
    door = Door.new

    assert TestNonARResource.respond_to?(:create_righter_right)
    assert TestNonARResource.respond_to?(:destroy_righter_right)
    assert TestNonARResource.respond_to?(:righter_right)
    assert !TestNonARResource.respond_to?(:auto_manage_righter_right)

    assert instance.respond_to?(:create_righter_right)
    assert instance.respond_to?(:destroy_righter_right)
    assert instance.respond_to?(:righter_right)
    assert !instance.respond_to?(:auto_manage_righter_right)

    assert Door.respond_to?(:create_righter_right)
    assert Door.respond_to?(:destroy_righter_right)
    assert Door.respond_to?(:righter_right)
    assert Door.respond_to?(:auto_manage_righter_right)

    assert door.respond_to?(:create_righter_right)
    assert door.respond_to?(:destroy_righter_right)
    assert door.respond_to?(:righter_right)
    assert !door.respond_to?(:auto_manage_righter_right)
  end

  test 'role creation with non AR object' do
    role = FactoryGirl.create(:righter_role, name: 'admin')

    assert_no_difference('RighterRight.count') do
      TestNonARResource.new(1)
    end

    assert_difference('RighterRight.count', 1) do
      assert_no_difference('RighterRightsRighterRole.count') do
        right = TestNonARResource.new(1).create_righter_right :manage
        assert_equal 'manage_RighterForResourceTest::TestNonARResource_1', right.name
        assert_equal 'RighterForResourceTest::TestNonARResource', right.resource_class
        assert_equal 1, right.resource_id
      end
    end

    assert_difference('RighterRight.count', -1) do
      TestNonARResource.new(1).destroy_righter_right :manage
    end

    assert_difference('RighterRight.count', 1) do
      assert_difference('RighterRightsRighterRole.count', 1) do
        assert_equal 0, role.reload.righter_rights.size
        right = TestNonARResource.new(1).create_righter_right :manage, auto_associate_roles: [:admin]
        assert_equal 1, role.reload.righter_rights.size
      end
    end

    assert_difference('RighterRight.count', -1) do
      assert_difference('RighterRightsRighterRole.count', -1) do
        TestNonARResource.new(1).destroy_righter_right :manage
      end
    end
  end

  test 'role creation with automanaged AR object' do
    admin_role = FactoryGirl.create(:righter_role, name: 'admin')
    user_role  = FactoryGirl.create(:righter_role, name: 'user')

    assert_no_difference('RighterRight.count') do
      FactoryGirl.create(:player)
    end

    door = nil
    assert_difference('RighterRight.count', 5) do
      assert_difference('RighterRightsRighterRole.count', 3) do
        assert RighterRight.where('name like ?', 'paint_Door_%').empty?
        assert RighterRight.where('name like ?', 'change_Door_%').empty?
        assert RighterRight.where('name like ?', 'open_Door_%').empty?
        assert_equal 0, admin_role.righter_rights.count
        assert_equal 0, user_role.righter_rights.count
        door = FactoryGirl.create(:door)
        assert RighterRight.find_by_name("paint_Door_#{door.id}").present?
        assert RighterRight.find_by_name("change_Door_#{door.id}").present?
        assert RighterRight.find_by_name("open_Door_#{door.id}").present?
        puts admin_role.id
        puts
        RighterRightsRighterRole.all.each do |r|
          puts r.inspect
        end
        # assert_equal 2, admin_role.righter_rights.size
        assert_equal 1, user_role.righter_rights.size
      end
    end

    assert_difference('RighterRight.count', -4) do
      assert_difference('RighterRightsRighterRole.count', -3) do
        door.destroy
      end
    end
  end

  test 'class methods do create class rights' do
    r = Door.create_righter_right(:manage)
    assert_equal 'manage_Door', r.name
    assert_equal 'Door', r.resource_class
    assert_nil r.resource_id

    assert_equal r, Door.righter_right(:manage)
  end

  test '.auto_manage_righter_right accepts proc as parent right option' do
    FactoryGirl.create(:righter_role, name: 'admin')
    FactoryGirl.create(:righter_role, name: 'user')

    house = FactoryGirl.create :house
    door = FactoryGirl.create :door, house: house

    assert house.righter_right(:build).present?
    assert door.righter_right(:close).present?
    assert_equal house.righter_right(:build), door.righter_right(:close).parent

    door.destroy

    refute door.righter_right(:close).present?
  end
end
