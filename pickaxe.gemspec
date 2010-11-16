require 'bundler'

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/lib"))

require 'pickaxe'

spec = Gem::Specification.new do |s|
  s.name = 'Pickaxe'
  s.version = Pickaxe::VERSION
  s.summary = 'Pickaxe allows to run tests (bundle of questions) written in simple text format.'
  s.description = <<-EOF
    Pickaxe provides a simple way to load, solve and rate tests (bundle of questions)
    written in simple text format.
  EOF
  
  s.executables = ['pickaxe']
	s.required_ruby_version = '>= 1.8.7'
	s.extra_rdoc_files = ['README.markdown']

  s.authors = 'Dawid Fatyga'
  s.email = "dawid.fatyga@gmail.com"
  s.homepage = "https://github.com/dejw/pickaxe"
  
  s.add_dependency('bundler', '>= 1.0.3')
  s.add_bundler_dependencies
end

