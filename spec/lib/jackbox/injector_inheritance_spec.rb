require "spec_helper"
=begin rdoc
	
	Specifies the behavior of Injectors under inheritance
	
	. First we se how ancestors are treated
	. Next we treat Injectors under a class hierarchy
	. Then we see a few special cases in the realm of multiple inheritance
	
	lha
	
=end

include Injectors

describe "ancestor chains" do

	it 'updates the ancestor chains accordingly based on: injections and ejections' do
    
		injector :Parent															# capitalized method
		class Child
			include Parent()
		end
		Child.ancestors.to_s.should match( /Child, \(.*\|Parent\|\), Object.*BasicObject/ )

		c = Child.new.enrich Parent()                                                      
		# Parent is ancestor of the class and of the metaclass
		c.singleton_class.ancestors.to_s.should match( /\(.*\|Parent\|\), Child, \(.*\|Parent\|\), Object.*BasicObject/ )

		c.eject Parent()
		# Parent is ejected from the object metaclass and ancestor chain reverts back
		c.singleton_class.ancestors.to_s.should match( /Child, \(.*\|Parent\|\), Object.*BasicObject/ )

		Child.eject Parent()
		# Parent is ejected from the class and ancestors chain is empty
		Child.ancestors.to_s.should match( /Child, Object.*BasicObject/ )
		# cannot update empty injector
		expect{ Child.send :update, Child.parent }.to raise_error(NoMethodError) 

		c.enrich Parent()
		c.enrich Parent()
		# object metaclass is extended with Parent twice like in the case of multiple decorators
		c.singleton_class.ancestors.to_s.should match( /\(.*\|Parent\|\), \(.*\|Parent\|\), Child, Object.*BasicObject/ )

		c.eject Parent()
		c.eject Parent()
		# object is reverted back to no Injectors
		c.singleton_class.ancestors.to_s.should match( /Child, Object.*BasicObject/ )

		Child.inject Parent()
		# class is re-injected with Parent and ancestors is updated 
		Child.ancestors.to_s.should match( /Child, \(.*\|Parent\|\), Object.*BasicObject/ )              
		c.singleton_class.ancestors.to_s.should match( /Child, \(.*\|Parent\|\), Object.*BasicObject/ )

		c.eject Parent()
		# class level Injector ejected from single object and ancestor for the object updated but not for class
		c.singleton_class.ancestors.to_s.should match( /Child, Object.*BasicObject/ )
		Child.ancestors.to_s.should match( /Child, \(.*\|Parent\|\), Object.*BasicObject/ )

		Child.send :update, Parent()
		# class level Injector update re-introduces it to objects that have ejected it locally and ancestors is updated
		c.singleton_class.ancestors.to_s.should match( /Child, \(.*\|Parent\|\), Object.*BasicObject/ )

	end
end

