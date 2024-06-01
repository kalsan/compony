# DO NOT EDIT
# This file is auto-generated via: 'rake gemspec'.

# -*- encoding: utf-8 -*-
# stub: compony 0.3.3.edge ruby lib

Gem::Specification.new do |s|
  s.name = "compony".freeze
  s.version = "0.3.3.edge".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sandro Kalbermatter".freeze, "contributors".freeze]
  s.date = "2024-06-01"
  s.files = [".gitignore".freeze, ".ruby-version".freeze, ".yardopts".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "Gemfile.lock".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "TODO.md".freeze, "VERSION".freeze, "app/controllers/compony_controller.rb".freeze, "compony.gemspec".freeze, "config/locales/de.yml".freeze, "config/locales/en.yml".freeze, "config/locales/fr.yml".freeze, "config/routes.rb".freeze, "doc/ComponentGenerator.html".freeze, "doc/Components.html".freeze, "doc/ComponentsGenerator.html".freeze, "doc/Compony.html".freeze, "doc/Compony/Component.html".freeze, "doc/Compony/ComponentMixins.html".freeze, "doc/Compony/ComponentMixins/Default.html".freeze, "doc/Compony/ComponentMixins/Default/Labelling.html".freeze, "doc/Compony/ComponentMixins/Default/Standalone.html".freeze, "doc/Compony/ComponentMixins/Default/Standalone/ResourcefulVerbDsl.html".freeze, "doc/Compony/ComponentMixins/Default/Standalone/StandaloneDsl.html".freeze, "doc/Compony/ComponentMixins/Default/Standalone/VerbDsl.html".freeze, "doc/Compony/ComponentMixins/Resourceful.html".freeze, "doc/Compony/Components.html".freeze, "doc/Compony/Components/Button.html".freeze, "doc/Compony/Components/Destroy.html".freeze, "doc/Compony/Components/Edit.html".freeze, "doc/Compony/Components/Form.html".freeze, "doc/Compony/Components/New.html".freeze, "doc/Compony/Components/WithForm.html".freeze, "doc/Compony/ControllerMixin.html".freeze, "doc/Compony/Engine.html".freeze, "doc/Compony/MethodAccessibleHash.html".freeze, "doc/Compony/ModelFields.html".freeze, "doc/Compony/ModelFields/Anchormodel.html".freeze, "doc/Compony/ModelFields/Association.html".freeze, "doc/Compony/ModelFields/Attachment.html".freeze, "doc/Compony/ModelFields/Base.html".freeze, "doc/Compony/ModelFields/Boolean.html".freeze, "doc/Compony/ModelFields/Color.html".freeze, "doc/Compony/ModelFields/Currency.html".freeze, "doc/Compony/ModelFields/Date.html".freeze, "doc/Compony/ModelFields/Datetime.html".freeze, "doc/Compony/ModelFields/Decimal.html".freeze, "doc/Compony/ModelFields/Email.html".freeze, "doc/Compony/ModelFields/Float.html".freeze, "doc/Compony/ModelFields/Integer.html".freeze, "doc/Compony/ModelFields/Percentage.html".freeze, "doc/Compony/ModelFields/Phone.html".freeze, "doc/Compony/ModelFields/RichText.html".freeze, "doc/Compony/ModelFields/String.html".freeze, "doc/Compony/ModelFields/Text.html".freeze, "doc/Compony/ModelFields/Time.html".freeze, "doc/Compony/ModelFields/Url.html".freeze, "doc/Compony/ModelMixin.html".freeze, "doc/Compony/NaturalOrdering.html".freeze, "doc/Compony/RequestContext.html".freeze, "doc/Compony/Version.html".freeze, "doc/Compony/ViewHelpers.html".freeze, "doc/ComponyController.html".freeze, "doc/_index.html".freeze, "doc/class_list.html".freeze, "doc/css/common.css".freeze, "doc/css/full_list.css".freeze, "doc/css/style.css".freeze, "doc/file.README.html".freeze, "doc/file_list.html".freeze, "doc/frames.html".freeze, "doc/imgs/intro-example-destroy.png".freeze, "doc/imgs/intro-example-edit.png".freeze, "doc/imgs/intro-example-index.png".freeze, "doc/imgs/intro-example-new.png".freeze, "doc/imgs/intro-example-show.png".freeze, "doc/index.html".freeze, "doc/js/app.js".freeze, "doc/js/full_list.js".freeze, "doc/js/jquery.js".freeze, "doc/method_list.html".freeze, "doc/resourceful_lifecycle.graphml".freeze, "doc/resourceful_lifecycle.pdf".freeze, "doc/resourceful_lifecycle.png".freeze, "doc/top-level-namespace.html".freeze, "lib/compony.rb".freeze, "lib/compony/component.rb".freeze, "lib/compony/component_mixins/default/labelling.rb".freeze, "lib/compony/component_mixins/default/standalone.rb".freeze, "lib/compony/component_mixins/default/standalone/resourceful_verb_dsl.rb".freeze, "lib/compony/component_mixins/default/standalone/standalone_dsl.rb".freeze, "lib/compony/component_mixins/default/standalone/verb_dsl.rb".freeze, "lib/compony/component_mixins/resourceful.rb".freeze, "lib/compony/components/button.rb".freeze, "lib/compony/components/destroy.rb".freeze, "lib/compony/components/edit.rb".freeze, "lib/compony/components/form.rb".freeze, "lib/compony/components/new.rb".freeze, "lib/compony/components/with_form.rb".freeze, "lib/compony/controller_mixin.rb".freeze, "lib/compony/engine.rb".freeze, "lib/compony/method_accessible_hash.rb".freeze, "lib/compony/model_fields/anchormodel.rb".freeze, "lib/compony/model_fields/association.rb".freeze, "lib/compony/model_fields/attachment.rb".freeze, "lib/compony/model_fields/base.rb".freeze, "lib/compony/model_fields/boolean.rb".freeze, "lib/compony/model_fields/color.rb".freeze, "lib/compony/model_fields/currency.rb".freeze, "lib/compony/model_fields/date.rb".freeze, "lib/compony/model_fields/datetime.rb".freeze, "lib/compony/model_fields/decimal.rb".freeze, "lib/compony/model_fields/email.rb".freeze, "lib/compony/model_fields/float.rb".freeze, "lib/compony/model_fields/integer.rb".freeze, "lib/compony/model_fields/percentage.rb".freeze, "lib/compony/model_fields/phone.rb".freeze, "lib/compony/model_fields/rich_text.rb".freeze, "lib/compony/model_fields/string.rb".freeze, "lib/compony/model_fields/text.rb".freeze, "lib/compony/model_fields/time.rb".freeze, "lib/compony/model_fields/url.rb".freeze, "lib/compony/model_mixin.rb".freeze, "lib/compony/natural_ordering.rb".freeze, "lib/compony/request_context.rb".freeze, "lib/compony/version.rb".freeze, "lib/compony/view_helpers.rb".freeze, "lib/generators/component/USAGE".freeze, "lib/generators/component/component_generator.rb".freeze, "lib/generators/component/templates/component.rb.erb".freeze, "lib/generators/component/templates/destroy.rb.erb".freeze, "lib/generators/component/templates/edit.rb.erb".freeze, "lib/generators/component/templates/form.rb.erb".freeze, "lib/generators/component/templates/new.rb.erb".freeze, "lib/generators/components/USAGE".freeze, "lib/generators/components/components_generator.rb".freeze, "logo.svg".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.5.9".freeze
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
  s.add_runtime_dependency(%q<anchormodel>.freeze, ["~> 0.2.0".freeze])
  s.add_runtime_dependency(%q<cancancan>.freeze, ["~> 3.4.0".freeze])
end