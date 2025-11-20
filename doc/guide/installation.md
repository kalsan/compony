[Back to the guide](/README.md#guide)

# Installation

## Installing Compony

First, add Compony to your Gemfile:

```ruby
gem 'compony'
```

Then run `bundle install`.

Create the directory `app/components`.

In `app/models/application_record.rb`, add the following line below `primary_abstract_class`:

```ruby
include Compony::ModelMixin
```

## Installing CanCanCan

Create the file `app/models/ability.rb` with the following content:

```ruby
class Ability
  include CanCan::Ability

  def initialize(_user)
    can :manage, :all
  end
end
```

This is an initial dummy ability that allows anyone to do anything. Most likely, you will want to adjust the file. For documentation, refer to [https://github.com/CanCanCommunity/cancancan/](https://github.com/CanCanCommunity/cancancan/).

## Optional: installing anchormodel

To take advantage of the anchormodel integration, follow the installation instructions under [https://github.com/kalsan/anchormodel/](https://github.com/kalsan/anchormodel/).

## Optional: installing `active_type`

To take advantage of [virtual models](./virtual_models.md) through the `active_type` integration, follow the instructions under [https://github.com/makandra/active_type](https://github.com/makandra/active_type)