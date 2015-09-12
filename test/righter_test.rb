require 'test_helper'

class RighterTest < ActiveSupport::TestCase
  test 'truth' do
    assert_kind_of Module, Righter
    assert_kind_of Class, RighterError
    assert_kind_of Class, RighterNoUserError
  end
end
