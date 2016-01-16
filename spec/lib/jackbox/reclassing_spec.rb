require "spec_helper"
=begin rdoc

	This file represents a different approach to refining a class using Jackbox Modular Closures.
	
	The examples are necessarily long because we are testing lifecycle changes for these construct.
	If we were to have simple unit testing we could have false positives form some of these tests.
	
	lha

=end

# RubyProf.start
describe 're-classes' do

	it 'refines classes within namespaces' do
		
		module Work
			lets String do
				def self.new(*args)
					"+++#{super}+++"
				end
			end
		end
		
		class WorkAholic
			include Work
			
			def work_method
				String('Men-At-Work')
			end
		end
	
		str = WorkAholic.new.work_method
		str.should == '+++Men-At-Work+++'
		
		str = String('Men-At-Work')										# Regular Kernel version
		str = 'Men-At-Work'
		
		str = String.new('Men-At-Work')								# Regular class version
		str = 'Men-At-Work'
		
	end
	
	describe "interaction with Ruby Code Injector" do
		before do
			#
			# Our first Injector
			#
			Sr1 = jack :StringRefinements do
				lets String do
					def self.new *args, &code
						super + ' is a special string'
					end
				end
			end

			#
			# A second injector in the mix
			#
			jack :Log do
				require 'logger'
				def to_log arg
					(@log ||= Logger.new($stdout)).warn(arg)
				end
			end

			#
			# refine our re-class
			StringRefinements do
				String() do 											# add function to same String() reclass
					inject Log()
					
					def glow
						to_log self
					end
					def foo
					end
				end
			end

			# 
			# lets redfine our first String() 
			# -- SR1 and SR2 are different injectable String()
			# 
			Sr2 = StringRefinements do 										# New String refinement
				lets String do
					inject Log()
					def self.new *args, &code
						'--' + super + '--'
					end
					def glow
						to_log self
					end
				end
			end
			
			#
			# refine our re-class
			StringRefinements do
				String() do 											# add function to same String() reclass
					# inject Log()
					# 				
					# def glow
					# 	to_log self
					# end
					def foo
					end
				end
			end
			
		end
		after do
			StringRefinements(:implode)
		end


		it 'works with Ruby Code Injectors' do

			
			class OurClass
				include Sr1												# Apply Tag
			
				def foo_bar
					String('foo and bar')
				end
			end
			
			c = OurClass.new
					
			# test it with our object
			c.foo_bar.should == 'foo and bar is a special string'
			c.foo_bar.class.should == String
			
			# test stdout
			$stdout.should_receive(:write).with(/foo and bar is a special string/).at_least(1) 
			c.foo_bar.glow


			class OurOtherClass
				include Sr2											# Apply other tag
			
				def foo_bar
					String('foo and bar')
				end
			end
					
			d = OurOtherClass.new
					
			# test it with our object
			d.foo_bar.should == '--foo and bar--'
			d.foo_bar.class.should == String
			
			# test stdout
			$stdout.should_receive(:write).with(/foo and bar--/).at_least(1) 
			d.foo_bar.glow
					
			#
			# c is still the same
			#
			c.foo_bar.should == 'foo and bar is a special string'
			c.foo_bar.class.should == String
					
			#
			# String is untouched
			#
			String("foo").should == 'foo'
			String.new("foo").should == 'foo'
			
		end

		# introspecting on capabilities
		
		it 'should allow injector introspection' do

			StringRefinements do
				(reclass? String).should == true

				if reclass? String
					String() do
						injectors.by_name.should == [:Log]
					end
				else
					lets String do
						#...
					end
				end
			end
		
			class SRClass
				inject StringRefinements()
		
				def m1
					String('m1')
				end
			end
		
			SRClass.new.m1.should == '--m1--'
		
		end

		it 'should allow injector introspection' do
			
			lets Array do
				inject jack :ArrayExtensions do
					def to_s
						super + '--boo'
					end
				end
			end
			
			# re-class
			Array() do
				injectors.by_name.should == [:ArrayExtensions]
			end
		
			Array(){injectors.by_name}.should == [:ArrayExtensions]
		
			# re-class instances
			Array(1).injectors.by_name == [:ArrayExtensions]
			
			Array(2).to_s.should == '[nil, nil]--boo'
		
		end
		
	end
end


