# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jackbox/version'

Gem::Specification.new do |spec|
  spec.name          = "jackbox"
  spec.version       = Jackbox::VERSION
  spec.authors       = ["Lou Henry Alvarez (LHA)"]
  spec.email         = ["luisealvarezb@yahoo.com"]
  spec.description   = %q{Collection of tools and utilities for programming and other tasks -- main gem for Injectors.}
  spec.summary       = %q{Jackbox is a set of programming tools which enhance the Ruby language or provide some additional software constructs.  

	The main library function at this time centers around the concept of code injectors.  With them it is possible to solve several general problems and Ruby shortcomings in the area of OOP according to the GOF standard. If the GOF standard is not relevant to your work perhaps you're better off looking at how they provide the ability to inject and withdraw code at will.  This makes things like conditional code injection a trivial matter.}
  spec.homepage      = "https://github.com/LouHenryAlvarez/jackbox"
  spec.license       = "Copyright © 2014 LHA. All rights reserved."

  # spec.files         = `git ls-files -z`.split("\x0")
  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

	spec.add_development_dependency 'rspec', '~> 3.0.0', '>= 3.0'
	
	spec.add_runtime_dependency "bundler", "~> 1.6", '>= 1.6'
	spec.add_runtime_dependency 'thor', '~> 0.18.1', '>= 0.18'
	spec.add_runtime_dependency 'ffi', '~> 1.7', '>=1.7.0'

end
