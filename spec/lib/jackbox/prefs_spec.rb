require "spec_helper"
=begin rdoc
	prefs_spec
	author: Lou Henry
	:nodoc:all
=end

include Injectors

describe 'what Prefs does' do

	it 'creates module level attribute methods' do
		module Tester
			extend Prefs
		
			pref :pref1 => 10
		end

		lambda{
			Tester.pref1.should == 10
			
			}.should_not raise_error()
		lambda{
			Tester.pref1=( 2 )
			
			}.should_not raise_error()
		Tester.pref1.should == 2
	end

	it 'should work the same on inclusion' do
		lambda {
			module Fester
				include Prefs
				
				pref :location => :file_system
			end
			}.should_not raise_error()
		Fester.location.should == :file_system
	end

	it 'allows resetting prefs to their original/default values' do
		module Jester
			extend Prefs
			
			pref :value => 10
		end
		Jester.value.should == 10
		Jester.value = 3
		Jester.value.should == 3
		Jester.reset :value
		Jester.value.should == 10 
	end

	it 'persists across processes' do
		# we run a process and make settings
		launch %{
			require 'jackbox'

			class Application
				include Prefs

				pref :data_path => "#{ENV['HOME']}/tmp/jackbox"

				def foo
				end
			end
			
			#...
			
			Application.data_path = "#{ENV['HOME']}/tmp/foo"
		}
		Process.waitall
		# After the previous invocation
		class Application
			include Prefs
			
			pref :data_path => "#{ENV['HOME']}/tmp/jackbox"
			
			def foo
			end
		end
		
		# ...
		
		Application.data_path.should == "#{ENV['HOME']}/tmp/foo"

		# ...

		Application.reset
		Application.data_path.should == "#{ENV['HOME']}/tmp/jackbox"
	end

	it 'should allow definition of prefs outside the module definition' do
		lambda{
			Tester.pref :new_prop => 3 
		
			}.should_not raise_error()
		Tester.pref :someprop => 'tester'
		
		lambda{
			Tester.someprop 
			
			}.should_not raise_error
		Tester.someprop.should == 'tester'
	end

	it 'should not pass-on definitions to descendants' do
		module Tester
			include Prefs
			pref :pref1 => 10
		end
		lambda{Tester.pref1}.should_not raise_error
		module Descendant
			include Tester
		end
		lambda{Descendant.pref1}.should raise_error
		module Child
			extend Tester
		end
		lambda{Child.pref1}.should raise_error
		class D
			include Tester
			extend Tester
		end
		lambda{D.pref1}.should raise_error
		lambda{D.new.pref1}.should raise_error
	end
	
	it 'should allow all of the following' do
	 lambda{
		module Master
			extend Prefs
			
			pref :tester => 10
		end

		Master.pref :boo => 45
		Master.boo = [23,45,32,56]
		Master.tester = 30
		Master.reset :tester
		Master.pref :second => 'second'
		Master.second = 'first'

		module Extras  
			extend Prefs

			pref :a => 10
			pref :reminders_on => true
			pref :interval => 60
			pref :log_file => "/d/workspace"
			pref :tester => :mary

			self.a = :b
			#TODO: problem: local variables override prefs
			a = 'c'
			self.reminders_on = false
			self.interval=45
		end
		}.should_not raise_error

		lambda {
		module Tester
			extend Prefs

			pref :foo => true
			pref :faa => :is_not_error
		end}.should_not raise_error
		Tester.foo.should == true
		Tester.faa.should == :is_not_error

	end

	it 'should also allow classes to be used' do
		class C
			extend Prefs

			pref :boo => "something"
		end
	  C.boo.should == 'something'  ##TODO:
		lambda{C.boo=(3)}.should_not raise_error
		lambda{C.new.boo}.should raise_error
	end

	it 'should be possible to reset the prefs to their defaults' do
		lambda{Tester.reset}.should_not raise_error
	end
	
	it 'should allow definition of prefs store location' do
		class One
			extend Prefs
			prefs_path 'spec/some_path'			
			
			pref :gaga => 3456
		end
		One.gaga.should == 3456
		
		File.should exist('spec/some_path/prefs')
	end
	
	the 'Prefs module also works with Injectors' do
		
		injector :prefs_tester do
			extend Prefs
			pref :some_pref => 'value'
		end
		
		prefs_tester.some_pref.should == 'value'
	end

end

