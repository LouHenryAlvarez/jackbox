require "spec_helper"
=begin rdoc
	
	Specifies the behavior of Injectors under inheritance
	
	. First we se how ancestors are treated
	. Next we treat Injectors under a class hierarchy
	. Then we see a few special cases in the realm of multiple inheritance
	
	lha
	
=end

include Injectors

	
	####################### IMPORTANT ##############################
	# NOTE: Once again, some of these examples are long on purpose.
	# We are trying to show what happens to Injectors as 
	# a result of various lifecycle change events.
	# ##############################################################



describe "ancestor chains" do

	it 'updates the ancestor chains accordingly based on: injections and ejections' do

    # LifeCycle Start

		trait :Parent															# capitalized method
		
		class Child
			include Parent()
		end
		c = Child.new
		
		# Parent is ancestor of the class and instance
		Child.ancestors.to_s.should match( /Child, \(\|Parent\|.*\), Object.*BasicObject/ )
		c.singleton_class.ancestors.to_s.should match(/Child, \(\|Parent\|.*\), Object.*BasicObject/ )

		# Parent is ancestor of the class and of the instance metaclass
		c.enrich Parent()                                                      
		c.singleton_class.ancestors.to_s.should match( /\(\|Parent\|.*\), Child, \(\|Parent\|.*\), Object.*BasicObject/ )


		# Parent is ejected from the object metaclass and ancestor chain reverts back
		c.eject Parent()
		c.singleton_class.ancestors.to_s.should match( /Child, \(\|Parent\|.*\), Object.*BasicObject/ )


		# Parent is ejected from the class and ancestors chain is empty
		Child.eject Parent()
		Child.ancestors.to_s.should match( /Child, Object.*BasicObject/ )


		# Note: cannot update empty trait
		expect{ Child.send :update, Child.parent }.to raise_error(NoMethodError) 


		# Instance metaclass is extended with Parent twice like in the case of multiple decorators
		c.enrich Parent()
		c.enrich Parent()
		c.singleton_class.ancestors.to_s.should match( /\(\|Parent\|.*\), \(\|Parent\|.*\), Child, Object.*BasicObject/ )


		# Instance is reverted back to no Injectors
		c.eject Parent()
		c.eject Parent()
		c.singleton_class.ancestors.to_s.should match( /Child, Object.*BasicObject/ )


		# LyfeCycle Restart

		# class is re-injected with Parent and becomes ancestor of the class and instance
		Child.inject Parent()
		
		Child.ancestors.to_s.should match( /Child, \(\|Parent\|.*\), Object.*BasicObject/ )              
		c.singleton_class.ancestors.to_s.should match( /Child, \(\|Parent\|.*\), Object.*BasicObject/ )


		# Parent is eject from the instance
		c.eject Parent()
		c.singleton_class.ancestors.to_s.should match( /Child, Object.*BasicObject/ )
		Child.ancestors.to_s.should match( /Child, \(\|Parent\|.*\), Object.*BasicObject/ )


		# Class-level Injector update re-introduces it to objects that have ejected it locally and ancestors is updated
		Child.send :update, Parent()
		c.singleton_class.ancestors.to_s.should match( /Child, \(\|Parent\|.*\), Object.*BasicObject/ )

	end
end

