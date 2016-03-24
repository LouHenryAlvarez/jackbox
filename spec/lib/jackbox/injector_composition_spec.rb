require "spec_helper"
=begin rdoc
	
	This file describes full blown trait composition and decomposition.
	
	NOTE: Please note that some examples are purposefully long because of the long
	process any given trait can undergo during program use.  We are testing the 
	possible lifecycle of an trait in the course of a program.
	
=end


include Injectors

describe 'plyability of injection/ejection' do

	describe 'a new form of mixin' do
		
		before do
			
			suppress_warnings do
				A1 = Class.new
			end

			trait :j1 do
				def j1m1
					:j1m1
				end
			end
	
			A1.inject j1
	
			# define function
			j1 do
				def j1m2
					:j1m2
				end
			end 
	
		end
		
		after do
			
			j1 :implode
			
			suppress_warnings do
				A1 = nil
			end
			
		end
		
		it 'morphs mixins to a new level' do

			a1 = A1.new
	
			# instance has traits of class
			a1.traits.sym_list.should == [:j1]
	
			a1.j1m1.should == :j1m1 # no errors on call
			a1.j1m2.should == :j1m2 # no errors on call
	
			# eject the class trait for this object only
			a1.eject j1
	
			a1.traits.sym_list.should == []
			A1.traits.sym_list.should == [:j1]
	
			# expect errors on object
			expect{ a1.j1m1 }.to raise_error(NoMethodError)
			expect{ a1.j1m2 }.to raise_error(NoMethodError)
	
			# class#new still the same
			A1.new.j1m1.should == :j1m1 # no errors
			A1.new.j1m2.should == :j1m2 # no errors
			
		end
		
		it 'all fails after class ejection' do
	                   
			a1 = A1.new

			# eject function from the entire class
			A1.eject j1
			
			A1.traits.sym_list.should == []
	
			# expect all these errors
			expect{ a1.j1m1 }.to raise_error(NoMethodError)
			expect{ a1.j1m2 }.to raise_error(NoMethodError)
			expect{ A1.new.j1m1 }.to raise_error(NoMethodError)
			expect{ A1.new.j1m2 }.to raise_error(NoMethodError)
			expect{ A1.eject j1 }.to raise_error(ArgumentError) # no more traits
	    
		end
		
		it 'regains function on individula object through enrichment' do
			
			a1 = A1.new

			# eject function from the entire class
			A1.eject j1
			
			A1.traits.sym_list.should == []   				# like above
		    
			# enrich the individual object
			a1.enrich j1
			A1.traits.sym_list.should == [] # still
			a1.traits.sym_list.should == [:j1]
	
			# regain object function
			a1.j1m1.should == :j1m1 # no errors
			a1.j1m2.should == :j1m2 # no errors
	
			# class#new still errors
			expect{ A1.new.j1m1 }.to raise_error(NoMethodError)
			expect{ A1.new.j1m2 }.to raise_error(NoMethodError)
			
		end
		
		it 'fails again on individual object ejection' do 
	
			a1 = A1.new

			# eject function from the entire class
			A1.eject j1
			
			A1.traits.sym_list.should == []   				# like above
	
			# enrich the individual object
			a1.enrich j1

			a1.traits.sym_list.should == [:j1]       # like above

			# eject back out
			a1.eject j1                           
			
			a1.traits.sym_list.should == []
			A1.traits.sym_list.should == [] # still
	
			# expect all errors
			expect{ a1.j1m1 }.to raise_error(NoMethodError)
			expect{ a1.j1m2 }.to raise_error(NoMethodError)
			expect{ A1.new.j1m1 }.to raise_error(NoMethodError)
			expect{ A1.new.j1m2 }.to raise_error(NoMethodError)
			expect{ a1.eject j1 }.to raise_error(ArgumentError) # no more traits
			
		end
		
		it 'regains all function on class injection' do
	
			a1 = A1.new

			# eject function from the entire class
			A1.eject j1
			
			A1.traits.sym_list.should == []   				# like above
	
			# enrich the individual object
			a1.enrich j1

			a1.traits.sym_list.should == [:j1]       # like above

			# eject back out
			a1.eject j1                           			
			
			a1.traits.sym_list.should == []          # like above 
			
			# re-inject the entire class
			A1.inject j1         
			
			A1.traits.sym_list.should == [:j1]
			a1.traits.sym_list.should == [:j1]
	
			# no errors
			a1.j1m1.should == :j1m1
			a1.j1m2.should == :j1m2
			A1.new.j1m1.should == :j1m1 # no errors
			A1.new.j1m2.should == :j1m2 # no errors
			
		end
		
		it 'fails on class injection if the premise of class ejection is not met' do
	
			a1 = A1.new

			# eject class trait from just this object again
			a1.eject j1                                  
			
			A1.traits.sym_list.should == [:j1]       # like above
			a1.traits.sym_list.should == []
	              
			# expect errors fo object
			expect{ a1.j1m1 }.to raise_error(NoMethodError)
			expect{ a1.j1m2 }.to raise_error(NoMethodError)
			expect{ a1.eject j1 }.to raise_error(ArgumentError)
			
			# no errors for new objects of the class    # no class ejection at any point
			A1.new.j1m1.should == :j1m1 # no errors
			A1.new.j1m2.should == :j1m2 # no errors
	
			# re-inject once again
			A1.inject j1                          			# this re-injection does not take effect

			A1.traits.sym_list.should == [:j1] 
			a1.traits.sym_list.should == [] # still ejected at object
	
			# expect errors
			expect{ a1.j1m1 }.to raise_error(NoMethodError)
			expect{ a1.j1m2 }.to raise_error(NoMethodError)
			expect{ a1.eject j1 }.to raise_error(ArgumentError)
	
			# class update
			A1.send :update, j1   											# only Class #update OVERRIDES OBJECT-LEVEL EJECTIONS!!
			A1.traits.sym_list.should == [:j1]       # (or object level injection) like above
			a1.traits.sym_list.should == [:j1]
	
			# working once again  
			a1.j1m1.should == :j1m1
			a1.j1m2.should == :j1m2
	
		end
		
	end

	describe "some special cases" do

		before do
			
			suppress_warnings do
				A2 = Class.new
			end

			trait :j2 do
				def meth
					:meth
				end
			end
			trait :j3 do
				def meth
					:method
				end
			end

			A2.inject j2, j3

		end
		
		after do
			
			suppress_warnings do
				A2 = nil
			end
			j2 :implode
			j3 :implode
			
		end
		
		it 'does cover this case' do

			# same name methods on different entities

			a2 = A2.new          

			A2.traits.sym_list.should == [:j2, :j3]
			a2.traits.sym_list.should == [:j2, :j3]

			a2.meth.should == :meth

			A2.eject j2
			
			a2.meth.should == :method

			A2.inject j2
			
			a2.meth.should == :meth

			A2.eject j3
			
			a2.meth.should == :meth

			A2.eject j2

			expect{a2.meth}.to raise_error(NoMethodError)
			expect{A2.eject j2}.to raise_error(ArgumentError)

		end

		it 'also covers this case' do

 		# the same thing but ejected at the object level

			a3 = A2.new

			a3.meth.should == :meth

			a3.eject j2
			a3.meth.should == :method

			A2.inject j2																# no Class #update NO CHANGE
			a3.meth.should == :method

			a3.enrich j2
			a3.meth.should == :meth

			a3.eject j2
			a3.meth.should == :method

			A2.send :update, j2 
			
			a3.traits.sym_list.should == [:j2, :j3]  # gets inverted
			a3.meth.should == :meth

			a3.eject j2

			a3.meth.should == :method
			expect{a3.eject j2}.to raise_error(ArgumentError)

			a3.eject j3

			a3. traits.should == []
			expect{a3.meth}.to raise_error(NoMethodError)
			
		end  
	end

	it 'errors out when no more traits to eject' do

		Ejected = trait :ejected

		class EjectionTester
			inject Ejected
		end

		x = EjectionTester.new
		x.traits.sym_list.should == [:ejected]

		x.extend ejected
		x.traits.sym_list.should == [:ejected, :ejected]

		x.eject ejected
		x.traits.sym_list.should == [:ejected]
		x.eject ejected
		x.traits.sym_list.should == []

		# debugger
		expect{
			x.eject ejected
		}.to raise_error(ArgumentError)

		EjectionTester.traits.sym_list.should == [:ejected]
		EjectionTester.eject Ejected
		EjectionTester.traits.sym_list.should == []

		expect{
			EjectionTester.eject Ejected
		}.to raise_error(ArgumentError)

	end

