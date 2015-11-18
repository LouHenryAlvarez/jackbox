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



# RubyProf.start
describe "ancestor chains" do

	it 'updates the ancestor chains accordingly based on: injections and ejections' do

    # LifeCycle Start

		injector :Parent															# capitalized method
		
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


		# Note: cannot update empty injector
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

describe "the behavior of injectors under class inheritance" do
	
	example "working accross class hierarchies and the effects of ejection" do
	
	
		###########################################
		# injection
		###########################################
    injector :j

    class C
    end
    C.inject j { 																	# #foo pre-defined at time of injection
      def m1
        'foo'
      end
    }
    C.injectors.sym_list.should == [:j]
    C.new.injectors.sym_list.should == [:j]

    injector :k

    C.inject k { 																	# #faa pre-defined at injection
      def m2
        'faa'
      end
    }
    C.injectors.sym_list.should == [:k, :j]
    C.new.injectors.sym_list.should == [:k, :j]
	
    C.new.m1.should == 'foo'
    C.new.m2.should == 'faa'
    c = C.new


		########################################
    # D inherits from C
		########################################
    class D < C																		# methods are inherited from j and k
    end
    C.injectors.sym_list.should == [:k, :j]
    C.new.injectors.sym_list.should == [:k, :j]
    D.injectors.sym_list.should == []
    D.new.injectors.sym_list.should == []

		# New Objects
    C.new.m1.should == 'foo'											
    C.new.m2.should == 'faa'
    D.new.m1.should == 'foo'
    D.new.m2.should == 'faa'
		# Existing Objects
    d = D.new
    c.m1.should == 'foo'
    c.m2.should == 'faa'
	
	
		########################################
		# inject D and override C
		########################################
		D.inject j { 																	# new version of j pre-defined at injection
			def m1
				'foooo'
			end
		}
    C.injectors.sym_list.should == [:k, :j]
    C.new.injectors.sym_list.should == [:k, :j]
    D.injectors.sym_list.should == [:j]
    D.new.injectors.sym_list.should == [:j]

		# New Objects
    D.new.m1.should == 'foooo'										# new version of #foo
		# still the same
    D.new.m2.should == 'faa'
    C.new.m1.should == 'foo'
    C.new.m2.should == 'faa'
		# Existing Objects
    c.m1.should == 'foo'
    c.m2.should == 'faa'
    d.m1.should == 'foooo'
    d.m2.should == 'faa'
	
	
		########################################
		# D class overrides j
		########################################
    class D < C
      def m1                                     # overrides foo from j
        'fuu'
      end
    end
    C.injectors.sym_list.should == [:k, :j]
    C.new.injectors.sym_list.should == [:k, :j]
    D.injectors.sym_list.should == [:j]
    D.new.injectors.sym_list.should == [:j]

		# New Objects
    D.new.m1.should == 'fuu'											# overrided last version from j
		# still the same
    D.new.m2.should == 'faa'
    C.new.m1.should == 'foo'
    C.new.m2.should == 'faa'
		# Existing Objects
    c.m1.should == 'foo'
    c.m2.should == 'faa'
    d.m1.should == 'fuu'													# overrided
    d.m2.should == 'faa'
	
		
		########################################
		# update C and inherit into D
		########################################
		C.send :update, k { 													# new version of k pre-defined at update
			def m2																			# -- no other version of k in hierarchy
				'faaxx'
			end
		}
		# can also be written
		# class C
		# 	update k 				# providing k is in scope
		# end
    C.injectors.sym_list.should == [:k, :j]
    C.new.injectors.sym_list.should == [:k, :j]
    D.injectors.sym_list.should == [:j]
    D.new.injectors.sym_list.should == [:j]
	
		# New Objects
    C.new.m2.should == 'faaxx'										# new version of #faa
    D.new.m2.should == 'faaxx'
		# still the same
    C.new.m1.should == 'foo'
    D.new.m1.should == 'fuu'
		# Existing Objects
    c.m1.should == 'foo'
    c.m2.should == 'faaxx'
    d.m1.should == 'fuu'
    d.m2.should == 'faaxx'
	
	
		########################################
    # E inherits from D
		########################################
    class E < D																		# methods are inherited from j at C, D and k update at C
    end
    C.injectors.sym_list.should == [:k, :j]
    C.new.injectors.sym_list.should == [:k, :j]
    D.injectors.sym_list.should == [:j]
    D.new.injectors.sym_list.should == [:j]
    E.injectors.sym_list.should == []
    E.new.injectors.sym_list.should == []

		# New Objects
    C.new.m1.should == 'foo'
    C.new.m2.should == 'faaxx'
    D.new.m1.should == 'fuu'
    D.new.m2.should == 'faaxx'                   # new objects pass
    E.new.m1.should == 'fuu'
    E.new.m2.should == 'faaxx'
		# Existing Objects
    e = E.new
    c.m1.should == 'foo'
    c.m2.should == 'faaxx'                       # existing objects pass
    d.m1.should == 'fuu'
    d.m2.should == 'faaxx'
	
	
		########################################
		# E overrides D
		########################################
    class E < D
      def m1																			# overrides #foo from j at C, D
        'fuuuu'
      end
    end
    C.injectors.sym_list.should == [:k, :j]
    C.new.injectors.sym_list.should == [:k, :j]
    D.injectors.sym_list.should == [:j]
    D.new.injectors.sym_list.should == [:j]
    E.injectors.sym_list.should == []
    E.new.injectors.sym_list.should == []

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
	
	
    #######################################
    # ejection                                  
		#######################################
    C.eject :j                                    # eject j from C
    
    C.new.injectors.sym_list.should == [:k]
    C.injectors.sym_list.should == [:k]
    D.new.injectors.sym_list.should == [:j]
    D.injectors.sym_list.should == [:j]
    E.new.injectors.sym_list.should == []
    E.injectors.sym_list.should == []

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
    
    C.new.injectors.sym_list.should == []
    C.injectors.sym_list.should == []
    D.new.injectors.sym_list.should == [:j]
    D.injectors.sym_list.should == [:j]
    E.new.injectors.sym_list.should == []
    E.injectors.sym_list.should == []

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
    C.injectors.sym_list.should == []
    C.new.injectors.sym_list.should == []
    D.injectors.sym_list.should == []
    D.new.injectors.sym_list.should == []
    E.injectors.sym_list.should == []
    E.new.injectors.sym_list.should == []
		
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

	describe 'some special cases' do
		
		the 'behavior when re-applying a new version of same Injector further down the line' do

			class C1
			end

			# Define a blanck Injector

			injector :j1


			# Apply to hierarchy root as defined

			C1.inject j1	do 															# apply definitions
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
			# Re-define methods
			############################
			j1 do 																				# NEW VERSION! because previous had an application
				def m1                                     	# -- was applied to C1 in the hierarchy
					'm1xx'                                   	# Methods only defined in the Virtual Method Cache
				end
			end                                          

			# Calls un-affected  !!                       # have existing version

			C1.new.m1.should == 'm1'
			D1.new.m1.should == 'm1'
			E1.new.m1.should == 'm1'


			E1.inject j1                      						# apply to hierarchy on E

			C1.new.m1.should == 'm1'                  		# same
			D1.new.m1.should == 'm1'                  		# same
			E1.new.m1.should == 'm1xx'                		# changed

		end

		it 'also passes on this case' do

			class C2
			end                                         

			# Define a blank Injector

			injector :j2


			# Apply <full> Injector definition to an ancestor

			Object.inject j2 do
				def m1
					'm1xx'
				end
			end


			# Call on the Injector

			C2.new.m1.should == 'm1xx'                	# call Injector


			############################
			# Re-define methods
			############################

			j2 do 																				# NEW VERSION! because previous had an application
				def m1                                      # -- was applied to Object in the hierarchy
					'm1'                                      # Methods only defined in the Virtual Method Cache
				end
			end

			# Calls un-afffected 

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
	    # Finally apply new version
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

			injector :j3


			# Apply the blank injector

			C3.inject j3													


			# Define function after the application

			j3 do 																				# NEW VERSION!
				def m1                                      # -- never applied to Object in the hierarchy
					'm1'                                      # Methods only defined in the Virtual Method Cache
				end
			end


			# C3 calls

			C3.new.m1.should == 'm1'											# call works as normal from VMC


			# D3 inherits from C3

			class D3 < C3
			end
			D3.new.m1.should == 'm1'											# inherited call 


			# E3 inherits from D3

			class E3 < D3
			end
			E3.new.m1.should == 'm1'											# inherited call


			###################################
			# Re-define Virtual Method Cache
			# -- previously un-applied methods
			###################################

			j3 do 																				# NEW VERSION!
				def m1                                      # -- never applied to Object in the hierarchy
					'm1xx'                                    # Methods only defined in the Virtual Method Cache
				end
			end                 


			# Calls are also re-defined

			C3.new.m1.should == 'm1xx'                  	# call is redefined
			D3.new.m1.should == 'm1xx'                  	#      '' 
			E3.new.m1.should == 'm1xx'                  	#      ''


			# Apply the <full> Injector onto E3

			E3.inject j3                      						# Attaches this version onto E only!!

			# calls

			C3.new.m1.should == 'm1xx'                  	# =>  from cache
			D3.new.m1.should == 'm1xx'                  	#    ''

			E3.new.m1.should == 'm1xx'                  	# =>  from applied version


			################################
			# Re-define cached methods
			#################################

			j3 do 																				# NEW VERSION!
				def m1                                      # -- never applied to Object in the hierarchy
					'-----'                                   # Methods only defined in the Virtual Method Cache
				end
			end


			# calls

			C3.new.m1.should == '-----'									# re-defined!!                  
			D3.new.m1.should == '-----'                 #      ''

			E3.new.m1.should == 'm1xx'                  # NOT REDEFINED!!
																									# from applied version

		end

	end
