require "spec_helper"
=begin rdoc
	
	This file describes full blown injector composition and decomposition.
	
	NOTE: Please note that some examples are purposefully long because of the long
	process any given injector can undergo during program use.  We are testing the 
	possible lifecycle of an injector in the course of a program.
	
=end

include Injectors
# declare injectors
injector :FuelSystem
injector :Engines
injector :Capsule
injector :Landing

# compose the object
class SpaceShip
	inject FuelSystem(), Engines(), Capsule(), Landing()

	def launch
		gas_tank fuel_lines burners ignition :go
		self
	end
end

describe 'plyability of injection/ejection' do
	
	it 'morphs mixins to a new level' do

		injector :foo
		class AA
		end

		AA.inject foo

		a = AA.new
		a.injectors.should == [:foo]

		foo do
			def faa
			end
		end
		a.faa.should == nil

		a.eject foo
		
		a.injectors.should == []
		expect{ a.faa }.to raise_error
		expect{ a.faa }.to raise_error
		AA.injectors.should == [:foo]

		AA.eject foo

		AA.injectors.should == []
		expect{ a.faa }.to raise_error
		expect{ AA.eject foo }.to raise_error
		
		a.enrich foo

		a.injectors.should == [:foo]
		a.faa.should == nil
		AA.injectors.should == []
		
		a.eject foo
		
		a.injectors.should == []
		expect{ a.eject foo }.to raise_error
		expect{ a.faa }.to raise_error
		AA.injectors.should ==[]
		
		AA.inject foo
		
		a.injectors.should == [:foo]
		a.faa.should == nil
		AA.injectors.should == [:foo]
		
		a.eject foo
		
		a.injectors.should == []
		AA.injectors.should == [:foo]
		expect{ a.faa }.to raise_error
		expect{ a.eject foo }.to raise_error
		
		AA.inject foo
		
		AA.injectors.should == [:foo]
		a.injectors.should == []
		expect{ a.faa }.to raise_error
		expect{ a.eject foo }.to raise_error
		
		AA.send :update, foo
		
		AA.injectors.should == [:foo]
		a.injectors.should == [:foo]
		a.faa.should == nil
		
	end

	it 'errors out when no more injectors to eject' do

		Ejected = injector :ejected

		class EjectionTester
			inject Ejected
		end

		x = EjectionTester.new
		x.injectors.should == [:ejected]

		x.extend Ejected
		x.injectors.should == [:ejected, :ejected]

		x.eject Ejected
		x.injectors.should == [:ejected]
		x.eject ejected
		x.injectors.should == []

		# debugger
		expect{
			x.eject Ejected
		}.to raise_error

		EjectionTester.injectors.should == [:ejected]
		EjectionTester.eject ejected
		EjectionTester.injectors.should == []

		expect{
			EjectionTester.eject Ejected
		}.to raise_error

	end

end