end



# 
# declare traits
# 
trait :FuelSystem
trait :Engines
trait :Capsule
trait :Landing


# 
# compose the object
# 
class SpaceShip
	
	inject FuelSystem(), Engines(), Capsule(), Landing()

	def launch
		# debugger
		gas_tank fuel_lines burners ignition :go
		self
	end
end


describe 'multiple trait composition and decomposition' do

	# define functionality
	FuelSystem do
		def gas_tank arg
			:gas
		end

		def fuel_lines arg
			:fuel
		end

		def burners arg
			:metal
		end
	end

	# further define function
	Engines do
		def ignition arg
			:spark
		end
	end

	# create object
	sat = SpaceShip.new.launch
	# sat = subject.new.launch

	 # in flight definitions, ha ha!!
	Capsule do
		def o2
			:oxigen
		end
		def hydration
			:water
		end
	end

	# more inflight definitions
	var = 'wheels'
	Landing do
		define_method :gear do
			var
		end
	end

	the 'domain is specified as follows' do

		#####
		# 0. Nornal operation
		SpaceShip.traits.sym_list.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.traits.sym_list.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.fuel_lines( :on ).should == :fuel
		sat.ignition( :on ).should == :spark
		sat.o2.should == :oxigen
		sat.gear.should == 'wheels'

		#####
		# 1. eject class level trait at the object level
		sat.eject :Capsule

		# expect errors
		SpaceShip.traits.sym_list.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.traits.sym_list.should == [:FuelSystem, :Engines, :Landing]
		expect{sat.o2}.to raise_error(NoMethodError)
		sat.fuel_lines( :good ).should == :fuel
		sat.ignition( :on ).should == :spark
		sat.gear.should == 'wheels'

		#####
		# 2. eject 2nd class level trait at the object level
		sat.eject :Engines

		# expect more errors
		SpaceShip.traits.sym_list.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.traits.sym_list.should == [:FuelSystem, :Landing]
		expect{sat.o2}.to raise_error(NoMethodError)
		expect{sat.ignition :on}.to raise_error(NoMethodError)
		sat.fuel_lines( :good ).should == :fuel
		sat.gear.should == 'wheels'

		#####
		# 3. launch a second vessel
		flyer = SpaceShip.new.launch

		# should have normal config
		SpaceShip.traits.sym_list.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.traits.sym_list.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.fuel_lines( :on ).should == :fuel
		flyer.ignition( :on ).should == :spark
		flyer.o2.should == :oxigen
		
		# sat is still cripled 
		sat.traits.sym_list.should == [:FuelSystem, :Landing]
		sat.fuel_lines( :good ).should == :fuel
		expect{sat.ignition :on}.to raise_error(NoMethodError)
		expect{sat.o2}.to raise_error(NoMethodError)
		sat.gear.should == 'wheels'

		#####
		# 4. re-inject sat with Capsule
		sat.enrich Capsule() # object level re-injection

		# sat regains some function
		SpaceShip.traits.sym_list.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.traits.sym_list.should == [:Capsule, :FuelSystem, :Landing]
		sat.o2.should == :oxigen
		sat.fuel_lines( :good ).should == :fuel
		sat.gear.should == 'wheels'
		
		# sat ignition still failing
		expect{sat.ignition :on}.to raise_error(NoMethodError)
		
		# flyer normal
		flyer.traits.sym_list.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.ignition( :on ).should == :spark
		flyer.fuel_lines( :on ).should == :fuel
		flyer.o2.should == :oxigen
		flyer.gear.should == 'wheels'

		#####
		# 5. Class Level ejection: from Ground control
		SpaceShip.eject :Capsule  
		SpaceShip.traits.sym_list.should == [:FuelSystem, :Engines, :Landing]

		# class level ejection: affects objects of the class 
		# that have not been re-injected at the object level
		
		# flyer is now affected 
		flyer.traits.sym_list.should == [:FuelSystem, :Engines, :Landing]
		expect{flyer.o2}.to raise_error(NoMethodError)
		flyer.ignition( :on ).should == :spark
		flyer.fuel_lines( :on ).should == :fuel
		flyer.gear.should == 'wheels'

		# sat not affected because previously enriched at the object level
		sat.traits.sym_list.should == [:Capsule, :FuelSystem, :Landing]
		sat.o2.should == :oxigen
		sat.fuel_lines( :good ).should == :fuel
		sat.gear.should == 'wheels'
		expect{sat.ignition :on}.to raise_error(NoMethodError)
		
		#####
		# 6. 2nd Class Level ejection from Ground Control
		SpaceShip.eject :FuelSystem	
		SpaceShip.traits.sym_list.should == [:Engines, :Landing]

		# sat affected
		sat.traits.sym_list.should == [:Capsule, :Landing]
		expect{sat.ignition :on}.to raise_error(NoMethodError)
		expect{sat.fuel_lines :off}.to raise_error(NoMethodError)
		sat.o2.should == :oxigen
		sat.gear.should == 'wheels'

		# flyer affected
		flyer.traits.sym_list.should == [:Engines, :Landing]
		expect{flyer.fuel_lines :on}.to raise_error(NoMethodError)
		expect{flyer.o2}.to raise_error(NoMethodError)
		flyer.ignition( :on ).should == :spark
		flyer.gear.should == 'wheels'

		#####
		# 7. 2nd vessel gets aided by aliens
		flyer.enrich FuelSystem()	# object level re-injection 

		# regains some function
		SpaceShip.traits.sym_list.should == [:Engines, :Landing]
		flyer.traits.sym_list.should == [:FuelSystem, :Engines, :Landing]
		flyer.fuel_lines( :on ).should == :fuel
		flyer.ignition( :on ).should == :spark
		flyer.gear.should == 'wheels'
		
		# o2 still failing
		expect{flyer.o2}.to raise_error(NoMethodError)
		
		# first vessel still same failures
		sat.traits.sym_list.should == [:Capsule, :Landing]
		expect{sat.ignition :on}.to raise_error(NoMethodError)
		expect{sat.fuel_lines :on}.to raise_error(NoMethodError)
		sat.o2.should == :oxigen
		sat.gear.should == 'wheels'

		#####
		# 8. flyer vessel gets aided by aliens a second time
		flyer.enrich Capsule()	# object level re-injection

		# regains all function
		SpaceShip.traits.sym_list.should == [:Engines, :Landing]
		flyer.traits.sym_list.should == [:Capsule, :FuelSystem, :Engines, :Landing]
		flyer.fuel_lines( :on ).should == :fuel
		flyer.ignition( :on ).should == :spark
		flyer.o2.should == :oxigen
		flyer.gear.should == 'wheels'

		# sat vessel still same failures
		sat.traits.sym_list.should == [:Capsule, :Landing]
		expect{sat.ignition :on}.to raise_error(NoMethodError)
		expect{sat.fuel_lines :on}.to raise_error(NoMethodError)
		sat.o2.should == :oxigen
		sat.gear.should == 'wheels'

		#####
		# 9. sat vessel looses capsule
		sat.eject :Capsule	# object level ejection

		# flyer vessel un-affected
		SpaceShip.traits.sym_list.should == [:Engines, :Landing]
		sat.traits.sym_list.should == [:Landing]
		flyer.traits.sym_list.should == [:Capsule, :FuelSystem, :Engines, :Landing]
		flyer.fuel_lines( :on ).should == :fuel
		flyer.ignition( :on ).should == :spark
		flyer.o2.should == :oxigen
		flyer.gear.should == 'wheels'
		
		# sat vessel can only land
		expect{sat.fuel_lines :on}.to raise_error(NoMethodError)
		expect{sat.ignition :on}.to raise_error(NoMethodError)
		expect{sat.o2}.to raise_error(NoMethodError)
		sat.gear.should == 'wheels'

		#####
		# 10. Class Level injection from Ground Control
		SpaceShip.inject FuelSystem()	
		SpaceShip.traits.sym_list.should == [:FuelSystem, :Engines, :Landing]
		
		# class level re-injection: affects all objects
		# even if they have been re-injected at the object level 

		# sat vessel regains some function
		sat.traits.sym_list.should == [:FuelSystem, :Landing]
		sat.fuel_lines( :on ).should == :fuel
		sat.gear.should == 'wheels'
		
		# but still errors 
		expect{sat.ignition :off}.to raise_error(NoMethodError)
		expect{sat.hydration}.to raise_error(NoMethodError)
		
		# flyer vessel gains a backup!
		flyer.traits.sym_list.should == [:Capsule, :FuelSystem, :FuelSystem, :Engines, :Landing]
		flyer.ignition( :on ).should == :spark
		flyer.gas_tank( :full ).should == :gas
		flyer.hydration.should == :water
		flyer.gear.should == 'wheels'
		
		#####
		# Injector directives
		FuelSystem(:collapse)
		SpaceShip.traits.sym_list.should == [:FuelSystem, :Engines, :Landing]

		# First vessel: fuel system is inoperative, everything else the same
		sat.traits.sym_list.should == [:FuelSystem, :Landing]
		sat.fuel_lines( :on ).should == nil
		expect{sat.ignition :off}.to raise_error(NoMethodError)
		expect{sat.hydration}.to raise_error(NoMethodError)
		sat.gear.should == 'wheels'

		# Second vessel: fuel system also inoperative, the rest same
		flyer.traits.sym_list.should == [:Capsule, :FuelSystem, :FuelSystem, :Engines, :Landing]
		flyer.gas_tank(:full).should == nil		
		flyer.ignition( :on )
		flyer.hydration.should == :water
		flyer.gear.should == 'wheels'

		#####
		# second directive 
		FuelSystem(:rebuild)
		SpaceShip.traits.sym_list.should == [:FuelSystem, :Engines, :Landing]
		
		# everything back to previous state
		sat.traits.sym_list.should == [:FuelSystem, :Landing]
		sat.fuel_lines( :on ).should == :fuel
		sat.gear.should == 'wheels'
		expect{sat.ignition :off}.to raise_error(NoMethodError)
		expect{sat.hydration}.to raise_error(NoMethodError)
		flyer.traits.sym_list.should == [:Capsule, :FuelSystem, :FuelSystem, :Engines, :Landing]
		flyer.gas_tank(:full).should == :gas		
		flyer.ignition( :on ).should == :spark
		flyer.hydration.should == :water
		flyer.gear.should == 'wheels'
		
	end
	
	it 'co-exists with method_missing on classes/modules' do

		# writing method_missing in conjunction with trait use
		class SpaceShip
			def method_missing sym, *args, &code								# done on the class
				if sym == :crash
					:booohoooo
					# ... do your stuff here
				else
					super(sym, *args, &code) 											
				end
			end
		end

		SpaceShip.traits.sym_list.should == [:FuelSystem, :Engines, :Landing]
		sat.traits.sym_list.should == [:FuelSystem, :Landing]
		
		sat.crash.should == :booohoooo
		sat.fuel_lines( :on ).should == :fuel
		expect{sat.ignition :off}.to raise_error(NoMethodError)
		expect{sat.hydration}.to raise_error(NoMethodError)
		sat.gear.should == 'wheels'
		
		
		module CrashAndBurn
			def method_missing sym, *args, &code								# done on a separate module
				if sym == :crash_and_burn
					"look ma' no teeth"
				else 
					super(sym, *args, &code)
				end
			end
		end

		class SpaceShip
			include CrashAndBurn
		end

		# debugger
		sat.crash_and_burn.should == "look ma' no teeth"

		#####
		# Done on the trait
		# . cannot be done at the trait level
		trait :Pilot do 																		
			def automatic
				'auto pilot'
			end
			def method_missing sym, *args, &code 	
				'Going dauwn...'
			end
		end
		
		# object level enrich
		sat.enrich Pilot()	
		sat.enrich Engines()
		
		SpaceShip.traits.sym_list.should == [:FuelSystem, :Engines, :Landing]
		sat.traits.sym_list.should == [:Engines, :Pilot, :FuelSystem, :Landing]
		
		sat.automatic.should == 'auto pilot'									
		sat.noMethod.should == 'Going dauwn...' 
		sat.fuel_lines( :on ).should == :fuel
		expect{sat.ignition( :off )}.to_not raise_error()
		sat.ignition( :on ).should == :spark
		expect{sat.hydration}.to_not raise_error()
		sat.hydration.should == 'Going dauwn...'
		sat.gear.should == 'wheels'
		
		# class level injection
		SpaceShip.inject Pilot()	

		SpaceShip.traits.sym_list.should == [:Pilot, :FuelSystem, :Engines, :Landing]
		sat.traits.sym_list.should == [:Engines, :Pilot, :Pilot, :FuelSystem, :Landing]
		
		sat.automatic.should == 'auto pilot'
		sat.noMethod.should == 'Going dauwn...' 
		sat.fuel_lines( :on ).should == :fuel
		expect{sat.ignition :off}.to_not raise_error()
		sat.ignition( :on ).should == :spark
		expect{sat.hydration}.to_not raise_error()
		sat.hydration.should == 'Going dauwn...'
		sat.gear.should == 'wheels'
		
		#####
		# Un-affected by directives
		Pilot(:silence)
		
		SpaceShip.traits.sym_list.should == [:Pilot, :FuelSystem, :Engines, :Landing]
		sat.traits.sym_list.should == [:Engines, :Pilot, :Pilot, :FuelSystem, :Landing]
		
		sat.automatic.should == nil
		sat.fuel_lines( :on ).should == :fuel
		expect{sat.ignition :off}.to_not raise_error()
		sat.ignition( :on ).should == :spark
		expect{sat.hydration}.to_not raise_error()
		sat.hydration.should == 'Going dauwn...'
		sat.gear.should == 'wheels'

		expect{sat.boohoo}.to_not raise_error()
		sat.boohoo.should == 'Going dauwn...'
		
		#####
		# Un-affected by directives
		Pilot(:rebuild)
		
		SpaceShip.traits.sym_list.should == [:Pilot, :FuelSystem, :Engines, :Landing]
		sat.traits.sym_list.should == [:Engines, :Pilot, :Pilot, :FuelSystem, :Landing]
		
		sat.automatic.should == 'auto pilot'
		sat.fuel_lines( :on ).should == :fuel
		expect{sat.ignition :off}.to_not raise_error()
		sat.ignition( :on ).should == :spark
		expect{sat.hydration}.to_not raise_error()
		sat.hydration.should == 'Going dauwn...'
		sat.gear.should == 'wheels'

		expect{sat.boohoo}.to_not raise_error()
		sat.boohoo.should == 'Going dauwn...'
		
	end
	
	describe 'trait order resolution' do
		
		it 'allows the following' do
			
			trait :a, :b, :c
			
			x = a b,c
			y = a c,b
			
			x.should == a
			y.should == a
			x.ancestors.map(&:name).should == [:a, :b, :c]
			y.ancestors.map(&:name).should == [:a, :c, :b]
			x.traits.by_name.should == [:b, :c]
			y.traits.by_name.should == [:c, :b]
			a.ancestors.map(&:name).should == [:a]
			b.ancestors.map(&:name).should == [:b]
			c.ancestors.map(&:name).should == [:c]
			
		end
		
		it "also allows the following" do
			
			trait :a, :b, :c
			
			x = a b c
			y = a c b
			
			x.should == a
			y.should == a
			x.ancestors.map(&:name).should == [:a, :b, :c]
			y.ancestors.map(&:name).should == [:a, :c, :b]
			x.traits.by_name.should == [:b]
			y.traits.by_name.should == [:c]
			x.traits.first.traits.by_name.should == [:c]
			y.traits.first.traits.by_name.should == [:b]
			a.ancestors.map(&:name).should == [:a]
			b.ancestors.map(&:name).should == [:b]
			c.ancestors.map(&:name).should == [:c]
			
		end
	end

	describe "composition with other tagged traits" do
		before do
			trait :a, :b, :c
		
			suppress_warnings do
				A1 = a do
					def m
						1
					end
				end
			
				B1 = b do
					def n
						2
					end
				end
			
				CC = c do
					def o
						3
					end
				end
				
				# debugger
				A2 = a b c do
					def m
						super * 6
					end
				end
			
				B2 = b a c do
					def m
						super - 1
					end
					def n
						super + 2
					end
				end
			end
			
		end
		
		after do
			suppress_warnings do
				A1, A2, B1, B2, CC = nil, nil, nil, nil, nil
			end
			with a, b, c do
				send :implode
			end
		end
		
		it "allows composition and inheritance" do
			
			p = Object.new.extend A2
			q = Object.new.extend B2
			
			p.m.should == 6
			p.n.should == 2
			p.o.should == 3
			
			q.m.should == 5
			q.n.should == 4
			q.o.should == 3
			
		end
		
		it 'encompasses ancestors as follows' do
			
			A1.ancestors.map(&:name).should == [:a]
			B1.ancestors.map(&:name).should == [:b]
			A2.traits(:all).by_name.should == [:a, :b, :c]
			B2.traits(:all).by_name.should == [:b, :a, :c]
			A2.ancestors.map(&:name).should == [:a, :b, :c]
			B2.ancestors.map(&:name).should == [:b, :a, :c]
			
		end
	end
	
	describe "composition with tags" do
		before do
			trait :a, :b, :c
		
			suppress_warnings do
				A1 = a do
					def m
						1
					end
				end
			
				B1 = b do
					def n
						2
					end
				end
			
				CC = c do
					def o
						3
					end
				end
			
				A2 = a B1, CC do
					def m
						super * 6
					end
				end
			
				B2 = b A1, CC do
					def m
						super - 1
					end
					def n
						super + 2
					end
				end
			end
			
		end
		
		after do
			suppress_warnings do
				A1, A2, B1, B2, CC = nil, nil, nil, nil, nil, nil
			end
		end
		
		it "allows composition and inheritance" do
			
			p = Object.new.extend A2
			q = Object.new.extend B2
			
			p.m.should == 6
			p.n.should == 2
			p.o.should == 3
			
			q.m.should == 0
			q.n.should == 4
			q.o.should == 3
			
		end
		
		it 'encompasses ancestors as follows' do
			
			A1.ancestors.map(&:name).should == [:a]
			B1.ancestors.map(&:name).should == [:b]
			A2.traits(:all).by_name.should == [:a, :b, :c]
			B2.traits(:all).by_name.should == [:b, :a, :c]
			A2.ancestors.map(&:name).should == [:a, :b, :c]
			B2.ancestors.map(&:name).should == [:b, :a, :c]
			
		end
	end
	
	describe 'standard inclusion/extension aspects' do
		
		it 'works with included/extended callbacks' do

			$stdout.should_receive(:puts).with('++++++++--------------++++++++++').twice()

			SS = trait :StarShipFunction do

				def phaser
					'_+_+_+_+_+_+'
				end

				def neutron_torpedoes
					'---ooooOOOO()()()'
				end

				def self.included host
					puts '++++++++--------------++++++++++'
					host.class_eval { 
						def warp_speed
						end
					}
				end

				def self.extended host
					puts '++++++++--------------++++++++++'
					host.instance_eval {  
						def link_to_ships
							'8...................8'
						end
					}

				end
			end

			class Airplane
				inject SS
			end
			expect{

				Airplane.new.warp_speed
				Airplane.new.neutron_torpedoes.should == '---ooooOOOO()()()'

			}.to_not raise_error


			class Building
				extend SS
			end
			expect{

				Building.link_to_ships.should == '8...................8'

			}.to_not raise_error

		end

		it 'does not interfere with regular module inclusion and extension' do

			expect{

				module AB
					def meth
					end
				end

				module BA
					include AB
					def mith
					end
				end

				class First
					include BA
					def moth
					end
				end

				First.new.meth
				First.new.mith
				First.new.moth

				class Second
					def math
					end
				end

				Second.new.extend(BA).mith
				Second.new.extend(BA).meth

			}.to_not raise_error

		end

		it 'raises cyclic inclusion on module self inclusion' do

			expect{
				module AC
					def foo
					end
					include self
				end
			}.to raise_error(ArgumentError)

		end

		it 'does the same for trait self inclusion' do
		
			expect{
		
				trait :Includer
		
				Includer do
					def far
					end
					inject self
				end
		
			}.to raise_error(ArgumentError)
		
		end
		
		it "does work this way however" do
			
			expect{
					
				trait :Includer
					
				Includer do
					def far
					end
					inject Includer()													# this includes a new copy of the original
				end                                         
					
			}.to_not raise_error()
		
		end

	end
end		
