require 'test_helper'

class RighterRightTest < ActiveSupport::TestCase
  fixtures :righter_rights

  test 'top_level_rights scopes returns only rights without parent_id' do
    r1 = FactoryGirl.create(:righter_right)
    r2 = FactoryGirl.create(:righter_right, parent_id: r1.id)

    assert RighterRight.top_level_rights, [r2]
  end

  test 'visible scopes returns only rights with fals-y hidden attribute' do
    FactoryGirl.create(:righter_right, name: 'top level right')
    r2 = FactoryGirl.create(:righter_right, hidden: false)
    r3 = FactoryGirl.create(:righter_right, hidden: nil)
    r4 = FactoryGirl.create(:righter_right, hidden: true)

    assert RighterRight.visible.sort, [r2, r3, r4].sort
  end

  test 'add_access_to controller/actions raises error if actions is not array or controller is nil' do
    r = righter_rights :kill
    assert_raise RighterError do
      r.add_access_to actions: :smth
    end

    assert_raise RighterError do
      r.add_access_to actions: [:smth]
    end

    assert_raise RighterError do
      r.add_access_to {}
    end

    assert_nothing_raised do
      r.add_access_to controller: :james, actions: [:bond]
      r2 = RighterRight.find_by_name :kill
      assert_equal :james, r2.controller.to_sym
      assert_equal [:bond], r2.actions
    end
  end

  test 'hierarchical browsing is based in parent_id' do
    r1 = RighterRight.create! name: '1'
    r11 = RighterRight.create! name: '11', parent_id: r1.id
    r12 = RighterRight.create! name: '12', parent_id: r1.id
    r121 = RighterRight.create! name: '121', parent_id: r12.id

    r2 = RighterRight.create! name: '2'

    r3 = RighterRight.create! name: '3'
    RighterRight.create! name: '31', parent_id: r3.id
    r32 = RighterRight.create! name: '32', parent_id: r3.id
    RighterRight.create! name: '321', parent_id: r32.id

    assert_equal [], ([r12, r11] - r1.children)
    assert_equal [], r11.children
    assert_equal [r121], r12.children
    assert_equal [], r121.children

    assert_equal [], r2.children
  end

  test 'raise ActiveRecord::RecordInvalid on attempt to create cycle in hierarchy of righter rights' do
    r1 = RighterRight.create! name: '1'
    r2 = RighterRight.create! name: '2', parent_id: r1.id
    r3 = RighterRight.create! name: '3', parent_id: r2.id

    assert_raise ActiveRecord::RecordInvalid do
      r1.parent_id = r3.id
      r1.save!
    end
  end

  test 'cached_find_by_name load the data only once' do
    RighterRight.clear_cache
    count_sql = count_queries do
      RighterRight.cached_find_by_name :kill
    end

    assert 1, count_sql

    count_no_sql = count_queries do
      RighterRight.cached_find_by_name :kill
    end

    assert 0, count_no_sql
  end
end