end

describe "regular Injector internal inheritance" do

	it 'carries current methods onto Injector Versions/Tags' do

		# Define injector
		
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


	it 'works accross compound injectors' do

			jack :S1

			S1 do
				include jack :s2 do
					def s2m1
						:s2m1
					end
					include jack :s3 do
						def s3m1
							:s3m1
						end
						include jack :s4 do
							def s4m1
								:s4m1
							end
						end
					end
				end
			end
			
			S1().s2.s3.s4       													# injector pipeline!


			# Apply the injectors

			class CompoundContainer
				include S1()
			end

			CompoundContainer.new.s2m1.should == :s2m1
			CompoundContainer.new.s3m1.should == :s3m1
			CompoundContainer.new.s4m1.should == :s4m1


			# Add methods to the VMC of s3

			S1().s2.s3 do
				def s3m2
					:s3m2
				end
			end

			CompoundContainer.new.s3m2.should == :s3m2


			# Create a version Tag

			AccessTag = S1() 

			class SecondContainer
				include AccessTag
			end

			SecondContainer.new.s3m2.should == :s3m2
			
	end

	it 'works accross the VMC' do

		expect{
			
		 	injector :J1
		 	injector :J2
		 	injector :J3

			class AA1
			end
			J1 do
				include J2()
			end
			J2 do
				def mJ2						# virtual cache method
					:mJ2
				end
			end
			J1 do
				def mJ1						# applied method
					:mJ1
				end
			end
			class AA1
				include J1()
			end

			AA1.new.mJ2.should == :mJ2
			AA1.new.mJ1.should == :mJ1

		}.not_to raise_error
		
	end 

	a 'different example' do

		expect{
			
			injector :K1
			injector :K2
			injector :K3

			K1 do
			  include K2() do
			    def mj2						# applied method
						:mj2
			    end
			  end
			end
			class AA2
			  include K1()
			end
			AA2.new.mj2.should == :mj2
			K2 do
			  include K3() do
			    def mj3						# virtual cache method with another indirect
						:mj3
			    end
			  end
			end
			AA2.new.mj3.should == :mj3

		}.not_to raise_error
		
	end

	a 'yet different one' do

		expect{
			
			injector :M1
			injector :M2
			injector :M3

			M1 do
				include M2() do
					def mk2						# applied method
						:mk2
					end
				end
			end
			class AA3
				include M1()
			end
			AA3.new.mk2.should == :mk2
			M2 do
				include M3()
			end
			M3 do
				def mk3							# virtual cache method
					:mk3
				end
			end
			AA3.new.mk3.should == :mk3

		}.not_to raise_error
		
	end

	describe 'jit inheriatnce' do

		before do
			injector :Tagger

		end
		
		after do
			Tagger(:implode)
			
		end
		
		
		
		it "follows a just-in-time inheritance policy" do
		
			# 
			# Our Modular Closure
			# 
			Tag1 = Tagger do
				def m1
					1
				end
				
				def m2
					:m2
				end
			end
			
			expect(Tag1.ancestors).to eql( [Tag1] )
			expect(Tagger().ancestors).to eql( [Tagger()] )


			# 
			# Normal Injector inheritance
			# 
			Tagger do
				def other  					# No overrides No inheritance
					'other'						# -- same ancestors as before
				end 								# -- normal injector inheritance
			end
			
			# test it

			expect(Tag1.ancestors).to eql( [Tag1] )
			expect(Tagger().ancestors).to eql( [Tagger()] )
			
			o  = Object.new.extend(Tagger())
			
			# inherited
			o.m1.should == 1
			o.m2.should == :m2
			
			# current
			o.other.should == 'other'
			
			
			#
			# JIT inheritance
			# 
			Tag2 = Tagger do
				def m1							# The :m1 override invokes JIT inheritance
					super + 1					# -- Tag1 is added as ancestor
				end 								# -- allows the use of super
				
				def m3							
					'em3'
				end
			end
			
			# test it
			
			expect(Tagger().ancestors).to eql( [Tagger(), Tag1] )
			expect(Tag2.ancestors).to eql( [Tag2, Tag1] )
			
			p = Object.new.extend(Tag2)
			
			# JIT inherited
			p.m1.should == 2
			
			# regular inheritance
			p.m2.should == :m2
			p.m3.should == 'em3'
			p.other.should == 'other'

			
			#
			# Under Inclusion
			# 
			class AA6
				inject Tag2
			end
			aa6 = AA6.new
			
			# test it
			
			aa6.m1.should == 2
			aa6.m2.should == :m2
			aa6.m3.should == 'em3'


			#
			# One more level: mixed level inheritance
			# 
			Tag3 = 	Tagger() do
				def m1
					super * 2 					# second override to #m1 
				end                   # -- Tag2 added as ancestor
				def m3
					super * 2						# first override to #m3
				end 								
			end
			
			# test it

			expect(Tagger().ancestors).to eql( [Tagger(), Tag2, Tag1] )
			expect(Tag3.ancestors).to eql( [Tag3, Tag2, Tag1] )
			expect(Tag2.ancestors).to eql( [Tag2, Tag1] )
			
			class AA7
				inject Tag3 
			end
			aa7 = AA7.new

			# JIT inheritance
			aa7.m1.should == 4					
			aa7.m3.should == 'em3em3'
			
			# regular inheritance
			aa7.m2.should == :m2
			aa7.other.should == 'other'

			
			# 
			# Another version: back to basics
			# 
			Tagger() do
				def m1							# another override but no call to #super
					:m1								# -- ancestor added
				end 								
			end
			n = Object.new.extend(Tagger())
			
			# test it
			
			expect(Tagger().ancestors).to eql( [Tagger(), Tag3, Tag2, Tag1] )
			expect(Tag3.ancestors).to eql( [Tag3, Tag2, Tag1] )
			expect(Tag2.ancestors).to eql( [Tag2, Tag1] )
			
			
			n.m1.should == :m1		# new version of #m1
			
			# JIT
			n.m3.should == 'em3em3'
			
			# regular
			n.m2.should == :m2

			
			# 
			# Test previous versions
			# 
			aa6.m1.should == 2
			aa6.m2.should == :m2
			aa6.m3.should == 'em3'
			
			aa66 = AA6.new
			
			aa66.m1.should == 2
			aa66.m2.should == :m2
			aa66.m3.should == 'em3'

			aa7.m1.should == 4
			aa7.m2.should == :m2
			aa7.m3.should == 'em3em3'

			aa77 = AA7.new

			aa77.m1.should == 4
			aa77.m2.should == :m2
			aa77.m3.should == 'em3em3'


			#
			# other clients
			#
			class AA6B
				inject Tag2
			end
			aa6b = AA6B.new
			
			aa6b.m1.should == 2
			aa6b.m2.should == :m2
			aa6b.m3.should == 'em3'
			
			#
			# VMC (Virtual Method Cache) method
			#
			Tagger() do
				def m4							
					:m4
				end
			end

			# test it
			
			expect(Tagger().ancestors).to eql([Tagger(), Tag3, Tag2, Tag1])
			expect(Tag3.ancestors).to eql( [Tag3, Tag2, Tag1] )
			expect(Tag2.ancestors).to eql( [Tag2, Tag1] )
			
			aa6b.m1.should == 2
			aa6b.m2.should == :m2
			aa6b.m3.should == 'em3'
			aa6b.m4.should == :m4		# vmc method
			
			
			# Total Tags
			
			Tagger().tags.should == [Tag1, Tag2, Tag3]
			
		end
		
		it "also allows further ancestor injection" do
			
			Tag4 = Tagger do
				def m1
					1
				end
				def m2
					:m2
				end
			end
		
			module Mod1
				def m1
					'one'
				end
			end
		
			Tag5 = Tagger(Mod1) do
				
				# include Mod1											# alternatively
				
				def m1
					super * 2					# invoking inheritance for Tag5 !!
				end
				def m3
					:m3
				end
			end

			expect(Tagger().ancestors).to eql([Tagger(), Mod1, Tag4])
			expect(Tag4.ancestors).to eql([Tag4])
			expect(Tag5.ancestors).to eql([Tag5, Mod1, Tag4])

			# test it 
		
			Object.new.extend(Tag5).m1.should == 'oneone'
			Object.new.extend(Tag5).m2.should == :m2
			Object.new.extend(Tag5).m3.should == :m3
			
			# other prolongation
			
			Object.new.extend(Tagger(){
				def m4
					:m4
				end
			}).m4.should == :m4
			
		end
		
		it 'also works like this' do
			
			Tag6 = Tagger do
				def m1
					super() * 2
				end
				def m2
					:m2
				end
			end
			
			module Mod2
				def m1
					3
				end
			end
			
			Object.new.extend(Tagger(Mod2)).m1.should == 6
			Object.new.extend(Tagger(Mod2)).m2.should == :m2
			
		end
		
		this "also possible" do
			
			Tag7 = Tagger do
				def m1
					1
				end
				def m2
					:m2
				end
			end
			
			Tag8 = Tagger do
				def m1
					super * 2
				end
				def m3
					:m3
				end
			end
			
			# test it
		
			Object.new.extend(Tag8).m1.should == 2


			#
			# On the fly overrides
			# 
			obj = Object.new.extend(
				Tagger {
					def m1
						super + 3
					end
					def m4
						:m4
					end
				})
			obj.m1.should == 5
			obj.m2.should == :m2
			obj.m3.should == :m3
			obj.m4.should == :m4
				
		end
		
		this "one is a bit tricky" do
			
			Tag9 = Tagger do
				def m1
					1
				end
			end
		
			module Mod1
				def m1
					'one'
				end
			end
			
			Tag10 = Tagger() do
				
				include Mod1
				
				def m1
					super * 2
				end
			end
			
			# test it
		
			Object.new.extend(Tag10).m1.should == 'oneone'
			Object.new.extend(Tagger()).m1.should == 'oneone'
			
			Tag10.ancestors.should == [Tag10, Mod1, Tag9]
			
		end
		
		this 'further trick' do
			
			Tag11 = Tagger do
			  def m1
			    1
			  end
			  def m2 							# original definition
			    2
			  end
			end
			Tag12 = Tagger do
			  def m1
			    'm1'
			  end 								# skipped #m2
			end
			Tag13 = Tagger do
			  def m1
			    super * 2
			  end
			  def m2
			    super * 2					# override # m2 two levels down
			  end
			end
			class AA10
			  inject Tag13
			end
			
			# test it
			
			AA10.new.m1.should == 'm1m1'
			AA10.new.m2 == 4
			
			Tag13.ancestors.should == [Tag13, Tag12, Tag11]

		end
		
		it 'rebases' do
			
			Tag14 = Tagger do
				def m1
					1
				end
			end
			
			class AA11
				inject Tagger() do
					def m1
						super + 1
					end
				end
			end
			
			# test it
			
			AA11.new.m1.should == 2
			
			
			Tag15 = Tagger do
				def m1
					5									# rebase m1
				end
			end
			
			class BB11
				inject Tagger() do
					def m1
						super * 2				# new override
					end
				end
			end
			
			# test it
			
			BB11.new.m1.should == 10
			
			
		end
		
		it 'takes Injector Directives' do
			
			Tag16 = Tagger do
				def m1
					1
				end
			end
			
			class AA12
				inject Tagger() do
					def m1
						super + 1
					end
				end
			end
			
			AA12.new.m1.should == 2
			
			
			Tag17 = Tagger do
				def m1
					5									# rebase m1
				end
			end
			
			class BB12
				inject Tagger() do
					def m1
						super * 2				# new override
					end
				end
			end
			
			BB12.new.m1.should == 10
			
			# test directives
			
			Tagger(:silence)

			AA12.new.m1.should == nil										# both bases affected
			BB12.new.m1.should == nil
			
			Tagger(:active)
			
			AA12.new.m1.should == 2											# both bases restored
			BB12.new.m1.should == 10
			
		end
		
	end
end

# profile = RubyProf.stop
# RubyProf::FlatPrinter.new(profile).print(STDOUT)
# RubyProf::GraphHtmlPrinter.new(profile).print(open('profile.html', 'w+'))
# RubyProf::CallStackPrinter.new(profile).print(open('profile.html', 'w+'))