describe "the inheritance behavior of injectors" do
	
	example "works accross class hierarchies" do
	
	
		###########################################
		# injection
		###########################################
    injector :j

    class C
    end
    C.inject j { 																	# #foo pre-defined at time of injection
      def foo
        'foo'
      end
    }
    C.injectors.sym_list.should == [:j]
    C.new.injectors.sym_list.should == [:j]

    injector :k

    C.inject k { 																	# #faa pre-defined at injection
      def faa
        'faa'
      end
    }
    C.injectors.sym_list.should == [:j, :k]
    C.new.injectors.sym_list.should == [:j, :k]
	
    C.new.foo.should == 'foo'
    C.new.faa.should == 'faa'
    c = C.new


    # D inherits from C

    class D < C																		# methods are inherited from j and k
    end
    C.injectors.sym_list.should == [:j, :k]
    C.new.injectors.sym_list.should == [:j, :k]
    D.injectors.sym_list.should == []
    D.new.injectors.sym_list.should == []

		# New Objects
    C.new.foo.should == 'foo'											
    C.new.faa.should == 'faa'
    D.new.foo.should == 'foo'
    D.new.faa.should == 'faa'
		# Existing Objects
    d = D.new
    c.foo.should == 'foo'
    c.faa.should == 'faa'
	
	
		# inject D and override C
		
		D.inject j { 																	# new version of j pre-defined at injection
			def foo
				'foooo'
			end
		}
    C.injectors.sym_list.should == [:j, :k]
    C.new.injectors.sym_list.should == [:j, :k]
    D.injectors.sym_list.should == [:j]
    D.new.injectors.sym_list.should == [:j]

		# New Objects
    D.new.foo.should == 'foooo'										# new version of #foo
		# still the same
    D.new.faa.should == 'faa'
    C.new.foo.should == 'foo'
    C.new.faa.should == 'faa'
		# Existing Objects
    c.foo.should == 'foo'
    c.faa.should == 'faa'
    d.foo.should == 'foooo'
    d.faa.should == 'faa'
	
	
		# D class overrides j
		
    class D < C
      def foo                                     # overrides foo from j
        'fuu'
      end
    end
    C.injectors.sym_list.should == [:j, :k]
    C.new.injectors.sym_list.should == [:j, :k]
    D.injectors.sym_list.should == [:j]
    D.new.injectors.sym_list.should == [:j]

		# New Objects
    D.new.foo.should == 'fuu'											# overrided last version from j
		# still the same
    D.new.faa.should == 'faa'
    C.new.foo.should == 'foo'
    C.new.faa.should == 'faa'
		# Existing Objects
    c.foo.should == 'foo'
    c.faa.should == 'faa'
    d.foo.should == 'fuu'													# overrided
    d.faa.should == 'faa'
	
		
		# update C and inherit into D
		
		C.send :update, k { 													# new version of k pre-defined at update
			def faa																			# -- no other version of k in hierarchy
				'faaxx'
			end
		}
    C.injectors.sym_list.should == [:j, :k]
    C.new.injectors.sym_list.should == [:j, :k]
    D.injectors.sym_list.should == [:j]
    D.new.injectors.sym_list.should == [:j]
	
		# New Objects
    C.new.faa.should == 'faaxx'										# new version of #faa
    D.new.faa.should == 'faaxx'
		# still the same
    C.new.foo.should == 'foo'
    D.new.foo.should == 'fuu'
		# Existing Objects
    c.foo.should == 'foo'
    c.faa.should == 'faaxx'
    d.foo.should == 'fuu'
    d.faa.should == 'faaxx'
	
	
    # E inherits from D

    class E < D																		# methods are inherited from j at C, D and k update at C
    end
    C.injectors.sym_list.should == [:j, :k]
    C.new.injectors.sym_list.should == [:j, :k]
    D.injectors.sym_list.should == [:j]
    D.new.injectors.sym_list.should == [:j]
    E.injectors.sym_list.should == []
    E.new.injectors.sym_list.should == []

		# New Objects
    C.new.foo.should == 'foo'
    C.new.faa.should == 'faaxx'
    D.new.foo.should == 'fuu'
    D.new.faa.should == 'faaxx'                   # new objects pass
    E.new.foo.should == 'fuu'
    E.new.faa.should == 'faaxx'
		# Existing Objects
    e = E.new
    c.foo.should == 'foo'
    c.faa.should == 'faaxx'                       # existing objects pass
    d.foo.should == 'fuu'
    d.faa.should == 'faaxx'
	
	
		# E overrides D
		
    class E < D
      def foo																			# overrides #foo from j at C, D
        'fuuuu'
      end
    end
    C.injectors.sym_list.should == [:j, :k]
    C.new.injectors.sym_list.should == [:j, :k]
    D.injectors.sym_list.should == [:j]
    D.new.injectors.sym_list.should == [:j]
    E.injectors.sym_list.should == []
    E.new.injectors.sym_list.should == []

		# New Objects
    C.new.foo.should == 'foo'
    C.new.faa.should == 'faaxx'
    D.new.foo.should == 'fuu'
    D.new.faa.should == 'faaxx'
    E.new.foo.should == 'fuuuu'
    E.new.faa.should == 'faaxx'
		# Existing Objects
    c.foo.should == 'foo'
    c.faa.should == 'faaxx'
    d.foo.should == 'fuu'
    d.faa.should == 'faaxx'
    e.foo.should == 'fuuuu'
    e.faa.should == 'faaxx'
	
	
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
    expect{ C.new.foo.should == 'foo'}.to raise_error(NoMethodError)  # #foo errors out on C
    C.new.faa.should == 'faaxx'
    D.new.foo.should == 'fuu' 
    D.new.faa.should == 'faaxx'                   # all else is the same...
    E.new.foo.should == 'fuuuu' 
    E.new.faa.should == 'faaxx'
    # Existing Objects
    expect{c.foo.should == 'foo'}.to raise_error(NoMethodError)
    c.faa.should == 'faaxx'
    d.foo.should == 'fuu'
    d.faa.should == 'faaxx'
    e.foo.should == 'fuuuu'
    e.faa.should == 'faaxx'
    
	
    C.eject :k                                    # eject the only k
    
    C.new.injectors.sym_list.should == []
    C.injectors.sym_list.should == []
    D.new.injectors.sym_list.should == [:j]
    D.injectors.sym_list.should == [:j]
    E.new.injectors.sym_list.should == []
    E.injectors.sym_list.should == []

		# New Objects
    expect{ C.new.foo.should == 'foo'}.to raise_error(NoMethodError) 
    expect{ C.new.faa.should == 'faaxx'}.to raise_error(NoMethodError) # # faa errors out
    D.new.foo.should == 'fuu' 										
    expect{ D.new.faa.should == 'faaxx'}.to raise_error(NoMethodError) #faa errors out 
    E.new.foo.should == 'fuuuu' 
    expect{ E.new.faa.should == 'faaxx'}.to raise_error(NoMethodError) #faa was only available thru k at C 
    # Existing Objects
    expect{c.foo.should == 'foo'}.to raise_error(NoMethodError)
    expect{c.faa.should == 'faaxx'}.to raise_error(NoMethodError)
    d.foo.should == 'fuu'													# same thing for pre-existing objects
    expect{d.faa.should == 'faaxx'}.to raise_error(NoMethodError)
    e.foo.should == 'fuuuu'
    expect{e.faa.should == 'faaxx'}.to raise_error(NoMethodError)
    
	
    D.eject :j                                    # eject j from D: the only one remaining
    																							# -- everything should revert back to class level
    C.injectors.sym_list.should == []
    C.new.injectors.sym_list.should == []
    D.injectors.sym_list.should == []
    D.new.injectors.sym_list.should == []
    E.injectors.sym_list.should == []
    E.new.injectors.sym_list.should == []
		# New Objects
    expect{ C.new.foo.should == 'foo'}.to raise_error(NoMethodError) # no actual #foo on class 
    expect{ C.new.faa.should == 'faaxx'}.to raise_error(NoMethodError) #         ''
    D.new.foo.should == 'fuu' 										# retains overrides from D
    expect{ D.new.faa.should == 'faaxx'}.to raise_error(NoMethodError) 
    E.new.foo.should == 'fuuuu' 									# retains overrides from E
    expect{ E.new.faa.should == 'faaxx'}.to raise_error(NoMethodError) 
    # Existing Objects
    expect{c.foo.should == 'foo'}.to raise_error(NoMethodError)
    expect{c.faa.should == 'faaxx'}.to raise_error(NoMethodError)
    d.foo.should == 'fuu'													# same for pre-existing objects
    expect{d.faa.should == 'faaxx'}.to raise_error(NoMethodError)
    e.foo.should == 'fuuuu'												
    expect{e.faa.should == 'faaxx'}.to raise_error(NoMethodError)

  end

