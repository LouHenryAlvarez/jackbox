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
		# using only that version of	methods as the object of injection.  Any overrides to methods in any subsequent injector prolongations 
		# do not take effect in this target.  Any new methods added to the injector do become available to the target, although
		# may contain internal references to newer versions of the target methods. This ensures to keep everyting working correctly.'
		
	    #___________________
	    # injector declaration
	    injector :my_injector do 															
	      def bar
	        :a_bar                                          # version bar.1
	      end
	      def foo
	      	# ...
	      end
	    end
	
			object1 = Object.new
	    object1.enrich my_injector                          # apply the injector --first snapshot
	    object1.bar.should == :a_bar                        # pass the test

	    #__________________
	    # injector prolongation
	    my_injector do 																			
	      def bar
	        :some_larger_bar                                # version bar.2 ... re-defines bar
	      end
	      def some_other_function
	      # ...
	      end
	    end
    
			object2 = Object.new
	    object2.enrich my_injector                          # apply the injector --second snapshot
	    object2.bar.should == :some_larger_bar

	    # result
	    ###########
    
	    object1.bar.should == :a_bar                        # bar.1 is still the one

	    ###########################################
	    # The object has kept its preferred version
		
		end
	
		the 're-injection changes ("updates if you will") versions of methods in use' do
			
			#_________________
			# re-injection
			enrich my_injector																		# re-injection on any object instance
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
	# does not change that, unless we use the Strategy Pattern which completely changes the class's strategy of methods" do
		
		the "class injector versioning is similar to object injector versioning" do
			
	    #___________________
	    # injector declaration:
	    Versions = injector :versions do
	      def meth arg                                      # version meth.1
	        arg ** arg
	      end
	    end

	    class One
	      inject Versions                                   # apply --first snapshot
	    end

	    #_________________
	    # injector prolongation:                              
	    versions do
	      def meth arg1, arg2                               # version meth.2 ... redefines meth.1
	        arg1 * arg2
	      end
	    end

	    class Two
	      inject Versions                                   # apply --second snapshot
	    end


	    # result
	    #############################
	    Two.new.meth(2,4).should == 8                       # meth.2 
	                                                                      # two different injector versions
	    One.new.meth(3).should == 27                        # meth.1
	    #############################
	    #
			
		end
		
		the 'above updates by re-injection are different for classes --we can update individual object instances' do
			
			One.inject Versions 																			# re-injection: applying version 2 to class One has no effect
			
			expect{ One.new.meth(4,5) }.to raise_error 								# meth.2: fails!! unavailable because class injection is static
			
			
			# re-injection can happen on individual object instances
			One.new.enrich(Versions).meth(4,5).should == 20						# meth.2
			
		end
		
		the 'way to class level injector updates is through the Strategy Pattern' do
					 
			class One
				eject Versions																					# eject version 1
			
				inject Versions																					# re-inject with prolonged injector -- can be any version
			end
			One.new.meth(4,5).should == 20														# meth.2 now available!!
			
			# We feel this is the correct approach but there is 
			# a little syntactical handicap/ambiguity
			
		end
		
		a 'preferred way as of late: private updates --could change' do
			
			versions do
				def meth(*args)
					args.inject(&:+)
				end
			end
			
			class One
				update Versions																					# changes strategy for you --but always to the latest only
			end
			# or ....
			
			One.send :update, Versions																# by design a private method as sign of its delicate nature 
																																# DO NOT want to necessarily update older clients of the class
			One.new.meth( 3,4,5,6 ).should == 18											# but possible if needed
			
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
		
		
	end

	describe "utility of injector versioning: " do
		
		it 'allows to easily override methods without affecting other parts of your program' do
			
			J = injector :j do
				def meth(arg)
					p arg or arg
				end
			end
			
			class A
				inject J
			end
			A.new.meth(3).should == 3
			
			j do
				def meth(arg)
					arg *arg
				end
			end
			
			class B
				inject J
			end
			B.new.meth(3).should == 9
			
			A.new.meth(3).should == 3
			
		end
		
		the "local binding of injectors" do

	    #_____________________
	    # injector declaration
	    injector :functionality do
	      def basic arg                                     # version basic.1
	        arg * 2
	      end
	    end
	    Version1 = functionality 


	    o = Object.new.enrich Version1                      # apply --first snapshot
	    o.basic(1).should == 2                              # basic.1 


	    #_____________________
	    # injector prolongation
	    functionality do
	      def basic arg                                     # basic.2 ... basic.1 redefined
	        arg * 3
	      end

	      def compound                                      # compound.1 --bound locally to basic.2
	        basic(3) + 2                                      
	      end
	    end                                                 #________________
	    Version2 = functionality                            # version naming
	                                                        #^^^^^^^^^^^^^^^^

	    p = Object.new.enrich Version2                      # apply --second snapshot (like above)
	    p.basic(1).should == 3                              # basic.2 
	    p.compound.should == 11                             # compound.1 


	    # result
	    ###################################

	    o.basic(1).should == 2                              # basic.1 
	    o.compound.should == 11                             # compound.1 --local injector binding

	    ###################################
	    # This ensures #compound.1 keeps bound
	    # to the right version #basic.2

		end

		there 'is a different way todo global updates: define_method' do
			
			SomeFacet = facet :some_facet do
				def foo_bar
					'a foo and a bar'
				end
			end
			
			class Client
				inject SomeFacet
			end
			
			Client.new.foo_bar.should == 'a foo and a bar'			# expected
			
			some_facet do
				define_method :foo_bar do
					'fooooo and barrrrr'
				end
			end
			
			Client.new.foo_bar.should == 'fooooo and barrrrr'		# different
			
		end
	end
end