describe "Injector Inheritance" do

	it 'carries current methods onto Injector Versions/Tags' do

		# Define trait
		
		jack :bounce

		bounce do
			def sound
				'splat splat'
			end
		end
    
		
		# Define Tag with new methods
		
		TagOne = bounce do 
			def bounce
				'boing boing'
			end
		end       
		
		
		# Apply Tag

		class Ball
			inject TagOne 
		end
		Ball.new.bounce.should == 'boing boing'


		class Spring
			inject TagOne
		end
		Spring.new.bounce.should == 'boing boing'


		# Inherited methods from :bounce

		Ball.new.sound.should == 'splat splat'
		Spring.new.sound.should == 'splat splat'

	end

	a "more complex example: effectively working Ruby's multiple inheritance" do

		jack :player do                       
			def sound                               
				'Lets make some music'                
			end                                     
		end                                       

		TapePlayer = player do                 
			def play                                
				return 'Tape playing...' + sound()                          
			end                                     
		end                                       

		CDPlayer = player do
			def play
				return 'CD playing...' + sound()
			end
		end

		class BoomBox
			include TapePlayer

			def on
				play
			end
		end

		class JukeBox < BoomBox
			inject CDPlayer
		end

		BoomBox.new.on.should == 'Tape playing...Lets make some music'
		JukeBox.new.on.should == 'CD playing...Lets make some music'
        
		#...                       

		jack :speakers

		Bass = speakers do                   
			def sound                               
				super + '...boom boom boom...'        
			end                                     
		end                   
		                    
		JukeBox.inject Bass
		JukeBox.new.on.should == 'CD playing...Lets make some music...boom boom boom...'

	end


	it "allows a just-in-time inheritance policy" do
	
		trait :Functionality
		
		# 
		# Our Modular Closure
		# 
		Tag1 = Functionality do
			def m1
				1
			end
			
			def m2
				:m2
			end
		end
		
		expect(Tag1.ancestors).to eql( [Tag1] )
		expect(Functionality().ancestors).to eql( [Functionality()] )


		# 
		# Normal Injector inheritance
		# 
		Functionality do
			def other  					# No overrides No inheritance
				'other'						# -- same ancestors as before
			end 								# -- normal trait inheritance
		end
		
		# test it

		expect(Tag1.ancestors).to eql( [Tag1] )
		expect(Functionality().ancestors).to eql( [Functionality()] )
		
		o  = Object.new.extend(Functionality())
		
		# inherited
		o.m1.should == 1
		o.m2.should == :m2
		
		# current
		o.other.should == 'other'
		
		
		#
		# JIT inheritance
		# 
		Tag2 = Functionality do
			def m1														# The :m1 override invokes JIT inheritance
				super + 1												# -- Tag1 is added as ancestor
			end 															# -- allows the use of super
			
			def m3							
				'em3'
			end
		end
		
		# test it
		
		expect(Tag2.ancestors).to eq([Tag2])
		expect(Functionality().ancestors).to eq([Functionality()])
		
		p = Object.new.extend(Tag2)
		
		# JIT inherited
		p.m1.should == 2										# using inherited function
		
		# regular inheritance
		p.m2.should == :m2
		p.m3.should == 'em3'
		p.other.should == 'other'

		Functionality(:implode)
		
	end
	
	
	########################## important ############################
	# For more information on JIT Inheritance (jiti), please see:   #
	# the accompanying spec file jiti_rules_spec.rb in the specs    #
	# directory.																										#
	#################################################################
	

end

