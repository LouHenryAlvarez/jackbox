# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jackbox/version'

Gem::Specification.new do |spec|
  spec.name          = "jackbox"
  spec.version       = Jackbox::VERSION
  spec.authors       = ["Lou Henry Alvarez (LHA)"]
  spec.email         = ["luisealvarezb@yahoo.com"]
  spec.description   = %q{Main gem for Ruby Code Injectors: Closures as Modules}
  spec.summary       = %q{Jackbox is a set of programming tools which enhance the Ruby language and provide some additional software constructs. The main library function at this time centers around the concept of code injectors.  
}
  spec.homepage      = "https://github.com/LouHenryAlvarez/jackbox"
  spec.license       = "Copyright © 2014 LHA. All rights reserved."

  # spec.files         = `git ls-files -z`.split("\x0")
  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

	spec.add_development_dependency 'rspec', '~> 3.0', '>= 3.1.0'
	
	spec.add_runtime_dependency "bundler", "~> 1.6", '>= 1.6.1'
	spec.add_runtime_dependency 'thor', '~> 0.18', '>= 0.18.1'
	# spec.add_runtime_dependency 'ffi', '~> 1.7', '>= 1.7.1'

end
