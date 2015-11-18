require "spec_helper"

include Injectors

describe 'Injector versioning:', :injectors do
# subsequent redefinitions of methods constitute another version of the injector.  Injector 
# versioning is the term used to identify a feature in the code that produces an artifact of injection which contains a 
# certain set of methods and their associated outputs and represents a snapshot of that injector up until the point it 
# gets applied to an object.  From, that point on the object contains only that version of methods from that injector, and 
# any subsequent overrides to those methods are only members of the "prolongation" of the injector and do not become part 
# of the object of injection unless some form of reinjection occurs. Newer versions of methods only become part of newer 
# objects or newer injections into existing targets'
	
	describe 'injector versioning and its relationship to object instances' do
	
		the 'injector versioning uses a snapshot of the injector`s existing methods up to the point of injection' do
		# using only that version of	methods as the object of injection.  AA4ny overrides to methods in any subsequent injector prolongations 
		# do not take effect in this target.  AA4ny new methods added to the injector do become available to the target, although
		# may contain internal references to newer versions of the target methods. This ensures to keep everyting working correctly.'
		
			#___________________
			# injector declaration
			injector :My_injector

	    #___________________
	    # injector first prolongation
	    My_injector do 															
	      def bar
	        :a_bar                                  # version bar.1
	      end
	      def foo
	      	# ...
	      end
	    end
	
			object1 = Object.new
	    object1.enrich My_injector()                # apply the injector --first snapshot
	    object1.bar.should == :a_bar                # pass the test

	    #__________________
	    # injector second prolongation
	    My_injector do 																			
	      def bar
	        :some_larger_bar                        # version bar.2 ... re-defines bar
	      end
	      def some_other_function
	      # ...
	      end
	    end
    
			object2 = Object.new
	    object2.enrich My_injector()                # apply the injector --second snapshot
	    object2.bar.should == :some_larger_bar

	    # result
	    ###########
    
	    object1.bar.should == :a_bar                # bar.1 is still the one

	    ###########################################
	    # The object has kept its preferred version
		
		end
	
		the 're-injection changes ("updates if you will") versions of methods in use' do
			
			#_________________
			# re-injection
			enrich My_injector()																	# re-injection on any object instance
			bar.should == :some_larger_bar												# bar.2 now available
			
			expect{some_other_function}.to_not raise_error				# some_other_function.1 is present
		
		end
		
		a 'different example with an explicit self' do
			
			o = Object.new
			
			injector :some_methods do
				def meth arg
					arg
				end
			end
			
			o.enrich some_methods
			o.meth('cha cha').should == 'cha cha'
			
			some_methods do
				def meth arg
					arg * 2
				end
			end
			
			o.meth('cha cha').should == 'cha cha'
			
			oo = Object.new.enrich(some_methods)
			oo.meth('cha cha').should == 'cha cha'+'cha cha'

			o.meth('cha cha').should == 'cha cha'
			
		end

	end
	
	describe "injector versioning and its relationship to classes" do
	# similar to object level versioning in that it uses a snapshot of the injector`s existing methods up to the point of injection, using only 
	# that version of methods as the object of injection.  But, unlike object level versioning, because class injection is static, reinjection 
	# does not change the class unless we use the Strategy Pattern which completely changes the class's strategy of methods" 
		
		the "class injector versioning is similar to object injector versioning" do
			
			#___________________
			# injector declaration:
			injector :Versions 

	    #___________________
	    # injector first prolongation
	    Version1 = Versions do
	      def meth arg                              # version meth.1
	        arg ** arg
	      end
	    end

	    class One
	      inject Version1                           # apply --first snapshot
	    end

	    #_________________
	    # injector second prolongation                              
	    Version2 = Versions do
	      def meth arg1, arg2                       # version meth.2 ... redefines meth.1
	        arg1 * arg2
	      end
	    end

	    class Two
	      inject Version2                           # apply --second snapshot
	    end


	    # result
	    #############################
	    Two.new.meth(2,4).should == 8               # meth.2 
	                                                            # two different injector versions
	    One.new.meth(3).should == 27                # meth.1
	    #############################
	    #
			
		end
		
		# we can update individual object instances but not classes directly
		# this is unavailable because class injection is pervasive
		the 'simple re-injection is different for classes: it fails ' do
			
			# re-injection can happen on individual object instances
			One.new.enrich(Version2).meth(4,5).should == 20			# meth.2 works!!
			
			# re-injection applying version 2 to class One has no effect
			One.inject Version2 												
			expect{ One.new.meth(4,5) }.to raise_error(ArgumentError) 					# meth.2: fails!! 
			
		end
		
		the 'way to class level injector updates is through the Strategy Pattern' do
					 
			# DO NOT want to necessarily update older clients of the class
			# but possible if needed

			class One
				eject Version1													# eject version 1
			
				inject Version2													# re-inject with prolonged injector -- can be any version
			end
			One.new.meth(4,5).should == 20							# meth.2 now available!!
			
			################################################
			# We feel this is the correct approach but has #
			# a sllight syntactical handicap/ambiguity     #
			################################################
			
		end
		
		a 'preferred way as of late: private updates --could change' do
			
			Versions do
				def meth(*args)
					args.inject(&:+)
				end
			end
			
			class One
				update Versions()													# changes strategy for you
																									# by design a private method as sign of its delicate nature 
			end
			
			# or ....
			
			One.send :update, Versions()
			One.new.meth( 3,4,5,6 ).should == 18				# new version now available!
			
		end
		
		a 'different use case' do
			
			class Freak
				
				injector :freaky
				freaky do
					def twitch
						'_-=-_-=-_-=-_-=-_'
					end
				end
				inject freaky
				
			end
			Freak.new.twitch.should == '_-=-_-=-_-=-_-=-_'
			
			class Freak
				
				freaky do
					def twitch
						'/\/\/\/\/\/\/\/\/\/'
					end
				end
				update freaky
				
			end
			Freak.new.twitch.should == '/\/\/\/\/\/\/\/\/\/'
		
		end

		there 'is a different way todo global updates on Injectors: use define_method' do

			SomeJack = jack :some_jack do
				def foo_bar
					'a foo and a bar'
				end
			end

			class Client
				inject SomeJack
			end

			Client.new.foo_bar.should == 'a foo and a bar'			# expected

			some_jack do
				define_method :foo_bar do
					'fooooo and barrrrr'
				end
			end

			Client.new.foo_bar.should == 'fooooo and barrrrr'		# different

		end
	end

	describe "utility of injector versioning: " do
		
		it 'allows to easily override methods without affecting other parts of your program' do
			
			J1 = injector :j do
				def meth(arg)
					arg
				end
			end
			
			class AA4
				inject J1
			end
			AA4.new.meth(3).should == 3
			
			J2 = j do
				def meth(arg)
					arg *arg
				end
			end
			
			class BBB
				inject J2
			end
			BBB.new.meth(3).should == 9
			
			AA4.new.meth(3).should == 3
			
		end
		
		the "local binding of injectors" do

	    #_____________________
	    # injector declaration
	    VersionOne = injector :functionality do
	      def basic arg                             # version basic.1
	        arg * 2
	      end
	    end

	    o = Object.new.enrich VersionOne						# apply --first snapshot
	    o.basic(1).should == 2                      # basic.1 


	    #_____________________
	    # injector prolongation
	    VersionTwo = functionality do
	      def basic arg                             # basic.2 ... basic.1 redefined
	        arg * 3
	      end

	      def compound                              # compound.1 --bound locally to basic.2
	        basic(3) + 2                                      
	      end
	    end                                         

	    p = Object.new.enrich VersionTwo            # apply --second snapshot (like above)
	    p.basic(1).should == 3                      # basic.2 
	    p.compound.should == 11                     # compound.1 


	    # result
	    ###################################

	    o.basic(1).should == 2                      # basic.1 
			# debugger
	    o.compound.should == 11                     # compound.1 --local injector binding

	    ###################################
	    # This ensures #compound.1 keeps bound
	    # to the right version #basic.2

		end

	end
end