describe "the behavior of traits under class inheritance" do
	
	before do
		
		suppress_warnings do
			
	    C = Class.new
			D = Class.new(C)
			E = Class.new(D)
			
	    trait :j

	    C.inject j { 																	# #m1 pre-defined at time of injection
	      def m1
	        'foo'
	      end
	    }

	    trait :k

	    C.inject k do 																# #m2 pre-defined at injection
	      def m2
	        'faa'
	      end
	    end

		end

	end
	
	after do

		suppress_warnings do
			
			j(:implode)
			k(:implode)

			C = nil
			D = nil
			E = nil
			
		end
		
	end
	
	it 'works on a first level' do
		
    C.traits.sym_list.should == [:k, :j]
    C.new.traits.sym_list.should == [:k, :j]
    c = C.new

		# New Objects
    with C.new do
			m1.should == 'foo'											
    	m2.should == 'faa'
		end
		# Existing objects
		with c do
			m1.should == 'foo'											
    	m2.should == 'faa'
		end
		
	end
	
	example "adding another level" do
	
	
		####################################
    # Preamble
		####################################
    c = C.new														# carry over from above

		####################################
    # D inherits from C
		####################################
    class D < C													# methods are inherited from j and k
    end

    D.traits(:all).sym_list.should == [:k, :j]					
    D.new.traits(:all).sym_list.should == [:k, :j]					
		d = D.new
		
		# New Objects
    with D.new do
			m1.should == 'foo'
    	m2.should == 'faa'
		end
		# Existing objects
		with c, d do
			m1.should == 'foo'											
    	m2.should == 'faa'
		end
	
	end
	
	example 'traits on second level' do
	
		####################################
    # Preamble
		####################################
    c = C.new

		####################################
		# inject into D overriding C
		####################################
		D.inject j { 												# new version of j pre-defined at injection
			def m1
				'foooo'
			end
		}
    D.traits(:all).sym_list.should == [:j, :k, :j]
    D.new.traits(:all).sym_list.should == [:j, :k, :j]
    d = D.new

		# New Objects
		with D.new do
	    m1.should == 'foooo'							# new version of #m1
	    m2.should == 'faa'								# still the same
		end
		# Existing Objects
		with c do
	    m1.should == 'foo'
	    m2.should == 'faa'
		end
		with d do
	    m1.should == 'foooo'
	    m2.should == 'faa'
		end
	end
	
	it 'class overrides at second level' do
	
		########################################
    # Preamble (from above)
		########################################
    c = C.new

		D.inject j { 												# new version of j pre-defined at injection
			def m1
				'foooo'
			end
		}

		####################################
    # Override injections at class level
		####################################
    class D < C
      def m1                            # overrides foo from j
        'fuu'
      end
    end
    C.traits.sym_list.should == [:k, :j]
    C.new.traits.sym_list.should == [:k, :j]
    D.traits.sym_list.should == [:j]
    D.new.traits.sym_list.should == [:j]
    d = D.new

		# New Objects
		with D.new do
	   	m1.should == 'fuu'								# overrided last version from j
	    m2.should == 'faa'								# still the same
		end
		with C.new do
	    m1.should == 'foo'
	    m2.should == 'faa'
		end
		# Existing Objects
		with c do
	    c.m1.should == 'foo'
	    c.m2.should == 'faa'
		end
		with d do
	    d.m1.should == 'fuu'							# overrided
	    d.m2.should == 'faa'
		end

	end
	
	it 'allows updates to methods at their respective level' do
		
		####################################
    # Preamble ( carry from above)
		####################################
    c = C.new

		D.inject j { 												# new version of j pre-defined at injection
			def m1
				'foooo'
			end
		}
    class D < C
      def m1                            # overrides foo from j
        'fuu'
      end
    end

		####################################
		# update K and inherit into D
		####################################
		C.send :update, k { 								# new version of k pre-defined at update
			def m2														# -- no other version of k in hierarchy
				'faaxx'
			end
		}
		# can also be written
		# class C
		# 	update k 				# providing k is in scope
		# end
		
    C.traits.sym_list.should == [:k, :j]
    C.new.traits.sym_list.should == [:k, :j]
    D.traits.sym_list.should == [:j]
    D.new.traits.sym_list.should == [:j]
		d = D.new
		
		# New Objects
		with D.new do
	    m2.should == 'faaxx'
	    m1.should == 'fuu'
		end
    with C.new do
			m2.should == 'faaxx'							# new version of m1faa
	    m1.should == 'foo'								# still the same
		end
		# Existing Objects
		with c do
	    m1.should == 'foo'
	    m2.should == 'faaxx'
		end
		with d do
	    m1.should == 'fuu'
	    m2.should == 'faaxx'
		end

	end
	
	it 'goes on to other levels' do
	
		####################################
    # Preamble (carry from above)
		####################################
    c = C.new

		D.inject j { 												# new version of j pre-defined at injection
			def m1
				'foooo'
			end
		}
    class D < C
      def m1                            # overrides foo from j
        'fuu'
      end
    end
		C.send :update, k { 								# new version of k pre-defined at update
			def m2														# -- no other version of k in hierarchy
				'faaxx'
			end
		}

		####################################
    # E inherits from D
		####################################
    class E < D													# methods are inherited from j at C, D and k update at C
    end
    C.traits.sym_list.should == [:k, :j]
    C.new.traits.sym_list.should == [:k, :j]
    D.traits.sym_list.should == [:j]
    D.new.traits.sym_list.should == [:j]
    E.traits.sym_list.should == []
    E.new.traits.sym_list.should == []

		d = D.new
		e = E.new

		# New Objects
    C.new.m1.should == 'foo'
    C.new.m2.should == 'faaxx'
    D.new.m1.should == 'fuu'
    D.new.m2.should == 'faaxx'          # new objects pass
    E.new.m1.should == 'fuu'
    E.new.m2.should == 'faaxx'
		# Existing Objects
    c.m1.should == 'foo'
    c.m2.should == 'faaxx'              # existing objects pass
    d.m1.should == 'fuu'
    d.m2.should == 'faaxx'
		e.m1.should == 'fuu'
		e.m2.should == 'faaxx'
	end
	
	this 'new class level override' do
		
		########################################
    # Preamble (carry from above)
		########################################
    c = C.new

		D.inject j { 																	# new version of j pre-defined at injection
			def m1
				'foooo'
			end
		}
    class D < C
      def m1                                     # overrides foo from j
        'fuu'
      end
    end
		C.send :update, k { 													# new version of k pre-defined at update
			def m2																			# -- no other version of k in hierarchy
				'faaxx'
			end
		}

		########################################
		# E overrides D
		########################################
    class E < D
      def m1																			# overrides #foo from j at C, D
        'fuuuu'
      end
    end
		d = D.new
		e = E.new

		# New Objects
    C.new.m1.should == 'foo'
    C.new.m2.should == 'faaxx'
    D.new.m1.should == 'fuu'
    D.new.m2.should == 'faaxx'
    E.new.m1.should == 'fuuuu'
    E.new.m2.should == 'faaxx'
		# Existing Objects
    c.m1.should == 'foo'
    c.m2.should == 'faaxx'
    d.m1.should == 'fuu'
    d.m2.should == 'faaxx'
    e.m1.should == 'fuuuu'
    e.m2.should == 'faaxx'

	end

	describe 'ejection' do
		
		before do
			########################################
	    # Preamble (carry from above)
			########################################

			D.inject j { 																	# new version of j pre-defined at injection
				def m1
					'foooo'
				end
			}
	    class D < C
	      def m1                                     # overrides foo from j
	        'fuu'
	      end
	    end
			C.send :update, k { 													# new version of k pre-defined at update
				def m2																			# -- no other version of k in hierarchy
					'faaxx'
				end
			}

			########################################
			# E overrides D
			########################################
	    class E < D
	      def m1																			# overrides #foo from j at C, D
	        'fuuuu'
	      end
	    end
		end

		it 'works with ejection' do

	    c = C.new
			d = D.new
			e = E.new
			
	    #######################################
	    # ejection                                  
			#######################################
	    C.eject :j                                    # eject j from C

	    C.new.traits.sym_list.should == [:k]
	    C.traits.sym_list.should == [:k]
	    D.new.traits.sym_list.should == [:j]
	    D.traits.sym_list.should == [:j]
	    E.new.traits.sym_list.should == []
	    E.traits.sym_list.should == []

			# New Objects
	    expect{ C.new.m1.should == 'foo'}.to raise_error(NoMethodError)  # m1 errors out on C
	    C.new.m2.should == 'faaxx'
	    D.new.m1.should == 'fuu' 
	    D.new.m2.should == 'faaxx'                   # all else is the same...
	    E.new.m1.should == 'fuuuu' 
	    E.new.m2.should == 'faaxx'
	    # Existing Objects
	    expect{c.m1.should == 'foo'}.to raise_error(NoMethodError)   # m1 errors out on C
	    c.m2.should == 'faaxx'
	    d.m1.should == 'fuu'
	    d.m2.should == 'faaxx'
	    e.m1.should == 'fuuuu'
	    e.m2.should == 'faaxx'


			########################################
	    # more ejection
			########################################
	    C.eject :k                                    # eject the only k

	    C.new.traits.sym_list.should == []
	    C.traits.sym_list.should == []
	    D.new.traits.sym_list.should == [:j]
	    D.traits.sym_list.should == [:j]
	    E.new.traits.sym_list.should == []
	    E.traits.sym_list.should == []

			# New Objects
	    expect{ C.new.m1.should == 'foo'}.to raise_error(NoMethodError) 
	    expect{ C.new.m2.should == 'faaxx'}.to raise_error(NoMethodError) # # faa errors out
	    D.new.m1.should == 'fuu' 										
	    expect{ D.new.m2.should == 'faaxx'}.to raise_error(NoMethodError) #faa errors out 
	    E.new.m1.should == 'fuuuu' 
	    expect{ E.new.m2.should == 'faaxx'}.to raise_error(NoMethodError) #faa was only available thru k at C 
	    # Existing Objects
	    expect{c.m1.should == 'foo'}.to raise_error(NoMethodError)
	    expect{c.m2.should == 'faaxx'}.to raise_error(NoMethodError)
	    d.m1.should == 'fuu'													# same thing for pre-existing objects
	    expect{d.m2.should == 'faaxx'}.to raise_error(NoMethodError)
	    e.m1.should == 'fuuuu'
	    expect{e.m2.should == 'faaxx'}.to raise_error(NoMethodError)


			########################################
	    # more ejection
			########################################
	    D.eject :j                                    # eject j from D: the only one remaining
	    																							# -- everything should revert back to class level
	    C.traits.sym_list.should == []
	    C.new.traits.sym_list.should == []
	    D.traits.sym_list.should == []
	    D.new.traits.sym_list.should == []
	    E.traits.sym_list.should == []
	    E.new.traits.sym_list.should == []

			# New Objects
	    expect{ C.new.m1.should == 'foo'}.to raise_error(NoMethodError) # no actual #foo on class 
	    expect{ C.new.m2.should == 'faaxx'}.to raise_error(NoMethodError) #         ''
	    D.new.m1.should == 'fuu' 										# retains overrides from D
	    expect{ D.new.m2.should == 'faaxx'}.to raise_error(NoMethodError) 
	    E.new.m1.should == 'fuuuu' 									# retains overrides from E
	    expect{ E.new.m2.should == 'faaxx'}.to raise_error(NoMethodError) 
	    # Existing Objects
	    expect{c.m1.should == 'foo'}.to raise_error(NoMethodError)
	    expect{c.m2.should == 'faaxx'}.to raise_error(NoMethodError)
	    d.m1.should == 'fuu'													# same for pre-existing objects
	    expect{d.m2.should == 'faaxx'}.to raise_error(NoMethodError)
	    e.m1.should == 'fuuuu'												
	    expect{e.m2.should == 'faaxx'}.to raise_error(NoMethodError)

	  end
	end

	describe 'some special cases' do
		
		the 'behavior when re-applying a new version of same Injector further down the line' do

			class C1
			end

			# Define a blanck Injector

			trait :j1

			# Apply to hierarchy while defining

			C1.inject j1	do 															# same as pre-defined
				def m1                                     
					'm1'                                     
				end                                         
			end                                           
			C1.new.m1.should == 'm1'											# call on Injector


			# DD inherits from CC                         

			class D1 < C1                                 
			end                                           # call on Injector
			D1.new.m1.should == 'm1'										


			# EE inherits from DD                         

			class E1 < D1                                 
			end                                           # call on Injector
			E1.new.m1.should == 'm1'										


			############################
			# NEW VERSION! 
			############################
			j1 do 																				
				def m1                                     	# -- previous was applied to C1
					'm1xx'                                   	# this #m1 only defined in the Virtual Method Cache
				end
			end                                          

			# Calls un-affected  !!                       # have existing version

			C1.new.m1.should == 'm1'
			D1.new.m1.should == 'm1'
			E1.new.m1.should == 'm1'


			E1.inject j1                      						# APPLY to hierarchy on E!

			C1.new.m1.should == 'm1'                  		# same
			D1.new.m1.should == 'm1'                  		# same
			E1.new.m1.should == 'm1xx'                		# changed

		end

		it 'also passes on this case' do

			class C2
			end                                         

			# Define a blank Injector

			trait :j2

			# Apply full definition to an ancestor

			Object.inject j2 do
				def m1
					'm1xx'
				end
			end
			# same effect as above
			C2.new.m1.should == 'm1xx'                	# call Injector


			############################
			# NEW VERSION! 
			############################

			j2 do 																				# NEW VERSION! 
				def m1                                      # -- previous was applied to Object in the hierarchy
					'm1'                                      # this #m1 only defined in the Virtual Method Cache
				end
			end

			# Calls un-afffected !!

			C2.new.m1.should == 'm1xx'									# still using the previous version --no changes


			# Inherit

			class D2 < C2
			end
			D2.new.m1.should == 'm1xx'									# using previous version


			# Inherit

			class E2 < D2
			end
			E2.new.m1.should == 'm1xx'									# using previous version


			###########################
	    # Apply new version on C
			###########################

			C2.inject j2												

			# Calls changed from C on up

			C2.new.m1.should == 'm1'
			D2.new.m1.should == 'm1'
			E2.new.m1.should == 'm1'										# new version of #m1


			# Call on ancestor the same

			Object.new.m1.should == 'm1xx'							# previous version


			# back to normal

			Object.eject j2															# so we do no interfere with other tests!!

		end

		it 'acts differently when using the Virtual Method Cache (VMC)' do

			class C3
			end

			# Define a Blank Injector

			trait :j3


			# Apply the blank trait

			C3.inject j3													

			############################
			# NEW VERSION! 
			############################

			j3 do 																				# 
				def m1                                      # -- never applied to Object in the hierarchy
					'm1'                                      # this #m1 only defined in the Virtual Method Cache
				end
			end


			# C3 calls

			C3.new.m1.should == 'm1'											# call works from VMC


			# D3 inherits from C3

			class D3 < C3
			end
			D3.new.m1.should == 'm1'											# inherited call from VMC


			# E3 inherits from D3

			class E3 < D3
			end
			E3.new.m1.should == 'm1'											# inherited call from VMC


			###################################
			# Re-define Virtual Method Cache
			# -- previously un-applied methods
			###################################

			j3 do 																				# NEW VERSION!
				def m1                                      # -- never applied to Object in the hierarchy
					'm1xx'                                    # this #m1 only defined in the Virtual Method Cache
				end
			end                 

			##############################
			# Calls are also re-defined
			##############################
			
			C3.new.m1.should == 'm1xx'                  	# call is redefined
			D3.new.m1.should == 'm1xx'                  	#      '' 
			E3.new.m1.should == 'm1xx'                  	#      ''


			# Apply the full Injector onto E3

			E3.inject j3                      						# Attaches this version onto E only!!

			# calls

			C3.new.m1.should == 'm1xx'                  	# =>  from cache
			D3.new.m1.should == 'm1xx'                  	#    ''

			E3.new.m1.should == 'm1xx'                  	# =>  from applied version


			############################
			# NEW VERSION! 
			############################

			j3 do 																				
				def m1                                      # -- never applied to Object in the hierarchy
					'-----'                                   # this #m1 only defined in the Virtual Method Cache
				end
			end


			# calls

			C3.new.m1.should == '-----'									# re-defined!!                  
			D3.new.m1.should == '-----'                 #      ''

			E3.new.m1.should == 'm1xx'                  # NOT REDEFINED!!
																									# from full applied version

		end

	end
end

