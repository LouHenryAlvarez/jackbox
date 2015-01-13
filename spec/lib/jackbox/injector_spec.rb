require "spec_helper"
=begin rdoc

	Injector_spec
	author: Lou Henry
	
	Injectors are like modules; they can be extended or included in other modules, but
	exhibit some additional functionality not present in modules.  
	
	# This class provides a sub-namespace container with some particular properties.  Injectors
	# are like modules in that they hold a set of methods pertaining to a certain domain, but have a slightly different
	# syntax and semantics.  They create a namespace which in addition to the regular Module defined properties also 
	# has the ability to dynamically inject more methods into its targets, to then either completely remove that 
	# funcionality, simply quiet it down, or to camouflage it until needed.  It allows the solution of problems 
	# like not being able to have additive decorators, or the creation of functionality to be used only once or while 
	# starting or debugging and then the cancellation of that functionality.  See DX(eXtra Dude) dubugger help injector
	# for an example.  Also refer to specs for examples.  
	# 
	# 
	# ==Features:
	# * Like modules but with slightly different syntax and semantics
	# * Add and remove code dynamically on all injected objects just by calling a method
	# * Add and remove more code afterwards just calling same method
	# * Enable to remove code from individual objects or all of them
	# * Have special ops to implode, collapse, and go silent
	# * Endow all methods or a subset with cross-concern user code 
	# * Injectors also work as modules 
	
=end

include Injectors

