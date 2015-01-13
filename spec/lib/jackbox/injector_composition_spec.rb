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

	the 'composition of many injectors into an object defined above is specified as follows' do

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


		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.fuel_lines :on
		flyer.ignition :on
		flyer.o2
		flyer.gear.should == 'wheels'

		# eject class level injector at the object level
		flyer.eject :Capsule

		# expect errors
		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.injectors.should == [:FuelSystem, :Engines, :Landing]
		expect{flyer.o2}.to raise_error
		flyer.fuel_lines :dead
		flyer.ignition :on
		flyer.gear.should == 'wheels'

		# eject class level injector at the object level
		flyer.eject :Engines

		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.injectors.should == [:FuelSystem, :Landing]
		expect{flyer.ignition :on}.to raise_error
		expect{flyer.o2}.to raise_error
		flyer.fuel_lines :dead
		flyer.gear.should == 'wheels'

		sat = SpaceShip.new.launch

		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.injectors.should == [:FuelSystem, :Landing]
		sat.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		sat.fuel_lines :on
		sat.ignition :on
		sat.o2
		flyer.fuel_lines :dead
		expect{flyer.ignition :on}.to raise_error
		expect{flyer.o2}.to raise_error
		flyer.gear.should == 'wheels'

		flyer.enrich Capsule() # object level re-injection

		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.injectors.should == [:FuelSystem, :Landing, :Capsule]
		sat.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
		flyer.o2
		expect{flyer.ignition :on}.to raise_error
		flyer.fuel_lines :dead
		sat.o2
		sat.ignition :on
		sat.fuel_lines :on
		flyer.gear.should == 'wheels'

		SpaceShip.eject :Capsule  # class level ejection: affects objects of the class 
															# that have not been re-injected at the object level

		SpaceShip.injectors.should == [:FuelSystem, :Engines, :Landing]
		flyer.injectors.should == [:FuelSystem, :Landing, :Capsule]
		sat.injectors.should == [:FuelSystem, :Engines, :Landing]
		flyer.o2
		expect{flyer.ignition :on}.to raise_error
		flyer.fuel_lines :dead
		expect{sat.o2}.to raise_error
		sat.ignition :on
		sat.fuel_lines :on
		flyer.gear.should == 'wheels'

		SpaceShip.eject :FuelSystem	# class level ejection: affects objects of the class 
															# that have not been re-injected at the object level

		SpaceShip.injectors.should == [:Engines, :Landing]
		flyer.injectors.should == [:Landing, :Capsule]
		sat.injectors.should == [:Engines, :Landing]
		expect{flyer.ignition :on}.to raise_error
		expect{flyer.fuel_lines :off}.to raise_error
		flyer.o2
		sat.ignition :on
		expect{sat.fuel_lines :on}.to raise_error
		expect{sat.o2}.to raise_error
		flyer.gear.should == 'wheels'

		sat.enrich FuelSystem()	# object level re-injection 

		SpaceShip.injectors.should == [:Engines, :Landing]
		flyer.injectors.should == [:Landing, :Capsule]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem]
		sat.fuel_lines :on
		sat.ignition :on
		expect{sat.o2}.to raise_error
		expect{flyer.ignition :on}.to raise_error
		expect{flyer.fuel_lines :on}.to raise_error
		flyer.o2
		flyer.gear.should == 'wheels'

		sat.enrich Capsule()	# object level re-injection

		SpaceShip.injectors.should == [:Engines, :Landing]
		flyer.injectors.should == [:Landing, :Capsule]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :Capsule]
		sat.fuel_lines :on
		sat.ignition :on
		sat.o2
		expect{flyer.ignition :on}.to raise_error
		expect{flyer.fuel_lines :on}.to raise_error
		flyer.o2
		flyer.gear.should == 'wheels'

		flyer.eject :Capsule	# object level ejection

		SpaceShip.injectors.should == [:Engines, :Landing]
		flyer.injectors.should == [:Landing]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :Capsule]
		sat.fuel_lines :on
		sat.ignition :on
		sat.o2
		expect{flyer.fuel_lines :on}.to raise_error
		expect{flyer.ignition :on}.to raise_error
		expect{flyer.o2}.to raise_error
		flyer.gear.should == 'wheels'

		SpaceShip.inject FuelSystem()	# class level re-injection: affects all objects
																	# even if they have been re-injected at the object level 
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]
		flyer.injectors.should == [:Landing, :FuelSystem]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :FuelSystem, :Capsule]
		flyer.fuel_lines :on
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		sat.ignition :on
		sat.gas_tank :full
		sat.hydration
		flyer.gear.should == 'wheels'
		
		
		# writing method_missing in conjunction with injector use
		class SpaceShip
			def method_missing sym, *args, &code								# Must be done on the class
				if sym == :crash
					:boooohoooo
					# ... do your stuff here
				else
					super(sym, *args, &code) 												#  MUST CALL super() ON THE FALLOUT!!!
				end
			end
		end
		flyer.crash.should == :boooohoooo
		sat.crash.should == :boooohoooo
		expect{flyer.automatic.should == 'auto pilot'}.to raise_error
		expect{sat.automatic.should == 'auto pilot'}.to raise_error
		flyer.fuel_lines :on
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		sat.gas_tank :full
		sat.ignition :on
		sat.hydration
		flyer.gear.should == 'wheels'
		
		injector :Pilot do
			def automatic
				'auto pilot'
			end
			def method_missing sym, *args, &code 								#  THIS NEVER EXECUTES!!!
				puts :baaaahaaaa or :baaaahaaaa
			end
		end
		
		flyer.enrich Pilot()	# object level injection
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem]
		flyer.injectors.should == [:Landing, :FuelSystem, :Pilot]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :FuelSystem, :Capsule]
		flyer.automatic.should == 'auto pilot'									
		expect{flyer.noMethod.should == :baaaahaaaa }.to raise_error
		flyer.fuel_lines :on
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		sat.gas_tank :full
		sat.ignition :on
		sat.hydration
		flyer.gear.should == 'wheels'
		
		SpaceShip.inject Pilot()

		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot]
		flyer.injectors.should == [:Landing, :FuelSystem, :Pilot, :Pilot]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot, :FuelSystem, :Capsule]
		flyer.automatic.should == 'auto pilot'
		expect{flyer.noMethod.should == :baaaahaaaa}.to raise_error
		sat.automatic.should == 'auto pilot'
		expect{sat.noMethod}.to raise_error
		flyer.fuel_lines :on
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		sat.gas_tank :full
		sat.ignition :on
		sat.hydration
		flyer.gear.should == 'wheels'
		
		Pilot(:silence)
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot]
		flyer.injectors.should == [:Landing, :FuelSystem, :Pilot, :Pilot]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot, :FuelSystem, :Capsule]
		flyer.automatic.should == nil
		sat.automatic.should == nil
		flyer.fuel_lines :on
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		sat.gas_tank :full
		sat.ignition :on
		sat.hydration
		flyer.gear.should == 'wheels'
		expect{flyer.boohoo}.to raise_error
		expect{sat.boohoo}.to raise_error
		
		FuelSystem(:silence)
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot]
		flyer.injectors.should == [:Landing, :FuelSystem, :Pilot, :Pilot]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot, :FuelSystem, :Capsule]
		flyer.automatic.should == nil
		sat.automatic.should == nil
		flyer.fuel_lines( :on ).should == nil
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		sat.gas_tank(:full).should == nil		
		sat.ignition( :on )
		sat.hydration
		flyer.gear.should == 'wheels'
		expect{flyer.boohoo}.to raise_error
		expect{sat.boohoo}.to raise_error
		
		FuelSystem(:active)
		
		SpaceShip.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot]
		flyer.injectors.should == [:Landing, :FuelSystem, :Pilot, :Pilot]
		sat.injectors.should == [:Engines, :Landing, :FuelSystem, :Pilot, :FuelSystem, :Capsule]
		flyer.automatic.should == nil
		sat.automatic.should == nil
		flyer.fuel_lines( :on ).should == :fuel
		expect{flyer.ignition :off}.to raise_error
		expect{flyer.hydration}.to raise_error
		sat.gas_tank(:full).should == :gas		
		sat.ignition( :on )
		sat.hydration
		flyer.gear.should == 'wheels'
		expect{flyer.boohoo}.to raise_error
		expect{sat.boohoo}.to raise_error
		
	end
	
	describe "#included/#extended" do

		it 'should' do
		
			$stdout.should_receive(:puts).with('++++++++--------------++++++++++').twice()

			SS = injector :StarShipFunction do
		
				def phaser
				end
		
				def neutron_torpedoes
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
		
			}.to_not raise_error
		
		
			class Building
				extend SS
			end
			expect{
			
				Building.link_to_ships
			
			}.to_not raise_error
		
		end
	
		this 'is another example' do
			
			class Aclass
				def meth arg
					p arg
				end
			end
			Emitter = injector :emitter do
				def self.extended host
					host.class_eval {
						class << self
							private :new
							def emitt
								new
							end
						end
					}
				end
			end
			class Aclass
				extend Emitter
			end
			Aclass.emitt.should be_instance_of(Aclass)
			

			emitter do
				def self.extended host
					host.class_eval {
						class << self
							private :new
							def emitt
								with new do
									def meth arg
										p arg or arg
									end
								end
							end
						end
					}
				end
			end
			class Bclass
				extend Emitter
			end
			Bclass.emitt.should be_instance_of(Bclass)
			expect{
				
				Bclass.emitt.meth('boo').should == 'boo'
				
			}.to_not raise_error

			
			# whatsmore 
			Aclass.emitt.should be_instance_of(Aclass)
			expect{
				
				Aclass.emitt.meth('baa')
				
			}.to_not raise_error
			
		end
	end
	
end		