end

describe "some special cases and circumstances" do

	it 'passes on this case when we apply a <blank> Injector and then define the methods on it' do

		class C1
		end

		# Define a Blank Injector

		injector :multi_levelA

		C1.inject multi_levelA												# apply blank injector


		# Define function after the application

		multi_levelA do 
			def m1
				'm1'
			end
		end


		# C1 calls

		C1.new.m1.should == 'm1'										# call 


		# D1 inherits from C1

		class D1 < C1
		end
		D1.new.m1.should == 'm1'										# inherited call 


		# E1 inherits from D1

		class E1 < D1
		end
		E1.new.m1.should == 'm1'										# inherited call


		# Re-define Method Cache
		# -- previously un-applied methods

		multi_levelA do 															
			def m1
				'm1xx'                                   
			end
		end                 
		
		
		# Calls are also re-defined
		                    
		C1.new.m1.should == 'm1xx'                  # call is redefined
		D1.new.m1.should == 'm1xx'                  #      '' 
		E1.new.m1.should == 'm1xx'                  #      ''


		# Apply the <full> Injector onto E1

		E1.inject multi_levelA                        # Attaches this version only onto E1
		
		# calls

		C1.new.m1.should == 'm1xx'                  # =>  from cache
		D1.new.m1.should == 'm1xx'                  #    ''
		
		E1.new.m1.should == 'm1xx'                  # =>  from applied version
		
		
		# Re-define cached injector methods
		
		multi_levelA do
			def m1
				'-----'
			end
		end
				                  

		# calls

		C1.new.m1.should == '-----'									# re-defined!!                  
		D1.new.m1.should == '-----'                  #      ''
		
		E1.new.m1.should == 'm1xx'                  # NOT REDEFINED!!
																									# -- attached with version
		
	end

	it 'also passes on this case' do

		class C2
		end

		# Define a blanck Injector
		
		injector :multi_levelB
    

		# Fill-in  function as you apply
		
		C2.inject multi_levelB	do 										# apply definitions
			def m1                                     
				'm1'                                     
			end                                         
		end                                           
		C2.new.m1.should == 'm1'										# call on Injector


		# DD inherits from CC                         

		class D2 < C2                                 
		end                                           # call on Injector
		D2.new.m1.should == 'm1'										


		# EE inherits from DD                         

		class E2 < D2                                 
		end                                           # call on Injector
		E2.new.m1.should == 'm1'										

    
		# Re-define methods
		
		multi_levelB do 															# NEW VERSION! because previous had an application
			def m1                                     # -- was applied to C2 in the hierarchy
				'm1xx'                                   
			end
		end                                          

		# Calls un-affected  !!                       # have existing version

		C2.new.m1.should == 'm1'
		D2.new.m1.should == 'm1'
		E2.new.m1.should == 'm1'

		E2.inject multi_levelB                      	# apply to hierarchy on E

		C2.new.m1.should == 'm1'                  	# same
		D2.new.m1.should == 'm1'                  	# same
		E2.new.m1.should == 'm1xx'                	# changed

	end

	it 'also passes on this case' do
                   
		class C3
		end                                         

		# Define a blank Injector
		
		injector :multi_levelC

    
		# Apply <full> Injector definition to an ancestor
		
		Object.inject multi_levelC do
			def m1
				'm1xx'
			end
		end
    

		# Call on the Injector
		
		C3.new.m1.should == 'm1xx'                	# call Injector


		# Re-define a new Injector version

		multi_levelC do 															
			def m1
				'm1'
			end
		end
		
		# Calls un-afffected 
		
		C3.new.m1.should == 'm1xx'									# still using the previous version --no changes
        
		
		# Inherit
		
		class D3 < C3
		end
		D3.new.m1.should == 'm1xx'									# using previous version
    

		# Inherit
		
		class E3 < D3
		end
		E3.new.m1.should == 'm1xx'									# using previous version
             
    
    # Finally apply new version

		C3.inject multi_levelC												
		
		
		# Calls changed from C on up
		
		C3.new.m1.should == 'm1'
		D3.new.m1.should == 'm1'
		E3.new.m1.should == 'm1'										# new version of #m1

    
		# Call on ancestor the same
		
		Object.new.m1.should == 'm1xx'							# previous version

	end

	it 'carries current methods onto sub-versions' do

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
        

		jack :speakers

		Bass = speakers do                   
			def sound                               
				super + '...boom boom boom...'        
			end                                     
		end                                       
		JukeBox.inject Bass
		
		#...                       

		JukeBox.new.on.should == 'CD playing...Lets make some music...boom boom boom...'

	end

	it 'works accross compound injectors' do

		jack :S1

		S1 do
			include jack :s2 do
				def s2m1
				end
				include jack :s3 do
					def s3m1
					end
					include jack :s4 do
						def s4m1
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
		
		
		# Call on the Injectors
		
		CompoundContainer.new.s2m1
		CompoundContainer.new.s3m1
		CompoundContainer.new.s4m1

		
		# Add methods to the method cache of s3
		
		S1().s2.s3 do
			def s3m2
			end
		end
		CompoundContainer.new.s3m2                  
                         

		# Create a version Tag
		
		AccessTag = S1() 
		
		
		# Apply the Tag
		
		class SecondContainer
			include AccessTag
		end
		
		
		# Call on tag methods
		
		SecondContainer.new.s3m2
       
    
		# Add methdos to the s2 method cache
		
		S1().s2 do
			def s2m2
			end
		end
		
		
		# The current cache is available to all containers
		
		CompoundContainer.new.s2m2
		SecondContainer.new.s2m2

	end

	it 'pases' do

	 	injector :M1
	 	injector :M2
	 	injector :M3
		
		class AA1
		end
		M1 do
			include M2()
		end
		M2 do
			def mM2
			end
		end
		M1 do
			def mM1
			end
		end
		class AA1
			include M1()
		end
		AA1.new.mM2

	end 

	it 'passes' do

		injector :J1
		injector :J2
		injector :J3

		J1 do
		  include J2() do
		    def mj2
		    end
		  end
		end
		class AA2
		  include J1()
		end
		AA2.new.mj2
		J2 do
		  include J3() do
		    def mj3
		    end
		  end
		end
		AA2.new.mj3

	end

	it 'also passes' do

		injector :K1
		injector :K2
		injector :K3

		K1 do
			include K2() do
				def mk2
				end
			end
		end
		class AA3
			include K1()
		end
		AA3.new.mk2
		K2 do
			include K3()
		end
		K3 do
			def mk3
			end
		end
		
		AA3.new.mk3

	end

end

