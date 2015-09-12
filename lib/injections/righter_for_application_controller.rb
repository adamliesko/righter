module RighterForApplicationController
  def self.included(controller_klass)
    controller_klass.before_filter :enforce_righter
  end

  def enforce_righter
    u = righter_user
    fail RighterNoUserError.new unless u
    c = params[:controller].to_sym
    a = params[:action].to_sym
    unless u.righter_accessible?(controller: c, action: a)
      fail RighterError.new("user #{u.login} is trying to reach prohibited content: #{c}/#{a}")
    end
  end

  def enforce_resource_security(right_name, resource, options = {}) # currently need to call this manually as soon as the instance of the resource is retrieved in the controller action
    u = righter_user
    fail RighterNoUserError.new unless u

    options.merge!(resource: resource, right: right_name)
    unless u.righter_accessible?(options)
      fail RighterError.new("user #{u.login} is not authorized to '#{right_name}' resource #{resource.inspect}")
    end
  end

  # Override this method in your application
  # @return [User]
  def righter_user
    User.current_user
  end
end
