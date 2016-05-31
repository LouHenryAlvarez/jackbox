=begin rdoc
	spec_helper
	author: Lou Henry
	:nodoc:all
=end

require 'rubygems'
require 'rspec'
require 'fileutils'



# decorate :system do |*args|
# 	pid = spawn(*args)
# 	Process.wait(pid, 0)
# end

def rfolder
	"#{ENV['HOME']}/tmp/jackbox/#{(0...10).map { ('a'..'z').to_a[rand(26)] }.join}"
end

RSpec.configure do |config|
	
	config.before(:suite) do
		require 'fileutils'
		@tmpdir  = rfolder()
		FileUtils.mkpath( @tmpdir )
		@old_dir = Dir.pwd
		Dir.chdir @tmpdir
	end

	# config.expect_with :rspec
	config.expect_with(:rspec) { |c| c.syntax = [:expect, :should] }
	config.treat_symbols_as_metadata_keys_with_true_values = true
	config.alias_example_to :they
	config.alias_example_to :there
	config.alias_example_to :this
	config.alias_example_to :these
	config.alias_example_to :a
	config.alias_example_to :an
	config.alias_example_to :the
	config.alias_example_to :but
	config.alias_it_behaves_like_to :behaves_like, 'behaves like:'
	config.alias_it_behaves_like_to :behaves_like_it, 'behaves like it:'
	config.alias_it_behaves_like_to :it_has_behavior, 'has behavior of:'
	config.alias_it_behaves_like_to :assure, 'assurance of condition:'
	config.alias_it_behaves_like_to :assure_it, 'assurance it had condition:'
	config.color=true
	config.full_backtrace=true
	# config.fail_fast = true
	#config.profile_examples=true
	# config.include FakeFS::SpecHelpers

	config.after(:suite) do
		Dir.chdir @old_dir
		@old_dir = nil
		FileUtils.rm_rf @tmpdir
		@tmpdir = nil
		require "fileutils"
	end

end



END {
	FileUtils.rm 'Ex*' rescue false
	FileUtils.rm '*uget' rescue false
	FileUtils.rm 'Pers*' rescue false
}



# stuff needed by all tests
require 'jackbox'
require 'jackbox/examples/dir'
# DX


puts '--------------------------------------Starting User Gem Spec------------------------------------------'
puts "Ruby Version: #{RUBY_VERSION} for #{RUBY_PLATFORM}"


