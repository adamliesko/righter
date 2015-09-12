require "#{File.dirname(__FILE__)}/righter_error.rb"
require "#{File.dirname(__FILE__)}/injections/righter_for_application_controller.rb"
require "#{File.dirname(__FILE__)}/injections/righter_for_user.rb"
require "#{File.dirname(__FILE__)}/injections/righter_for_resource.rb"

module Righter
  class Engine < Rails::Engine
  end
end