describe Injectors, :injectors do

	describe :injector do
		it 'creates the injector function' do
			class Bar
			end
			Bar.should respond_to :injector
		end
		it 'returns an instance of Injector' do
			injector(:code_injector).class.should == Injector
		end
	end

	#####
	# Syntax differences

	describe 'syntax differences: ' do

		describe 'One of the main differences is in how injectors are declared using a method from the injectors
		module and a block. Thsy can later be included or extended into a class or module.  They can moreover
		be used to #inject or #enrich into a class or module' do

			it 'is declared like so...'do
			
				expect {
					
					
					injector :my_injector # &blk
				
						#  or...
					
					Name = injector :name # &blk
				
						# or even ...
					
					injector :Name # $blk
				
			
				}.to_not raise_error
				
			end

			it 'allows the following expressions' do

				injector :my_injector do
					def foo
						'a foo'
					end

					def bar
						:a_bar
					end
				end
				
				Name = my_injector

				class Target
					include Name
					extend Name
				end
				include my_injector
				extend my_injector
				
				# or ...
				
				class Target
					inject Name
					enrich Name
				end
				inject my_injector
				enrich my_injector
					

			end 
			
			they 'gnerate the following target methods' do
				
				Target.bar == :a_bar
				Target.new.bar == :a_bar
				
				Target.foo == 'a foo'
				Target.new.foo == 'a foo'

			end
			
			the 'injectors can have prolongations' do
				
				my_injector do
					
					def meth arg
						arg
					end
					
					def mith *args
						return args
					end
					
				end
				
				expect {
					
					Target.meth(3).should == 3
					# ...
					
					Target.new.mith(1,2,3).should == [1,2,3]
					# ...
					
				}.to_not raise_error
				
				# another prolongation
				my_injector do
					
					def moth arg1, arg2
						arg1 + arg2
					end
					
				end
				
				expect {
					
					Target.moth(3, 2).should == 5
					# ...
					
				}.to_not raise_error
				
			end
		
		end		


		describe 'Another main difference is that Injectors can be redefined using a block.
		This toys with the ideas of modules as closures.' do

			there 'can be subsequent additions and redefinitions on the block' do
				# declare the injector
				Stuff = injector :stuff do
					def far
						'distant'
					end
				end
				# define containers and include the injector
				class Something
					# define class
					include Stuff
				end
				
				# program works
				some_thing = Something.new
				some_thing.far.should == 'distant'
				
				# define more stuff on the injector
				stuff do
					define_method :far do |miles|
						'My stuff is: ' + miles.to_s + ' miles away' 
					end
				end
				
				# program stiil works
				some_thing.far(100).should == ('My stuff is: 100 miles away')
			end
			
		end
		
		it 'employs the idea of modules as closures allows defining modules on the fly which 
		include state from the surrounding context.  Note: because of RSpec the surrounding 
		context has to me inside the example class, but in normal use it DOES NOT' do
			
			class ClosureExpose
			
				some_value = 'something'
				
				injector :capture do
					define_method :val do
						some_value
					end
				end
			
				inject capture
			end
			
			# the result
			ClosureExpose.new.val.should == 'something'
			
			class SecondClass
				inject ClosureExpose.capture
			end
			
			# the result
			SecondClass.new.val.should == 'something'
		end
		
	end


	describe 'method definition' do
		the 'methods of the injector closure can be define using the def keyword' do
			
			injector :MethodDefinitions
			
			MethodDefinitions() do
				
				def some_crazy_method
					'I am %#&*@^%_crazy enough'
				end
				
			end
			o = Object.new.enrich MethodDefinitions()
			o.some_crazy_method.should ==  'I am %#&*@^%_crazy enough'
		end
		
		the 'methods can be defined using the define_method method proc style' do
			
			MethodDefinitions do
				define_method :more_crazynex do |x, y|
					x * y * x * y
				end
			end
			enrich MethodDefinitions()
			more_crazynex( 3, 4).should == 144
			
		end
		
		the 'methods can be defined using the define_method lambda style' do
			
			MethodDefinitions do
				define_method :gone_bonkers, lambda { |x,y,z| (x * y * z).split(':').join('#@')}
			end
			enrich MethodDefinitions()
			gone_bonkers('errrr:rrrr', 2, 3).should == 'errrr#@rrrrerrrr#@rrrrerrrr#@rrrrerrrr#@rrrrerrrr#@rrrrerrrr#@rrrr'
			
		end
		
	end

	
	describe 'the receiver of the injectors' do

		it 'can have code dynamically injected into an object receiver' do

			Thing = Object.new
			Thang = Object.new

			injector :agent

			Thing.extend agent
			Thang.extend agent

			agent do
				define_method :capability do
					'do the deed'
				end
				define_method :location do
					'main building'
				end
				define_method :tester do
					'some crap happened'
				end
			end
			Thing.should respond_to :capability
			Thing.capability.should == 'do the deed'
			Thang.should respond_to :location
			Thang.location.should == 'main building'
			
		end

		it 'can be a class receiver' do
			
			class Widget

				injector :layout do
					def expand
					end
				end
				injector :color do
					def tint
					end
				end
				include layout
				include color
			end
			
			# Widget.injectors.should == [:layout, :color]
			expect{Widget.new.expand}.to_not raise_error
			expect{Widget.new.tint}.to_not raise_error
			
		end

		it 'has alternate syntax and function through the inject/enrich keywords' do
			
			class Window
				def draw
					'window'
				end

				injector :scroll_bars do
					def draw
						super() + ' with scroll bars'
					end
				end
			end
			
			Window.new.enrich(Window.scroll_bars).draw.should == 'window with scroll bars'
			
		end

		a 'list of injections to an object is available from the enriched object themselves' do
			
			class Coffee
				def cost
					1.50
				end
			end
			injector :milk 
			injector :sprinkles 
			
			cup = Coffee.new.enrich(milk).enrich(sprinkles)
			cup.injectors.should == [:milk, :sprinkles]
			
		end

		the 'list if also available on class injection' do
			
			class SomeClass
				inject injector :one
				inject injector :two
			end
			SomeClass.injectors.should == [:one, :two]
			
		end
	end
		

	describe 'injectors can all be dynamically erased from context. In various ways:' do

		describe 'An injector individually ejected to eliminate its function. All subsequent
		method calls on the injectors methods may raise an error if there is nothing else up
		the lookup chain' do

			the 'injector functionally can be removed from a class of objects. Note: only 
			available on injected classes, i.e: using the inject keyword' do
				
				# create the injection
				class Home
					injector :layout do
						def fractal
						end
					end
					inject layout
				end
				expect{Home.new.fractal}.to_not raise_error

				# another injector
				class Home
					injector :materials do
						def plastic
						end
					end
					inject materials
				end
				Home.injectors.should == [:layout, :materials ]

				# build
				my_home = Home.new
				friends = Home.new
				
				# eject the code
				class Home
					eject :layout
				end
				
				# the result
				Home.injectors.should == [:materials]
				expect{my_home.fractal}.to raise_error
				expect{friends.fractal}.to raise_error
				expect{Home.new.fractal}.to raise_error(NoMethodError)
				
				# eject the other injector
				class Home
					eject :materials
				end
				
				# the result
				Home.injectors.should be_empty
				expect{my_home.plastic}.to raise_error
				expect{friends.plastic}.to raise_error
				expect{Home.new.plastic}.to raise_error(NoMethodError)
				
			end

			but 'the main injector is still available for re-injection' do
				
				# re-inject the class
				class Home
					inject layout
				end
				
				# the result
				expect{Home.new.fractal}.to_not raise_error
				expect{Home.new.dup}.to_not raise_error
				
			end

			the 'functionality removed from the individual objects when enriched,
			i.e: using the enrich keyword' do
				
				class Coffee
					def cost
						1.00
					end
				end
				injector :milk do
					def cost
						super() + 0.50
					end
				end
				expect{eject :milk}.to raise_error(NoMethodError, /eject/)
			
				cup = Coffee.new.enrich(milk)
				friends_cup = Coffee.new.enrich(milk)
			
				cup.cost.should == 1.50
				friends_cup.cost.should == 1.50
			
				cup.eject :milk
				cup.cost.should == 1.00
				# friends cup didn't change price
				friends_cup.cost.should == 1.50
				
			end
				
			
		end

		describe 'the entire injector and all instances eliminated via injector :implode
		produces different results than ejecting individual injectors' do
		
			an 'example of complete injector implosion' do
				
				class Model
					def feature
						'a standard feature'
					end
				end

				injector :extras do
					def feature
						super() + ' plus some extras'
					end
				end
				
				car = Model.new.enrich(extras)
				car.feature.should == 'a standard feature plus some extras'

				extras :implode
				
				# total implosion
				expect{extras}.to raise_error(NameError, /extras/)
				car.feature.should == 'a standard feature'
				
				expect{ 
					new_car = Model.new.enrich(extras) 
					}.to raise_error(NameError, /extras/)
					
				expect{
					extras do
						def foo
						end
					end
					}.to raise_error(NameError, /extras/)
					
			end

			describe 'difference between injector ejection/implosion' do
		
				the 'Injector reconstitution after ejection is possible through reinjection
				but reconstitution after injector implosion is NOT AVAILABLE' do

					# code defined
					class Job
						injector :agent do
							def call
							end
						end
						inject agent
					end
					Job.injectors.should == [:agent]

					# normal use
					expect{Job.new.call}.to_not raise_error

					# code ejection
					Job.eject :agent

					# code extended and re-injected
					class Job
						inject agent
						agent do
							def sms
							end
						end
					end

					#normal use
					expect{Job.new.call}.to_not raise_error
					expect{Job.new.sms}.to_not raise_error

					# code imlossion
					Job.agent :implode

					# Unavailable !!!
					expect{
						class Job
							inject :agent
						end
						}.to raise_error

					# Unavailable !!!
					expect{
						class Job
							agent do
								def something
								end
							end
						end }.to raise_error

					# Unavailable!!!
					expect{Job.new.call}.to raise_error
					expect{Job.new.sms}.to raise_error

				end

			end

		end

		describe 'injectors can be silenced. This description produces similar results to 
		the previous except that further injector method calls DO NOT raise an error 
		they just quietly return nil' do
			
			the 'case with objects' do
		
				injector :copiable do
					def object_copy
						'a dubious copy'
					end
				end
		
				o1 = Object.new.enrich(copiable)
				o2 = Object.new.enrich(copiable)
		
				o1.object_copy.should == 'a dubious copy'
				o2.object_copy.should == 'a dubious copy'
		
				# DX.splat
				copiable :silence
		
				o1.object_copy.should == nil
				o2.object_copy.should == nil
		
			end

			the 'case with a classes' do

				class SomeClass
					injector :code do
						def tester
							'boo'
						end
					end
					
					inject code
				end
				
				# collapse
				SomeClass.code :collapse

				# build
				a = SomeClass.new
				b = SomeClass.new

				# INTERESTINGLY!!
				a.tester.should == nil
				b.tester.should == nil
				
				# further
				SomeClass.eject :code 
				expect{ a.tester }.to raise_error
				expect{ b.tester }.to raise_error

			end
			
			the 'case with multiple injector copies in one object' do
		
				# extend already collapsed injectors
				injector :somecode do
					def fun
						super + ' and more fun'
					end
				end
			
				# define container
				class BumperCar
					def fun
						'this is fun'
					end
				end				
				bc = BumperCar.new.enrich(somecode).enrich(somecode)
			
				# INTERSTINGLY!!
				bc.fun.should == 'this is fun and more fun and more fun'
			
				# re-collapse
				somecode :collapse																								
				bc.fun.should == nil																							
			                                                                    
				# eject all injectors                                             
				bc.injectors.each { |ij| bc.eject ij }														
				bc.fun.should == 'this is fun' 
		
			end
		
		end
		
		describe 'quieted injectors restored without having
		to re-inject them into every object they modify' do
		
			the 'case with objects' do
	
				injector :reenforcer do
					def thick_walls
						'=====  ====='
					end
				end

				o1 = Object.new.enrich(reenforcer)
				o2 = Object.new.enrich(reenforcer)
	
				reenforcer :collapse
	
				o1.thick_walls.should == nil
				o2.thick_walls.should == nil
	
				reenforcer :rebuild
	
				o1.thick_walls.should == '=====  ====='
				o2.thick_walls.should == '=====  ====='
	
			end

			the 'case with a classes' do
			
				class SomeBloatedObject
					injector :ThinFunction do
						def perform
							'do the deed'
						end
					end
					inject ThinFunction()
				end
				SomeBloatedObject.ThinFunction :silence
			
				tester = SomeBloatedObject.new
				tester.perform.should == nil
			
				SomeBloatedObject.ThinFunction :active
				tester.perform.should == 'do the deed'
			
			end
	
			the 'case with multiple injectors in one object' do
		
				injector :othercode do
					def fun
						super + ' and more fun'
					end
				end
				class BumperCar
					def fun
						'this is fun'
					end
				end
		
				bc = BumperCar.new.enrich(othercode).enrich(othercode)
				bc.fun.should == 'this is fun and more fun and more fun'
		
				othercode :silence
				bc.fun.should == nil
			
				othercode :active
				bc.fun.should == 'this is fun and more fun and more fun'
				
				# restore the original
				bc.injectors.each { |ij| bc.eject ij }
				bc.fun.should == 'this is fun' 
		
			end
	
		end
	end

	describe 'a shimmer of orthogonality with injectors' do

		the 'following interdepent calls do not raise any errors' do

			expect{
				include Injectors

				injector :tester

				
				tester do
					extend self																									# extend self
																																			# Note: you cannot self enrich an injector
					def order weight
						lets manus =->(){"manus for #{weight}"}
						manus[]
					end
				end
				tester.order(50).should == 'manus for 50'											# call method extended to self


				tester do
					decorate :order do |num|																		# decorate the same method
						self.to_s + super(num)
					end	
				end
				tester.order(50).should =~ /^<Injector.+?manus for 50/ 				# call decorated method extended to self 
				


				with tester do 																								# with self(tester)
					puts order 30																								# execute method
					def receive weight																					# define singleton method
						"received #{weight}"
					end
				end
				tester.receive(90).should == 'received 90'										# call singleton method


				tester do
					def more_tests arg																					# define instance method which depends on singleton method
						receive 23                           											# call singleton method
						"tested more #{arg}"
					end
				end
				tester.should_receive(:receive).with(23)											# call instance method extended to self
				tester.more_tests('of the api').should == 'tested more of the api'
				
			}.to_not raise_error

		end
		
		the 'following call does raise a Jackbox::UserError' do
			
			expect{
				
			injector :try_this do
				enrich self
			end
			
			}.to raise_error(UserError)
		end
	
	end
	
	
end 


