module RighterAccessible
  extend self

  def self.righter_accessible?(user, opts = {})
    if opts[:resource]
      righter_accessible_resource? user, opts

    elsif opts[:role]
      righter_accessible_role? user, opts[:role]

    elsif opts[:right]
      righter_accessible_right? user, opts[:right]

    elsif opts[:controller] && opts[:action]
      righter_accessible_ca? user.righter_rights.where(controller: opts[:controller].to_s), opts[:action]

    else
      fail RighterError.new("User.righter_accessible? expects as parameter role/right/controller+action. provided: #{opts.inspect}")
    end
  end

  private

  def righter_accessible_resource?(user, opts)
    resource = opts[:resource]
    fail RighterError('cannot check rights for nil resource') unless resource

    unless opts[:right]
      fail RighterError.new('option :right is missing - which right should be checked on a resource?')
    end

    unless resource.respond_to?(:righter_right)
      fail RighterError('cannot check rights for resource which does not respond to righter_right method')
    end

    right = resource.righter_right(opts[:right], opts)
    fail RighterError.new("cannot find resource right #{opts[:right].inspect} for resource #{opts[:resource].inspect}") unless right

    _righter_accessible_right?(user, right)
  end

  def righter_accessible_role?(user, role_name)
    unless [String, Symbol].include?(role_name.class)
      fail RighterError.new('User.righter_accessible? :role expects role_name as input')
    end
    all_user_role_names = user.righter_roles.map{ |r| r.name.to_sym }
    all_user_role_names.include? role_name
  end

  def righter_accessible_right?(user, right_name)
    unless [String, Symbol].include?(right_name.class)
      fail RighterError.new('User.righter_accessible? :right expects right_name as input')
    end

    r = RighterRight.cached_find_by_name right_name
    fail RighterError.new("cannot find righter_right with name #{right_name.inspect}") unless r

    _righter_accessible_right?(user, r)
  end

  def _righter_accessible_right?(user,right)
    fail RighterError.new('no right provided!') unless right

    righter_role_ids = RighterRightsRighterRole.where(righter_right_id: right.id).collect &:righter_role_id
    user_role_ids = user.righter_roles.map(&:id)

    righter_role_ids.each do |righter_role_id|
      return true if user_role_ids.include?(righter_role_id)
    end

    false
  end

  def righter_accessible_ca?(righter_rights, action)
    righter_rights.map { |user_right| user_right.actions.collect(&:to_sym) }.each do |right_actions|
      return true if right_actions.include?(action)
      return true if match_right_actions_action(right_actions, action)
    end

    false
  end

  def match_right_actions_action(right_actions, action)
    right_actions.each do |right_action| # wildcards
      return true if right_action.to_s == '*'
      if right_action.to_s.include?('*')
        regex = right_action.to_s.gsub('*', '(.*)').gsub('/', '\/')
        return true if action.match /#{regex}/
      end
    end

    false
  end
end