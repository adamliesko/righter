class Player < ActiveRecord::Base
  include RighterForResource

  def side
    'evil'
  end
end
