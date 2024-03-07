# DO NOT EDIT
# This file is auto-generated via: 'rake gemspec'.

# -*- encoding: utf-8 -*-
# stub: compony 0.2.2.edge ruby lib

Gem::Specification.new do |s|
  s.name = "compony".freeze
  s.version = "0.2.2.edge".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sandro Kalbermatter".freeze, "contributors".freeze]
  s.date = "2024-03-07"
  s.files = [".gitignore".freeze, ".ruby-version".freeze, ".yardopts".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "Gemfile.lock".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "app/controllers/compony_controller.rb".freeze, "compony.gemspec".freeze, "config/locales/de.yml".freeze, "config/locales/en.yml".freeze, "config/locales/fr.yml".freeze, "config/routes.rb".freeze, "doc/imgs/intro-example-destroy.png".freeze, "doc/imgs/intro-example-edit.png".freeze, "doc/imgs/intro-example-index.png".freeze, "doc/imgs/intro-example-new.png".freeze, "doc/imgs/intro-example-show.png".freeze, "doc/resourceful_lifecycle.graphml".freeze, "doc/resourceful_lifecycle.pdf".freeze, "doc/resourceful_lifecycle.png".freeze, "lib/compony.rb".freeze, "lib/compony/component.rb".freeze, "lib/compony/component_mixins/default/labelling.rb".freeze, "lib/compony/component_mixins/default/standalone.rb".freeze, "lib/compony/component_mixins/default/standalone/resourceful_verb_dsl.rb".freeze, "lib/compony/component_mixins/default/standalone/standalone_dsl.rb".freeze, "lib/compony/component_mixins/default/standalone/verb_dsl.rb".freeze, "lib/compony/component_mixins/resourceful.rb".freeze, "lib/compony/components/button.rb".freeze, "lib/compony/components/destroy.rb".freeze, "lib/compony/components/edit.rb".freeze, "lib/compony/components/form.rb".freeze, "lib/compony/components/new.rb".freeze, "lib/compony/components/with_form.rb".freeze, "lib/compony/controller_mixin.rb".freeze, "lib/compony/engine.rb".freeze, "lib/compony/method_accessible_hash.rb".freeze, "lib/compony/model_fields/anchormodel.rb".freeze, "lib/compony/model_fields/association.rb".freeze, "lib/compony/model_fields/attachment.rb".freeze, "lib/compony/model_fields/base.rb".freeze, "lib/compony/model_fields/boolean.rb".freeze, "lib/compony/model_fields/color.rb".freeze, "lib/compony/model_fields/currency.rb".freeze, "lib/compony/model_fields/date.rb".freeze, "lib/compony/model_fields/datetime.rb".freeze, "lib/compony/model_fields/decimal.rb".freeze, "lib/compony/model_fields/email.rb".freeze, "lib/compony/model_fields/float.rb".freeze, "lib/compony/model_fields/integer.rb".freeze, "lib/compony/model_fields/percentage.rb".freeze, "lib/compony/model_fields/phone.rb".freeze, "lib/compony/model_fields/rich_text.rb".freeze, "lib/compony/model_fields/string.rb".freeze, "lib/compony/model_fields/text.rb".freeze, "lib/compony/model_fields/time.rb".freeze, "lib/compony/model_fields/url.rb".freeze, "lib/compony/model_mixin.rb".freeze, "lib/compony/request_context.rb".freeze, "lib/compony/version.rb".freeze, "lib/compony/view_helpers.rb".freeze, "lib/generators/component/USAGE".freeze, "lib/generators/component/component_generator.rb".freeze, "lib/generators/component/templates/component.rb.erb".freeze, "lib/generators/component/templates/destroy.rb.erb".freeze, "lib/generators/component/templates/edit.rb.erb".freeze, "lib/generators/component/templates/form.rb.erb".freeze, "lib/generators/component/templates/new.rb.erb".freeze, "lib/generators/components/USAGE".freeze, "lib/generators/components/components_generator.rb".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.5.5".freeze
  s.summary = "Compony is a Gem that allows you to write your Rails application in component-style fashion. It combines a controller action and route along \\ with its view into a single Ruby class. This allows writing much DRYer code, using inheritance even in views and much easier refactoring for your Rails \\ applications, helping you to keep the code clean as the application evolves.".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<yard>.freeze, [">= 0.9.28".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 1.48".freeze])
  s.add_development_dependency(%q<rubocop-rails>.freeze, [">= 2.18.0".freeze])
  s.add_runtime_dependency(%q<rails>.freeze, [">= 7.1.2".freeze])
  s.add_runtime_dependency(%q<request_store>.freeze, [">= 1.5".freeze])
  s.add_runtime_dependency(%q<dyny>.freeze, [">= 0.0.3".freeze])
  s.add_runtime_dependency(%q<schemacop>.freeze, [">= 3.0.17".freeze])
  s.add_runtime_dependency(%q<simple_form>.freeze, [">= 5.1.0".freeze])
  s.add_runtime_dependency(%q<dslblend>.freeze, [">= 0.0.3".freeze])
  s.add_runtime_dependency(%q<anchormodel>.freeze, ["~> 0.1.2".freeze])
  s.add_runtime_dependency(%q<cancancan>.freeze, ["~> 3.4.0".freeze])
end