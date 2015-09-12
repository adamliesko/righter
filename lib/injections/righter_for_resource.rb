module RighterForResource
  extend ActiveSupport::Concern

  included do
    extend ClassMethodsForActiveRecord if ancestors.include?(ActiveRecord::Base)
  end

  module ClassMethods
    def create_righter_right(right_name_prefix, options = {})
      options[:resource] = self unless options[:resource].present?
      resource = options[:resource]
      if options[:parent_right]
        if options[:parent_right].is_a? Proc
          parent_right = options[:parent_right].call(resource)
        else
          parent_right = options[:parent_right]
        end

        parent = RighterRight.cached_find_by_name(parent_right) if parent_right
      end

      right = RighterRight.create(name: right_name(right_name_prefix, options),
                                  resource_class: resource.righter_right_resource_class,
                                  resource_id: resource.righter_right_resource_id,
                                  hidden: false,
                                  parent: parent,
                                  human_name: resource.righter_right_human_name(right_name_prefix))

      if options[:auto_associate_roles]
        options[:auto_associate_roles].each do |role_name|
          role = RighterRole.find_by_name(role_name)
          role.add_right(right)
        end
      end
      right
    end

    def destroy_righter_right(right_name_prefix, options = {})
      righter_right(right_name_prefix, options).destroy
    end

    def righter_right(right_name_prefix, options = {})
      RighterRight.cached_find_by_name(right_name(right_name_prefix, options))
    end

    def righter_right_resource_class
      name # name of the class
    end

    def righter_right_resource_id
      nil # class resources have no explicit ID
    end

    def righter_right_human_name(right_name_prefix)
      "#{right_name_prefix} #{righter_right_resource_class} #{righter_right_resource_id}"
    end

    private

    def right_name(right_name_prefix, options = {})
      unless right_name_prefix.present?
        fail RighterArgumentError.new('No prefix for righter_right name provided...')
      end
      resource = options[:resource]
      resource ||= self
      resource_class = resource.righter_right_resource_class
      resource_id = resource.righter_right_resource_id
      resource_id.present? ? "#{right_name_prefix}_#{resource_class}_#{resource_id}" : "#{right_name_prefix}_#{resource_class}"
    end
  end

  def create_righter_right(right_name_prefix, options = {})
    options = options.merge(resource: self)
    self.class.create_righter_right(right_name_prefix, options)
  end

  def destroy_righter_right(right_name_prefix, options = {})
    options = options.merge(resource: self)
    self.class.destroy_righter_right(right_name_prefix, options)
  end

  def righter_right(right_name_prefix, options = {})
    options = options.merge(resource: self)
    self.class.righter_right(right_name_prefix, options)
  end

  def righter_right_resource_class
    self.class.name
  end

  def righter_right_resource_id
    return id if respond_to?(:id)
    fail RighterError.new("Don't know how to compute instance_id for resource role. Please implement righter_right_resource_id method for this resource.")
  end

  def righter_right_human_name(right_name_prefix)
    "#{right_name_prefix} #{righter_right_resource_class} #{righter_right_resource_id}"
  end

  module ClassMethodsForActiveRecord
    def auto_manage_righter_right(right_name_prefix, options = {})
      unless right_name_prefix.present?
        fail RighterArgumentError.new('No prefix for autocreated right name provided...')
      end

      after_create { create_righter_right(right_name_prefix, options) } # called on instance level
      before_destroy { destroy_righter_right(right_name_prefix, options) } # called on instance level
    end
  end
end
