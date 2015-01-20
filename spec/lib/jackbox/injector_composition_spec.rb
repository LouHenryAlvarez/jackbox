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
	inject FuelSystem()
	inject Engines()
	inject Capsule()
	inject Landing()

	def launch
		gas_tank fuel_lines burners ignition :go
		self
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
	flyer = SpaceShip.new.launch
	# flyer = subject.new.launch

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

		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.fuel_lines( :on ).should == :fuel
		flyer.ignition( :on ).should == :spark
		flyer.o2.should == :oxigen
		flyer.gear.should == 'wheels'

		
		# eject class level injector at the object level
		flyer.eject :Capsule

		# expect errors
		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.injectors.should == [:FuelSystem, :Engines, :Landing]
		expect{flyer.o2}.to raise_error
		flyer.fuel_lines( :good ).should == :fuel
		flyer.ignition( :on ).should == :spark
		flyer.gear.should == 'wheels'

		
		# eject class level injector at the object level
		flyer.eject :Engines

		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.injectors.should == [:FuelSystem, :Landing]
		expect{flyer.o2}.to raise_error
		expect{flyer.ignition :on}.to raise_error
		flyer.fuel_lines( :good ).should == :fuel
		flyer.gear.should == 'wheels'

		
		sat = SpaceShip.new.launch

		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.injectors.should == [:FuelSystem, :Landing]
		sat.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.fuel_lines( :on ).should == :fuel
		sat.ignition( :on ).should == :spark
		sat.o2.should == :oxigen
		flyer.fuel_lines( :good ).should == :fuel
		expect{flyer.ignition :on}.to raise_error
		expect{flyer.o2}.to raise_error
		flyer.gear.should == 'wheels'

		
		flyer.enrich Capsule() # object level re-injection

		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.injectors.should == [:FuelSystem, :Landing, :Capsule]
		sat.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.fuel_lines( :good ).should == :fuel
		expect{flyer.ignition :on}.to raise_error
		flyer.o2.should == :oxigen
		flyer.gear.should == 'wheels'
		sat.ignition( :on ).should == :spark
		sat.fuel_lines( :on ).should == :fuel
		sat.o2.should == :oxigen

		
		SpaceShip.eject :Capsule  # class level ejection: affects objects of the class 
															# that have not been re-injected at the object level

		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Landing]
		flyer.injectors.should == [:FuelSystem, :Landing, :Capsule]
		sat.injectors.should == [:FuelSystem, :Engines, :Landing]
		flyer.o2.should == :oxigen
		expect{flyer.ignition :on}.to raise_error
		flyer.fuel_lines( :good ).should == :fuel
		expect{sat.o2}.to raise_error
		sat.ignition( :on ).should == :spark
		sat.fuel_lines( :on ).should == :fuel
		flyer.gear.should == 'wheels'

		
		SpaceShip.eject :FuelSystem	# class level ejection: affects objects of the class 
															# that have not been re-injected at the object level

		SpaceShip.injectors.should == [:Engines, :Landing]
		flyer.injectors.should == [:Landing, :Capsule]
		sat.injectors.should == [:Engines, :Landing]
		expect{flyer.ignition :on}.to raise_error
		expect{flyer.fuel_lines :off}.to raise_error
		flyer.o2.should == :oxigen
		sat.ignition( :on ).should == :spark
		expect{sat.fuel_lines :on}.to raise_error
		expect{sat.o2}.to raise_error
		flyer.gear.should == 'wheels'

		
		sat.enrich FuelSystem()	# object level re-injection 

		SpaceShip.injectors.should == [:Engines, :Landing]
		flyer.injectors.should == [:Landing, :Capsule]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem]
		sat.fuel_lines( :on ).should == :fuel
		sat.ignition( :on ).should == :spark
		expect{sat.o2}.to raise_error
		expect{flyer.ignition :on}.to raise_error
		expect{flyer.fuel_lines :on}.to raise_error
		flyer.o2.should == :oxigen
		flyer.gear.should == 'wheels'

		
		sat.enrich Capsule()	# object level re-injection

		SpaceShip.injectors.should == [:Engines, :Landing]
		flyer.injectors.should == [:Landing, :Capsule]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :Capsule]
		sat.fuel_lines( :on ).should == :fuel
		sat.ignition( :on ).should == :spark
		sat.o2.should == :oxigen
		expect{flyer.ignition :on}.to raise_error
		expect{flyer.fuel_lines :on}.to raise_error
		flyer.o2.should == :oxigen
		flyer.gear.should == 'wheels'

		
		flyer.eject :Capsule	# object level ejection

		SpaceShip.injectors.should == [:Engines, :Landing]
		flyer.injectors.should == [:Landing]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :Capsule]
		sat.fuel_lines( :on ).should == :fuel
		sat.ignition( :on ).should == :spark
		sat.o2.should == :oxigen
		expect{flyer.fuel_lines :on}.to raise_error
		expect{flyer.ignition :on}.to raise_error
		expect{flyer.o2}.to raise_error
		flyer.gear.should == 'wheels'

		
		SpaceShip.inject FuelSystem()	# class level re-injection: affects all objects
																	# even if they have been re-injected at the object level 
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]
		flyer.injectors.should == [:Landing, :FuelSystem]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :FuelSystem, :Capsule]
		flyer.fuel_lines( :on ).should == :fuel
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		sat.ignition( :on ).should == :spark
		sat.gas_tank( :full ).should == :gas
		sat.hydration.should == :water
		flyer.gear.should == 'wheels'
		
		
		FuelSystem(:collapse)
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]
		flyer.injectors.should == [:Landing, :FuelSystem]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :FuelSystem, :Capsule]
		flyer.fuel_lines( :on ).should == nil
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		sat.gas_tank(:full).should == nil		
		sat.ignition( :on )
		sat.hydration.should == :water
		flyer.gear.should == 'wheels'
		expect{flyer.boohoo}.to raise_error
		expect{sat.boohoo}.to raise_error
		
		
		FuelSystem(:rebuild)
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]
		flyer.injectors.should == [:Landing, :FuelSystem]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :FuelSystem, :Capsule]
		flyer.fuel_lines( :on ).should == :fuel
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		sat.gas_tank(:full).should == :gas		
		sat.ignition( :on ).should == :spark
		sat.hydration.should == :water
		flyer.gear.should == 'wheels'
		expect{flyer.boohoo}.to raise_error
		expect{sat.boohoo}.to raise_error
		
	end

	it 'works with method_missing' do

		# writing method_missing in conjunction with injector use
		class SpaceShip
			def method_missing sym, *args, &code								# done on the class
				if sym == :crash
					:baaaahaaaa
					# ... do your stuff here
				else
					super(sym, *args, &code) 											
				end
			end
		end

		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]
		flyer.injectors.should == [:Landing, :FuelSystem]
		flyer.crash.should == :baaaahaaaa
		flyer.fuel_lines( :on ).should == :fuel
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		flyer.gear.should == 'wheels'
		
		
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

		# flyer = SpaceShip.new
		flyer.crash_and_burn.should == "look ma' no teeth"


		injector :Pilot do 																		# done on the injector
			def automatic
				'auto pilot'
			end
			def method_missing sym, *args, &code 								#  THIS NEVER EXECUTES!!!
				puts :booohoooo or :booohoooo
			end
		end
		
		flyer.enrich Pilot()	# object level injection
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]
		flyer.injectors.should == [:Landing, :FuelSystem, :Pilot]
		flyer.automatic.should == 'auto pilot'									
		expect{flyer.noMethod.should == :booohoooo }.to raise_error
		flyer.fuel_lines( :on ).should == :fuel
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		flyer.gear.should == 'wheels'
		
		
		SpaceShip.inject Pilot()

		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot]
		flyer.injectors.should == [:Landing, :FuelSystem, :Pilot, :Pilot]
		flyer.automatic.should == 'auto pilot'
		expect{flyer.noMethod.should == :booohoooo}.to raise_error
		flyer.fuel_lines( :on ).should == :fuel
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		flyer.gear.should == 'wheels'
		
		
		Pilot(:silence)
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot]
		flyer.injectors.should == [:Landing, :FuelSystem, :Pilot, :Pilot]
		flyer.automatic.should == nil
		flyer.fuel_lines( :on ).should == :fuel
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		flyer.gear.should == 'wheels'
		expect{flyer.boohoo}.to raise_error
		expect{sat.boohoo}.to raise_error
		
		Pilot(:rebuild)
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot]
		flyer.injectors.should == [:Landing, :FuelSystem, :Pilot, :Pilot]
		flyer.automatic.should == 'auto pilot'
		flyer.fuel_lines( :on ).should == :fuel
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		flyer.gear.should == 'wheels'
		expect{flyer.boohoo}.to raise_error
		
		
	end
	

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

end		