describe 'multiple injector composition and decomposition' do

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

	the 'composition of many injectors into an object defined above is specified as follows' do

		#####
		# 0. Nornal operation
		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.fuel_lines( :on ).should == :fuel
		sat.ignition( :on ).should == :spark
		sat.o2.should == :oxigen
		sat.gear.should == 'wheels'

		#####
		# 1. eject class level injector at the object level
		sat.eject :Capsule

		# expect errors
		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.injectors.should == [:FuelSystem, :Engines, :Landing]
		expect{sat.o2}.to raise_error
		sat.fuel_lines( :good ).should == :fuel
		sat.ignition( :on ).should == :spark
		sat.gear.should == 'wheels'

		#####
		# 2. eject 2nd class level injector at the object level
		sat.eject :Engines

		# expect more errors
		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.injectors.should == [:FuelSystem, :Landing]
		expect{sat.o2}.to raise_error
		expect{sat.ignition :on}.to raise_error
		sat.fuel_lines( :good ).should == :fuel
		sat.gear.should == 'wheels'

		#####
		# 3. launch a second vessel
		flyer = SpaceShip.new.launch

		# should have normal config
		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.fuel_lines( :on ).should == :fuel
		flyer.ignition( :on ).should == :spark
		flyer.o2.should == :oxigen
		
		# sat is still cripled 
		sat.injectors.should == [:FuelSystem, :Landing]
		sat.fuel_lines( :good ).should == :fuel
		expect{sat.ignition :on}.to raise_error
		expect{sat.o2}.to raise_error
		sat.gear.should == 'wheels'

		#####
		# 4. re-inject sat with Capsule
		sat.enrich Capsule() # object level re-injection

		# sat regains some function
		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.injectors.should == [:FuelSystem, :Landing, :Capsule]
		sat.o2.should == :oxigen
		sat.fuel_lines( :good ).should == :fuel
		sat.gear.should == 'wheels'
		
		# sat ignition still failing
		expect{sat.ignition :on}.to raise_error
		
		# flyer normal
		flyer.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.ignition( :on ).should == :spark
		flyer.fuel_lines( :on ).should == :fuel
		flyer.o2.should == :oxigen
		flyer.gear.should == 'wheels'

		#####
		# 5. Class Level ejection: from Ground control
		SpaceShip.eject :Capsule  
		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Landing]

		# class level ejection: affects objects of the class 
		# that have not been re-injected at the object level
		
		# flyer is now affected 
		flyer.injectors.should == [:FuelSystem, :Engines, :Landing]
		expect{flyer.o2}.to raise_error
		flyer.ignition( :on ).should == :spark
		flyer.fuel_lines( :on ).should == :fuel
		flyer.gear.should == 'wheels'

		# sat not affected because previously enriched at the object level
		sat.injectors.should == [:FuelSystem, :Landing, :Capsule]
		sat.o2.should == :oxigen
		sat.fuel_lines( :good ).should == :fuel
		sat.gear.should == 'wheels'
		expect{sat.ignition :on}.to raise_error
		
		#####
		# 6. 2nd Class Level ejection from Ground Control
		SpaceShip.eject :FuelSystem	
		SpaceShip.injectors.should == [:Engines, :Landing]

		# sat affected
		sat.injectors.should == [:Landing, :Capsule]
		expect{sat.ignition :on}.to raise_error
		expect{sat.fuel_lines :off}.to raise_error
		sat.o2.should == :oxigen
		sat.gear.should == 'wheels'

		# flyer affected
		flyer.injectors.should == [:Engines, :Landing]
		expect{flyer.fuel_lines :on}.to raise_error
		expect{flyer.o2}.to raise_error
		flyer.ignition( :on ).should == :spark
		flyer.gear.should == 'wheels'

		#####
		# 7. 2nd vessel gets aided by aliens
		flyer.enrich FuelSystem()	# object level re-injection 

		# regains some function
		SpaceShip.injectors.should == [:Engines, :Landing]
		flyer.injectors.should == [:Engines, :Landing, :FuelSystem]
		flyer.fuel_lines( :on ).should == :fuel
		flyer.ignition( :on ).should == :spark
		flyer.gear.should == 'wheels'
		
		# o2 still failing
		expect{flyer.o2}.to raise_error
		
		# first vessel still same failures
		sat.injectors.should == [:Landing, :Capsule]
		expect{sat.ignition :on}.to raise_error
		expect{sat.fuel_lines :on}.to raise_error
		sat.o2.should == :oxigen
		sat.gear.should == 'wheels'

		#####
		# 8. flyer vessel gets aided by aliens a second time
		flyer.enrich Capsule()	# object level re-injection

		# regains all function
		SpaceShip.injectors.should == [:Engines, :Landing]
		flyer.injectors.should == [:Engines, :Landing, :FuelSystem, :Capsule]
		flyer.fuel_lines( :on ).should == :fuel
		flyer.ignition( :on ).should == :spark
		flyer.o2.should == :oxigen
		flyer.gear.should == 'wheels'

		# sat vessel still same failures
		sat.injectors.should == [:Landing, :Capsule]
		expect{sat.ignition :on}.to raise_error
		expect{sat.fuel_lines :on}.to raise_error
		sat.o2.should == :oxigen
		sat.gear.should == 'wheels'

		#####
		# 9. sat vessel looses capsule
		sat.eject :Capsule	# object level ejection

		# flyer vessel un-affected
		SpaceShip.injectors.should == [:Engines, :Landing]
		sat.injectors.should == [:Landing]
		flyer.injectors.should == [:Engines, :Landing, :FuelSystem, :Capsule]
		flyer.fuel_lines( :on ).should == :fuel
		flyer.ignition( :on ).should == :spark
		flyer.o2.should == :oxigen
		flyer.gear.should == 'wheels'
		
		# sat vessel can only land
		expect{sat.fuel_lines :on}.to raise_error
		expect{sat.ignition :on}.to raise_error
		expect{sat.o2}.to raise_error
		sat.gear.should == 'wheels'

		#####
		# 10. Class Level injection from Ground Control
		SpaceShip.inject FuelSystem()	
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]
		
		# class level re-injection: affects all objects
		# even if they have been re-injected at the object level 

		# sat vessel regains some function
		sat.injectors.should == [:Landing, :FuelSystem]
		sat.fuel_lines( :on ).should == :fuel
		sat.gear.should == 'wheels'
		
		# but still errors 
		expect{sat.ignition :off}.to raise_error
		expect{sat.hydration}.to raise_error
		
		# flyer vessel gains a backup!
		flyer.injectors.should == [:Engines, :Landing, :FuelSystem, :FuelSystem, :Capsule]
		flyer.ignition( :on ).should == :spark
		flyer.gas_tank( :full ).should == :gas
		flyer.hydration.should == :water
		flyer.gear.should == 'wheels'
		
		#####
		# Injector directives
		FuelSystem(:collapse)
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]

		# First vessel: fuel system is inoperative, everything else the same
		sat.injectors.should == [:Landing, :FuelSystem]
		sat.fuel_lines( :on ).should == nil
		expect{sat.ignition :off}.to raise_error
		expect{sat.hydration}.to raise_error
		sat.gear.should == 'wheels'

		# Second vessel: fuel system also inoperative, the rest same
		flyer.injectors.should == [:Engines, :Landing, :FuelSystem, :FuelSystem, :Capsule]
		flyer.gas_tank(:full).should == nil		
		flyer.ignition( :on )
		flyer.hydration.should == :water
		flyer.gear.should == 'wheels'

		#####
		# second directive 
		FuelSystem(:rebuild)
		
		# everything back to previous state
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]
		sat.injectors.should == [:Landing, :FuelSystem]
		sat.fuel_lines( :on ).should == :fuel
		sat.gear.should == 'wheels'
		expect{sat.ignition :off}.to raise_error
		expect{sat.hydration}.to raise_error
		flyer.injectors.should == [:Engines, :Landing, :FuelSystem, :FuelSystem, :Capsule]
		flyer.gas_tank(:full).should == :gas		
		flyer.ignition( :on ).should == :spark
		flyer.hydration.should == :water
		flyer.gear.should == 'wheels'
		
	end

	it 'co-exists with method_missing on classes/modules' do

		# writing method_missing in conjunction with injector use
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

		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]
		sat.injectors.should == [:Landing, :FuelSystem]
		sat.crash.should == :booohoooo
		sat.fuel_lines( :on ).should == :fuel
		expect{sat.ignition :off}.to raise_error
		expect{sat.hydration}.to raise_error
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

		sat.crash_and_burn.should == "look ma' no teeth"

		#####
		# Done on the injector
		# . cannot be done at the injector level
		injector :Pilot do 																		
			def automatic
				'auto pilot'
			end
			def method_missing sym, *args, &code 								#  THIS NEVER EXECUTES!!!
				'Going dauwn...'
			end
		end
		
		# object level injection: no go!
		sat.enrich Pilot()	
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]
		sat.injectors.should == [:Landing, :FuelSystem, :Pilot]
		sat.automatic.should == 'auto pilot'									
		expect{sat.noMethod.should == 'Going dauwn...' }.to raise_error
		sat.fuel_lines( :on ).should == :fuel
		expect{sat.ignition :off}.to raise_error
		expect{sat.hydration}.to raise_error
		sat.gear.should == 'wheels'
		
		# class level injection: no go!
		SpaceShip.inject Pilot()	

		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot]
		sat.injectors.should == [:Landing, :FuelSystem, :Pilot, :Pilot]
		sat.automatic.should == 'auto pilot'
		expect{sat.noMethod.should == 'Going dauwn...' }.to raise_error
		sat.fuel_lines( :on ).should == :fuel
		expect{sat.ignition :off}.to raise_error
		expect{sat.hydration}.to raise_error
		sat.gear.should == 'wheels'
		
		#####
		# Un-affected by directives
		Pilot(:silence)
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot]
		sat.injectors.should == [:Landing, :FuelSystem, :Pilot, :Pilot]
		sat.automatic.should == nil
		sat.fuel_lines( :on ).should == :fuel
		expect{sat.ignition :off}.to raise_error
		expect{sat.hydration}.to raise_error
		sat.gear.should == 'wheels'

		expect{sat.boohoo}.to raise_error
		expect{flyer.boohoo}.to raise_error
		
		#####
		# Un-affected by directives
		Pilot(:rebuild)
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot]
		sat.injectors.should == [:Landing, :FuelSystem, :Pilot, :Pilot]
		sat.automatic.should == 'auto pilot'
		sat.fuel_lines( :on ).should == :fuel
		expect{sat.ignition :off}.to raise_error
		expect{sat.hydration}.to raise_error
		sat.gear.should == 'wheels'

		expect{sat.boohoo}.to raise_error
		expect{flyer.boohoo}.to raise_error
		
	end
	
	describe 'standard inclusion/extension aspects' do
		
		it 'works with included/extended callbacks' do

			$stdout.should_receive(:puts).with('++++++++--------------++++++++++').twice()

			SS = injector :StarShipFunction do

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

				Building.link_to_ships

			}.to_not raise_error

		end

		it 'does not interfere for module inclusion and extension' do

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

				class Base
					include BA
					def moth
					end
				end

				Base.new.meth
				Base.new.mith
				Base.new.moth

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
					include AC
				end
			}.to raise_error(ArgumentError)

		end

		it 'does the same for Injector self inclusion' do

			expect{

				Includer = injector :includer

				includer do
					def far
					end
					inject Includer
				end

			}.to raise_error(ArgumentError)

		end

	end

	describe "ancestor chains" do
		
		it 'modifies the ancestor chains accordingly' do
			
			class Child
				include injector :parent
			end
			
			Child.ancestors.to_s.should match( /Child, \(.*<\|parent\|>\), Object.*BasicObject/ )
			
			c = Child.new.enrich Child.parent
			
			c.singleton_class.ancestors.to_s.should match( /\(.*<\|parent\|>\), Child, \(.*<\|parent\|>\), Object.*BasicObject/ )
			
			c.eject Child.parent
			
			c.singleton_class.ancestors.to_s.should match( /Child, \(.*<\|parent\|>\), Object.*BasicObject/ )
				
			Child.eject Child.parent
			
			Child.ancestors.to_s.should match( /Child, Object.*BasicObject/ )
			
			c.enrich Child.parent
			c.enrich Child.parent
			
			c.singleton_class.ancestors.to_s.should match( /\(.*<\|parent\|>\), \(.*<\|parent\|>\), Child, Object.*BasicObject/ )
			
			c.eject Child.parent
			c.eject Child.parent
			
			c.singleton_class.ancestors.to_s.should match( /Child, Object.*BasicObject/ )
			
			expect{ Child.send :update, Child.parent }.to raise_error # cannot update empty injector
			
			Child.inject Child.parent
			
			Child.ancestors.to_s.should match( /Child, \(.*<\|parent\|>\), Object.*BasicObject/ )
			
			c.singleton_class.ancestors.to_s.should match( /Child, \(.*<\|parent\|>\), Object.*BasicObject/ )
			
			c.eject Child.parent
			
			c.singleton_class.ancestors.to_s.should match( /Child, Object.*BasicObject/ )
			
			Child.send :update, Child.parent

			c.singleton_class.ancestors.to_s.should match( /Child, \(.*<\|parent\|>\), Object.*BasicObject/ )

		end
	end
	
	########################################################################################
	# If you want to run these examples: you must have a debugger for your version of Ruby
	#              ** You must uncomment the DX line in spec_helper **
	# #####################################################################################
	
	# require 'jackbox/examples/dx'
	# describe DX, 'the debugger extras makes use of another capability of injectors to just completely
	# collapse leaving the method calls inplace but ejecting the actual funtion out of them' do
	# 	
	# 	describe 'ability to break into debugger' do
	# 		# after(:all) { load "../../lib/tools/dx.rb"}
	# 		it 'has a method to break into debugger mode' do
	# 			DX.should_receive :debug
	# 			DX.debug
	# 		end
	# 		it 'can break into the debugger on exception' do
	# 			DX.should_receive :debug
	# 			DX.seize TypeError
	# 			expect{String.new 3}.to raise_error
	# 		end
	# 		the 'call to #collapse leaves the methods inplace but silent.  There are no
	# 		NoMethodError exceptions raised the programm proceeds but the DX function has been removed.  
	# 		See the #rebuild method' do
	# 			DX.logger :collapse
	# 			DX.splatter :collapse
	# 		
	# 			DX.debug  # nothing happens
	# 			DX.seize Exception # nothing happens
	# 			DX.assert_loaded.should == nil
	# 			DX.log("boo").should == nil
	# 			DX.syslog("baa").should == nil
	# 		end
	# 	end
	# end
	
end		

