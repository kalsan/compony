require 'bundler/gem_tasks'
require_relative 'lib/compony/version'

task :gemspec do
  specification = Gem::Specification.new do |s|
    s.name = 'compony'
    s.version = Compony::Version::LABEL
    s.author = ['Sandro Kalbermatter', 'contributors']
    s.summary = 'Needs summary'
    s.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
    s.executables   = []
    s.require_paths = ['lib']
    s.required_ruby_version = '>= 3.0.0'

    # Dependencies
    # TODO: dslblend
  end

  File.open('compony.gemspec', 'w') do |f|
    f.puts('# DO NOT EDIT')
    f.puts("# This file is auto-generated via: 'rake gemspec'.\n\n")
    f.write(specification.to_ruby.strip)
  end
end
