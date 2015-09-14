
# Righter
[![Gem Version](https://badge.fury.io/rb/righter.svg)](http://badge.fury.io/rb/righter)
[![Build Status](https://travis-ci.org/adamliesko/righter.svg)](https://travis-ci.org/adamliesko/righter)
[![Coverage Status](https://coveralls.io/repos/adamliesko/righter/badge.svg?branch=master&service=github)](https://coveralls.io/github/adamliesko/righter?branch=master)
[![Codeclimate](https://d3s6mut3hikguw.cloudfront.net/github/adamliesko/righter/badges/gpa.svg)](https://d3s6mut3hikguw.cloudfront.net/github/adamliesko/righter/badges/gpa.svg)
[![CI Docs](https://inch-ci.org/github/adamliesko/righter.svg?branch=master)](https://inch-ci.org/github/adamliesko/righter.svg?branch=master)
[![Join the chat at https://gitter.im/adamliesko/righter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/adamliesko/righter?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Righter is a Ruby on Rails security engine, which is based on `Roles`, `Resources` and `User` models. You can think of it as ab authorization engine, that provides somewhat similar features to the [Pundit](https://github.com/elabs/pundit) and [cancancan](https://github.com/CanCanCommunity/cancancan) albeit from a very different viewpoint. The difference is that Righter allows you to define those rights on the database level and tie them up to your User model (which can be in fact any Model). With Righter you can restrict and control access on the `resource_class` level or `resource_id` level as you will see in the examples. Currently on version `0.0.1 `only `ActiveRecord` is supported. 

## Installation
In **Rails 4 and 5**, add this to your Gemfile and run the `bundle install` command.
```ruby
    gem 'righter', '~> 0.0.1'
```
  
## Getting Started
Righter bring two important models into the game - `RighterRole` and `RighterRight`. The third one, which roles and rights are associated with is your `User` model (abstract) - that you can specify to be for example `Subscriber` or `Player`.

### User
Righter expects from your user model to define a `.current_user` method that should represent the current user interacting with the application whether it is in case of rights and role management or in any other case. As mentioned previously you can safely use any other of your Models to act as a `User` in Righter. By including `RighterForUser` you enable RIghter to provide you the relation with roles and whole right management.

```ruby
class User < ActiveRecord::Base
  include RighterForUser
  cattr_accessor :current_user
end
```
Most probably you would like to add or remove roles and check whether a `User` has a right to do concrete action on a certain `Resource`. For these use cases Righter provides `add_role`, `remove_role` and `can?` methods.


### Controller
The general idea behind Controller addition is to include it directly to your `ApplicationController`, hence the name of the module `RighterForApplicationController`. 
```ruby
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include RighterForApplicationController
end
```

This Controller addition brings up two useful methods `enforce_righter` and `enforce_resource_security`. The `enforce_righter` is implemented as a `before_filter`/`before_action` method,  which automatically checks for a certain `User` whether he can access this concrete controller `action`. There are situations in which you would probably prefer to skip these filter - e.g. - unsigned user, public page etc. What need a more closer look from you as a developer is method `enforce_resource security` which acts as a `load_and_authorize_resource` in [cancancan](https://github.com/CanCanCommunity/cancancan) .

```ruby
class SongsController < ApplicationController
  def show
    @song = Song.find(params[:id])
  end

  def play
    @song = Song..find(params[:id])
    enforce_resource_security(:play, @song)
    render :play
  end

  def promote
    @song = Song.find(params[:id])
    enforce_resource_security(:promote, @song)
    render :promote
  end
end
```


### Resource
In your Resource models you have to inject `RighterForResource` module.
```ruby
class Song < ActiveRecord::Base
  include RighterForResource
```
In order to enable advanced and convenient feature of auto management of rights, go ahead and use `auto_manage_righter_right` method with right's name. By default, the right is created and destroyed automatically for each of your `RighterRoles` on respective occasions. With the `auto_associate_roles` option you can specify an array of names of your `RighterRoles` for which you want to enable the `auto_manage_righter_right` method.

```ruby
 class Song < ActiveRecord::Base
   include RighterForResource
   auto_manage_righter_right :play
   auto_manage_righter_right :promote, auto_associate_roles: [:admin, :vip]
```
Righter allows you to nest and structure your rights as a tree with the use of a `parent_right` option, which also accepts a lambda block of code to define the `parent_right`.
```ruby
auto_manage_righter_right :delete, parent_right: ->(song) { song.album.righter_right(:build).name }
```

For a more detailed and concrete example of righter usage, please do take a look at the [dummy app](https://github.com/adamliesko/righter/tree/master/test/dummy) located in the tests folder. For explanation of some of the edge use cases consider the tests.

### Errors
Righter implements three separate Exceptions, which are always being filled with detailed and descriptive message to help you figure out your trouble. 
```ruby
class RighterError < StandardError
end

class RighterArgumentError < StandardError
end

class RighterNoUserError < RighterError
end
```
## I want to help! Contributions guide

1. [Clone the repo](https://help.github.com/articles/importing-a-git-repository-using-the-command-line/).
2. [Create a separate branch](https://github.com/Kunena/Kunena-Forum/wiki/Create-a-new-branch-with-git-and-manage-branches) (to prevent unrelated updates).
3. Apply your changes.
4. [Create a pull request](https://help.github.com/articles/creating-a-pull-request/).
5. Describe what has been done.

### License
The MIT License.
