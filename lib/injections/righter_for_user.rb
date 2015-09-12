module RighterForUser
  include ActionView::Helpers::TextHelper
  extend ActiveSupport::Concern

  # when includes into an ActiveRecord::Model, creates associations for both model and RighterRole
  # class RighterRoleModel must exist
  included do
    model_sym = model_name.human(count: :many).to_s.underscore.to_sym
    model_plural_name = ActiveModel::Naming.plural(self)
    relation = "righter_roles_#{model_plural_name}".to_sym
    join_class = "RighterRoles#{self}".constantize

    # associate me with RighterRole
    has_many :righter_roles, -> { uniq }, through: relation
    has_many relation, dependent: :destroy

    # associate RighterRole with me
    RighterRole.send :has_many, relation, dependent: :destroy
    RighterRole.send :has_many, model_sym, through: relation, class_name: to_s
    RighterRole.send :has_many, model_plural_name.to_sym, through: relation, source: model_sym

    # associate _join_class_
    # FIXME: check for existing reflections?
    join_class.send :belongs_to, :righter_role
    join_class.send :belongs_to, model_name.to_s.underscore.to_sym
    join_class.send :has_many, model_plural_name.to_sym
  end

  # @return [Array<RighterRight>}
  # scope returning associated RighterrRights
  def righter_rights
    @@users_id ||= self.class.arel_table[:id]
    @@right_id ||= RighterRight.arel_table[:id]
    @@righter_user_class ||= ActiveModel::Naming.singular(self)
    right_ids = RighterRight.joins(righter_roles: @@righter_user_class).where(@@users_id.eq(id)).select(@@right_id).collect &:id
    RighterRight.where id: right_ids.uniq
  end

  def add_role(role)
    RighterRight.clear_cache
    if role.class != RighterRole
      fail RighterError.new("User.add_role accepts only RighterRole instance as input (provided :#{role.class.inspect})")
    end
    righter_roles << role
    save!
  end

  def remove_role(role)
    RighterRight.clear_cache
    if role.class != RighterRole
      fail RighterError.new("User.add_role accepts only RighterRole instance as input (provided :#{role.class.inspect})")
    end
    righter_roles.delete role
  end

  def righter_accessible?(opts = {})
    if opts[:resource]
      righter_accessible_resource? opts

    elsif opts[:role]
      righter_accessible_role? opts[:role]

    elsif opts[:right]
      righter_accessible_right? opts[:right]

    elsif opts[:controller] && opts[:action]
      righter_accessible_ca? opts[:controller], opts[:action]

    else
      fail RighterError.new("User.righter_accessible? expects as parameter role/right/controller+action. provided: #{opts.inspect}")
    end
  end

  def grantable_roles
    righter_roles.collect(&:grantable_roles).flatten
  end

  # should we raise RighterError when user is trying to break the grant rules ?
  def update_roles_with_respect_to_grants(list_of_roles)
    user_who_is_updating_roles = User.current_user
    user_whom_roles_will_be_updated = self

    RighterRight.clear_cache

    User.transaction do
      remove_all_roles_which_can_be_granted

      grantable_roles = user_who_is_updating_roles.grantable_roles
      list_of_roles.each do |role|
        if grantable_roles.include? role
          user_whom_roles_will_be_updated.add_role role
        end
      end
    end
  end

  def can?(right_name, resource)
    righter_accessible_resource?(right: right_name, resource: resource)
  end

  private

  def remove_all_roles_which_can_be_granted
    user_who_is_updating_roles = User.current_user
    user_whom_roles_will_be_updated = self

    user_who_is_updating_roles.grantable_roles.each do |grantable_role|
      if user_whom_roles_will_be_updated.righter_roles.include? grantable_role
        user_whom_roles_will_be_updated.remove_role grantable_role
      end
    end
  end

  def righter_accessible_resource?(opts)
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

    _righter_accessible_right?(right)
  end

  def righter_accessible_role?(role_name)
    unless [String, Symbol].include?(role_name.class)
      fail RighterError.new('User.righter_accessible? :role expects role_name as input')
    end
    all_user_role_names = righter_roles.collect { |r| r.name.to_sym }
    all_user_role_names.include? role_name
  end

  def righter_accessible_right?(right_name)
    unless [String, Symbol].include?(right_name.class)
      fail RighterError.new('User.righter_accessible? :right expects right_name as input')
    end

    r = RighterRight.cached_find_by_name right_name
    fail RighterError.new("cannot find righter_right with name #{right_name.inspect}") unless r

    _righter_accessible_right?(r)
  end

  def _righter_accessible_right?(right)
    fail RighterError.new('no right provided!') unless right

    righter_role_ids = RighterRightsRighterRole.where(righter_right_id: right.id).collect &:righter_role_id
    user_role_ids = righter_roles.collect &:id

    righter_role_ids.each do |righter_role_id|
      return true if user_role_ids.include?(righter_role_id)
    end

    false
  end

  def righter_accessible_ca?(controller, action)
    all_user_rights = righter_rights.where(controller: controller.to_s)
    all_user_rights.each do |user_right|
      if user_right.controller && user_right.actions
        if user_right.controller.to_sym == controller
          right_actions = user_right.actions.collect(&:to_sym)
          return true if right_actions.include?(action)

          right_actions.each do |right_action| # wildcards
            return true if right_action.to_s == '*'
            if right_action.to_s.include?('*')
              regex = right_action.to_s.gsub('*', '(.*)').gsub('/', '\/')
              regex_match_result = (action.match /#{regex}/)
              return true unless regex_match_result.nil?
            end
          end
        end
      end
    end

    false
  end
end
