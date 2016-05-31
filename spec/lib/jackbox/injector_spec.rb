require "spec_helper"
=begin rdoc

	Injector_spec
	author: Lou Henry
	
	Injectors are like modules; they can be extended or included in other modules, but
	exhibit some additional functionality not present in modules.  
		
=end

include Injectors

describe Injectors, :injectors do

	describe :injector do
		it 'creates the injector function' do
			should respond_to :injector
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
					
					injector :my_injector 
				
					#  or...
					
					Name = injector :name 
				
					# or even ...
					
					injector :Name 													# capitalized method
				
				}.to_not raise_error
				
			end

			it 'allows the following expressions' do

				expect{

			    # somewhere in your code
		
			    injector :my_injector                   # define the injector 

			    # later on...
		
			    my_injector do  
				    def foo
					  	'a foo'
						end
			      def bar                  
			        :a_bar
			      end
			    end

			    # later on...
		
					widget = Object.new
			    widget.extend my_injector
			    widget.bar

			    # or...  
		
			    Mine = my_injector
		
			    class Target1
			      include Mine                          # apply the injector
						extend Mine
			    end

			    Target1.new.bar

					module Container
						jack :some_jack												# alternate term

						class Contained
							inject Container.some_jack
						end
					end
				
					# etc ...

				}.to_not raise_error

			end 
			
			the 'above generate the following target methods' do
				
				Target1.bar.should == :a_bar
				Target1.new.bar.should == :a_bar
				
				Target1.foo.should == 'a foo'
				Target1.new.foo.should == 'a foo'
				
				Container.some_jack
				
			end
			
			it 'follows the method lookup algorythm' do
				
				injector :some_injector
				
				expect{
					class SomeReceiver
						include some_injector
					end
				}.to raise_error(NameError)
				
			end
			
			it 'allows you to follow the constant lookup algorythmn' do
				
				Some_Injector = injector :some_injector
				
				expect{
					class Some_Receiver
						inject Some_Injector
					end
				}.to_not raise_error
				
			end
			
			it 'has alternate syntax and function through the inject/enrich keywords' do

				# inject

				injector :alternate do
					def meth arg
						arg < 3
					end
				end

				class AlternateClass
					# ...
				end
				AlternateClass.inject alternate

				AlternateClass.new.meth(2).should == true

				# enrich

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

		end		

		# This toys with the ideas of modules as closures.' 
		describe 'another main difference is that Injectors are defined using a block.' do
			there 'can be subsequent additions and definitions on the block' do

				# declare the injector
				Stuff = injector :stuff do
					def far
						'distant'
					end
				end

				# define containers and include the injector
				class Something
					include Stuff
				end
				
				# program works
				some_thing = Something.new
				some_thing.far.should == 'distant'
				
				# define more stuff on the injector
				stuff do
					def this_far miles
						'My stuff is: ' + miles.to_s + ' miles away' 
					end
				end
				
				# program stiil works
				some_thing.this_far(100).should == ('My stuff is: 100 miles away')
				
			end
			
			it 'can have code dynamically injected into a receiver' do

				Thing = Object.new
				Thang = Object.new

				injector :agent

				Thing.extend agent
				Thang.extend agent

				agent do 																							# on the fly definitions
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

			these 'blocks allow on the fly modules which can also include state from the surrounding context' do
			
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
					include ClosureExpose.capture
				end
			
				# the result
				SecondClass.new.val.should == 'something'
			
			end
		
			these 'new blocks constitute new injector prolongations' do
				
				AnotherName = injector :another_injector 
				
				class Target2
					include AnotherName
				end

				#_____________________
				# first prolongation
				another_injector do
					def meth arg
						arg
					end
					
					def mith *args
						return args
					end
				end
				
				expect {
					
					Target2.new.mith(1,2,3).should == [1,2,3]
					Target2.new.meth(4).should == 4
					
				}.to_not raise_error
				
				#____________________
				# another prolongation
				another_injector do
					def moth arg1, arg2
						arg1 + arg2
					end
				end
				
			end
		
		end
	end

	describe 'method definition on injectors' do
		the 'methods of the injector closure can be defined using the def keyword' do

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

			injector :MethodDefinitions
			MethodDefinitions do
				define_method :more_crazynex do |x, y|
					x * y * x * y
				end
			end
			enrich MethodDefinitions()
			more_crazynex( 3, 4).should == 144

		end

		the 'methods can be defined using the define_method lambda style' do

			injector :MethodDefinitions
			MethodDefinitions do
				define_method :gone_bonkers, lambda { |x,y,z| (x * y * z).split(':').join('#@')}
			end
			enrich MethodDefinitions()
			gone_bonkers('errrr:rrrr', 2, 3).should == 'errrr#@rrrrerrrr#@rrrrerrrr#@rrrrerrrr#@rrrrerrrr#@rrrrerrrr#@rrrr'

		end
	end

	describe 'the types of receivers' do
		
		it 'can be a class INSTANCE' do
			
			injector :class_instance_injector do
				def new *args
					puts "--done--"
					super(*args)
				end
			end

			class SomeClassInstance
				# ...
			end

			SomeClassInstance.enrich class_instance_injector

			$stdout.should_receive(:puts).with("--done--")
			iu = SomeClassInstance.new

		end
		
		it 'can be an actual class receiver' do
		
			Layout = injector( :layout ){
				def expand
				end
			}
			Color = injector( :color ){
				def tint
				end
			}
			class Widget

				include Layout 
				include Color
			
			end
			Widget.injectors.sym_list.should == [:color, :layout]

			expect{Widget.new.expand}.to_not raise_error
			expect{Widget.new.tint}.to_not raise_error
		
		end

		it 'can be an object instance receiver' do
			
			injector :for_an_object do
				def to_s
					'oohooo'
				end
			end
			
			o = Object.new
			
			o.enrich for_an_object
			
			o.to_s.should == 'oohooo'
			
		end
	
	end

	describe 'introspection on receivers' do
		
		a 'list of injections to an object is available from the objects themselves' do
		
			class Coffee
				def cost
					1.50
				end
			end
			injector :milk 
			injector :vanilla 
		
			cup = Coffee.new.enrich(milk).enrich(vanilla)
			cup.injectors.sym_list.should == [:vanilla, :milk]
		
		end

		the 'list if also available on class injection' do
		
			class SomeClass
				inject injector :one
				inject injector :two
			end
			SomeClass.injectors.sym_list.should == [:two, :one]
		
		end
		
		the 'same is true at the class instance level' do
			
			# from above
			SomeClassInstance.injectors(:all).sym_list.should == [:class_instance_injector]
			
		end
		
		#
		# more on this at the end of file
		#
		
	end
	

	describe 'injectors can all be dynamically erased from context. In various ways:' do
		describe 'An injector individually ejected to eliminate its function. All subsequent
		method calls on the injectors methods may raise an error if there is nothing else up
		the lookup chain' do

			the 'functionality removed from the individual objects.
			Note: applied using the enrich keyword on the object instance' do
				
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
				# expect{eject :milk}.to raise_error(NoMethodError, /eject/)
			
				cup = Coffee.new.enrich(milk)
				friends_cup = Coffee.new.enrich(milk)
			
				cup.cost.should == 1.50
				friends_cup.cost.should == 1.50
			
				cup.eject :milk
				cup.cost.should == 1.00
				# friends cup didn't change price
				friends_cup.cost.should == 1.50
				
			end
			
			the 'functionality removed from a class INSTANCE
			Note: when applied via the enrich keyword on the class' do

				injector :part do
					def connector
						'connected'
					end
				end
				class Whole
				end
				Whole.extend part
				
				Whole.connector.should == 'connected'
				Whole.injectors(:all).sym_list.should == [:part]
				
				# eject the part
				
				Whole.eject part
				
				# result
				
				Whole.injectors.should be_empty
				expect{
					Whole.eject part
				}.to raise_error(ArgumentError)
				
			end
			
			the 'injector functionality removed from a class of objects. 
			Note: applied using the inject keyword on the class' do
				
				# create the injection
				class Home
					include jack :layout do
						def fractal
						end
					end
				end
				expect{Home.new.fractal}.to_not raise_error

				# another injector
				class Home
					include jack :materials do
						def plastic
						end
					end
				end
				Home.injectors.sym_list.should == [:materials, :layout ]

				# build
				my_home = Home.new
				friends = Home.new
				
				# eject the code
				class Home
					eject :layout
				end
				Home.injectors.sym_list.should == [:materials]
				
				# the result
				expect{my_home.fractal}.to raise_error(NoMethodError)
				expect{friends.fractal}.to raise_error(NoMethodError)
				expect{Home.new.fractal}.to raise_error(NoMethodError)
				
				# eject the other injector
				class Home
					eject :materials
				end
				Home.injectors.sym_list.should be_empty
				
				# the result
				expect{my_home.plastic}.to raise_error(NoMethodError)
				expect{friends.plastic}.to raise_error(NoMethodError)
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

		end


	end

	describe 'orthogonality of injectors with Jackbox' do
		
		the 'following interdepent calls do not raise any errors' do

			expect{
				include Injectors

				injector :tester1
				
				tester1 do
					extend self																									# extend self
																																			# Note: you cannot self enrich an injector
					def order weight
						lets label =->(){"label for #{weight}"}
						label[]
					end
				end
				tester1.order(50).should == 'label for 50'											# call method extended to self


				tester1 do
					decorate :order do |num|																		# decorate the same method
						"#{self.to_s} " + super(num)
					end	
				end
				tester1.order(50).should match( /|tester1| label for 50/ )  # call decorated method extended to self 


				$stdout.should_receive(:puts).with( /|tester1| label for 30/ )
				with tester1 do 																							# with self(tester1)
					puts order 30																								# execute method
					def receive weight																					# define singleton method
						"received #{weight}"
					end
				end
				tester1.receive(90).should == 'received 90'										# call singleton method


				tester1 do
					def more_tests arg																					# define instance method which depends on singleton method
						receive 23                           											# call singleton method
						"tested more #{arg}"
					end
				end                     
				
				tester1.more_tests('of the api').should == 'tested more of the api'
				
			}.to_not raise_error

		end
		
		it 'should also pass' do

			expect{

				injector :tester2 
                                                                      ##################
				tester2 do                                                    # enrich == extend
					enrich self																									##################
                                                                      
					def meth arg																								# define method enriched on self
						arg * arg
					end
				end
				tester2.meth(4).should == 16																	# call method enriched on self


				tester2 do
					decorate :meth do |arg| 																		# re-define method enriched on self
						super(arg) + 1
					end
				end
				tester2.meth(3).should == 10																	# call re-defined method

				# splat
				with tester2 do 																							# with object self
					meth(5).should == 26
					def math arg1, arg2																					# define singleton method on self
						meth(arg1 + arg2)
					end
				end
				tester2.math(3, 2).should == 26																# call singleton method on self

			}.to_not raise_error

			tester2 do 																											# define new instance method depending on singleton method
				def moth arg											
					math(arg, arg) 																				
				end
			end

			tester2.moth(4).should == 65

		end

		describe 'othogonality: equivalent injector forms' do
			
			describe "equivalent inclusion" do
			
				before do
					class Injected
						# ...
					end
				end
			
				after do
				
				end

				the 'following class injection forms are all equivalent' do

					injector :Base do
						def meth
							:meth
						end
					end
					Injected.inject Base()
					Injected.new.meth.should == :meth  
				
					Injected.eject Base()
				end
				the 'following class injection forms are all equivalent' do

					Injected.inject Base() do
						def meth
							:meth
						end
					end
					Injected.new.meth.should == :meth

					Injected.eject Base()
				end 
				the 'following class injection forms are all equivalent' do

					injector( :Base ){
						def meth
							:meth
						end
					}
					Injected.inject Base()
					Injected.new.meth.should == :meth

					Injected.eject Base()
				end
				the 'following class injection forms are all equivalent' do

					Injected.inject injector( :Base ){
						def meth
							:meth
						end
					}
					Injected.new.meth.should == :meth

					Injected.eject Base()
				end
      end

			describe 'equivalent enrichment' do
				
				the 'following instance enrichment forms are all equvalent' do

					injector :base do
						def meth
							:meth
						end
					end
					enrich base
					meth.should == :meth

					eject base
				end
				the 'following instance enrichment forms are all equvalent' do

					enrich injector :base do
						def meth
							:meth
						end
					end
					meth.should == :meth

					eject base
				end
				the 'following instance enrichment forms are all equvalent' do

					injector( :base ){
						def meth
							:meth
						end
					}
					enrich base
					meth.should == :meth

					eject base
				end
				the 'following instance enrichment forms are all equvalent' do

					enrich injector( :base ){
						def meth
							:meth
						end
					}
					meth.should == :meth

					eject base
				end 
				
			end
			
		end
		
		describe 'other forms of othogonlity' do
			
			before do
			 injector :Ortho 
			end
			
			after do
				Ortho(:implode)
			end
				 
			it 'uses #with in the following ways' do
			                                          
				with Ortho() do
					def foo
					end
				end
				
				Ortho().instance_methods.should include(:foo) 
				
			end
			
			it "also works this way" do
				
				class OrthoClass
				end
				
				with OrthoClass do
					include Ortho()
					extend Ortho(), Ortho()
				end
				
				with OrthoClass do
					eject *injectors
				end
				
				OrthoClass.injectors.should be_empty
			
			end  
			
			it 'works with #lets in this way' do
			
				with Ortho() do
					lets(:make){'Special Make'}
					
					def print
						puts make
					end
				end
				
				enrich Ortho()
				make.should == 'Special Make'
				#...
				
			end
			
			it 'ejects inherited tags' do
				
				EjectionTag1 = jack :ejection_test do
					def m1
						2
					end
				end
				
				EjectionTag2 = ejection_test do
					def m1
						super + 2										# override --jit inheritance
					end
				end
				
				o = Object.new.enrich EjectionTag2
				o.m1.should == 4
				# o.metaclass.ancestors.to_s.should match(/EjectionTag2.*EjectionTag1/)
				
				o.eject EjectionTag2
				expect{o.m1}.to raise_error(NoMethodError)
				o.metaclass.ancestors.to_s.should_not match(/EjectionTag2/)
				o.metaclass.ancestors.to_s.should_not match(/EjectionTag2.*EjectionTag1/)
				o.metaclass.ancestors.to_s.should_not match(/EjectionTag1/)
				
			end

		end
	end

end 


