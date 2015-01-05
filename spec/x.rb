=begin rdoc
	spec_helper
	author: Lou Henry
	:nodoc:all
=end

require 'rubygems'
require 'rspec'
require 'fileutils'



END {
	FileUtils.rm 'Ex*' rescue false
	FileUtils.rm '*uget' rescue false
	FileUtils.rm 'Pers*' rescue false
}



module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
   (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and not OS.mac?
  end
end

def system *args
	pid = spawn(*args)
	Process.wait(pid, 0)
end

def launch program
	case
	when OS.windows?
		return system "ruby.exe", program if File.exists?(program)
		system "ruby.exe", '-e', program
	else
		return system "ruby", program if File.exists?(program)
		system "ruby", '-e', program
	end
end

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
	config.after(:suite) do
		Dir.chdir @old_dir
		@old_dir = nil
		FileUtils.rm_rf @tmpdir
		@tmpdir = nil
		require "fileutils"
	end

	config.expect_with :rspec
	config.treat_symbols_as_metadata_keys_with_true_values = true
	config.alias_it_behaves_like_to :behaves_like, 'behaves like:'
	config.alias_it_behaves_like_to :behaves_like_it, 'behaves like it:'
	config.alias_it_behaves_like_to :it_has_behavior, 'has behavior of:'
	config.alias_it_behaves_like_to :assure, 'assurance of condition:'
	config.alias_it_behaves_like_to :assure_it, 'assurance it had condition:'
	config.alias_example_to :they
	config.alias_example_to :there
	config.alias_example_to :this
	config.alias_example_to :these
	config.alias_example_to :a
	config.alias_example_to :an
	config.alias_example_to :the
	config.alias_example_to :but
	config.color=true
	config.full_backtrace=true
	# config.fail_fast = true
	#config.profile_examples=true
	# config.include FakeFS::SpecHelpers
end

# stuff needed by all tests
require 'jackbox'
require 'jackbox/examples/dir'
DX

# extend DX

describe 'ruby system independence' do
	# System Independence is accomplished by loading modules based on platform
	describe 'ruby version independence' do
	
		it 'works according to ruby version' do
			if RUBY_VERSION < '2.0.0'
				$".grep(/debugger/).should_not be_empty
			else
				$".grep(/byebug/).should_not be_empty
			end
		end
	
	end
	describe 'os independence', 'provided for by ruby itself' do
		
		case
		when OS.windows?
			it 'works on the windows platform' do
      	launch %{
					puts RUBY_VERSION
				}
				$?.exitstatus.should == 0
			end
		else
			it 'works on *nix platform' do
      	launch %{
					puts RUBY_VERSION
				}
				$?.exitstatus.should == 0
			end
		end
		
	end
	
end

