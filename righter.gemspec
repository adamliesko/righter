$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'righter/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'righter'
  s.version     = Righter::VERSION
  s.authors     = ['Adam Lieskovsky']
  s.email       = ['adamliesko@gmail.com']
  s.homepage    = ''
  s.summary     = 'Role based authorization security engine for your user model and resources.'
  s.description = ''
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '~> 4.2.4'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'coveralls'
end
