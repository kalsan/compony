require 'bundler/gem_tasks'
require_relative 'lib/compony/version'

File.open('VERSION', 'w') { |f| f.puts(Compony::Version::LABEL) }

task :gemspec do
  specification = Gem::Specification.new do |s|
    s.name = 'compony'
    s.version = Compony::Version::LABEL
    s.author = ['Sandro Kalbermatter', 'contributors']
    s.summary = 'Compony is a Gem that allows you to write your Rails application in component-style fashion. It combines a controller action and route along \
    with its view into a single Ruby class. This allows writing much DRYer code, using inheritance even in views and much easier refactoring for your Rails \
    applications, helping you to keep the code clean as the application evolves.'
    s.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
    s.executables   = []
    s.require_paths = ['lib']
    s.required_ruby_version = '>= 3.0.0'

    # Dependencies
    s.add_development_dependency 'yard', '>= 0.9.28'
    s.add_development_dependency 'rubocop', '>= 1.48'
    s.add_development_dependency 'rubocop-rails', '>= 2.18.0'

    s.add_runtime_dependency 'rails', '>= 7.1.2'
    s.add_runtime_dependency 'request_store', '>= 1.5'
    s.add_runtime_dependency 'dyny', '>= 0.0.3'
    s.add_runtime_dependency 'schemacop', '>= 3.0.17'
    s.add_runtime_dependency 'simple_form', '>= 5.1.0'
    s.add_runtime_dependency 'dslblend', '>= 0.0.3'
    s.add_runtime_dependency 'anchormodel', '~> 0.2.0'
    s.add_runtime_dependency 'cancancan', '~> 3.4.0'
  end

  File.open('compony.gemspec', 'w') do |f|
    f.puts('# DO NOT EDIT')
    f.puts("# This file is auto-generated via: 'rake gemspec'.\n\n")
    f.write(specification.to_ruby.strip)
  end
end
