require 'righter/righter_accessible'

module RighterForUser
  include ActionView::Helpers::TextHelper
  include RighterAccessible
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
    RighterAccessible.righter_accessible?(self, opts)
  end

  def grantable_roles
    righter_roles.collect(&:grantable_roles).flatten
  end

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
    RighterAccessible.righter_accessible?(self, right: right_name, resource: resource)
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


end
