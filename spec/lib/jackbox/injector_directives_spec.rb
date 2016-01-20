require "spec_helper" 

include Injectors

describe 'Injector Directives: ' do
	
	describe "<trait> :implode, the entire trait and all instances eliminated.  Produces different results than 
	ejecting individual traits, or from using <trait> :collapse and then restored using <trait> :rebuild" do
	
		an 'example of complete trait implosion' do
		
			class Model
				def feature
					'a standard feature'
				end
			end

			trait :extras do
				def feature
					super() + ' plus some extras'
				end
			end
		
			car = Model.new.enrich(extras)
			car.feature.should == 'a standard feature plus some extras'

			extras :implode
		
			# total implosion
			expect{extras}.to raise_error(NameError, /extras/)
			car.feature.should == 'a standard feature'
		
			expect{ 
				new_car = Model.new.enrich(extras) 
				}.to raise_error(NameError, /extras/)
			
			expect{
				extras do
					def foo
					end
				end
				}.to raise_error(NameError, /extras/)
			
		end

		describe 'difference between trait ejection/implosion' do

			the 'Injector reconstitution after ejection is possible through reinjection
			but reconstitution after trait implosion is NOT AVAILABLE' do

				# code defined
				class Job
					trait :agent do
						def call
						end
					end
					inject agent
				end
				Job.traits.sym_list.should == [:agent]

				# normal use
				expect{Job.new.call}.to_not raise_error

				# code ejection
				Job.eject :agent

				# code extended and re-injected
				class Job
					inject agent
					agent do
						def sms
						end
					end
				end

				#normal use
				expect{Job.new.call}.to_not raise_error
				expect{Job.new.sms}.to_not raise_error

				# code imlossion
				Job.agent :implode

				# Unavailable !!!
				expect{
					class Job
						inject :agent
					end
					}.to raise_error(TypeError)

				# Unavailable !!!
				expect{
					class Job
						agent do
							def something
							end
						end
					end }.to raise_error(NoMethodError)

				# Unavailable!!!
				expect{Job.new.call}.to raise_error(NoMethodError)
				expect{Job.new.sms}.to raise_error(NoMethodError)

			end
		end

	end
end

describe '<trait> :collapse.  Injectors can be silenced. This description produces similar results to 
the previous except that further trait method calls DO NOT raise an error they just quietly return nil' do
	
	the 'case with objects' do

		trait :copiable do
			def object_copy
				'a dubious copy'
			end
		end

		o1 = Object.new.enrich(copiable)
		o2 = Object.new.enrich(copiable)

		o1.object_copy.should == 'a dubious copy'
		o2.object_copy.should == 'a dubious copy'

		copiable :silence

		o1.object_copy.should == nil
		o2.object_copy.should == nil

	end

	the 'case with classes' do

		class SomeClass
			trait :code do
				def tester
					'boo'
				end
			end
			
			inject code
		end
		
		# collapse
		SomeClass.code :collapse

		# build
		a = SomeClass.new
		b = SomeClass.new

		a.tester.should == nil
		b.tester.should == nil
		
		# further
		SomeClass.eject :code 
		expect{ a.tester }.to raise_error(NoMethodError)
		expect{ b.tester }.to raise_error(NoMethodError)

	end
	
	the 'class members are not affected by the collapse' do

		# define container
		class BumperCar
			def fun
				'this is fun'
			end
		end				
		
		trait :somecode do 																				# share member name with container
			def fun
				super + ' and more fun'
			end
		end
	
		bc = BumperCar.new.enrich(somecode).enrich(somecode)					# decorator pattern
		bc.fun.should == 'this is fun and more fun and more fun'
	
		somecode :collapse																						# collapse the trait
		
		bc.fun.should == 'this is fun'																# class memeber foo intact
	                                                                    
		# eject all traits                                             
		bc.traits.sym_list.each { |ij| bc.eject ij }								# same as before
		bc.fun.should == 'this is fun' 

	end
end

describe '<trait> :rebuild.  Quieted traits restored without having
to re-inject them into every object they modify' do
	
	the 'case with objects' do

		trait :reenforcer do
			def thick_walls
				'=====  ====='
			end
		end

		o1 = Object.new.enrich(reenforcer)
		o2 = Object.new.enrich(reenforcer)

		reenforcer :collapse

		o1.thick_walls.should == nil
		o2.thick_walls.should == nil

		reenforcer :rebuild

		o1.thick_walls.should == '=====  ====='
		o2.thick_walls.should == '=====  ====='

	end

	the 'case with classes' do
	
		class SomeBloatedObject
			trait :ThinFunction do
				def perform
					'do the deed'
				end
			end
			inject ThinFunction()
		end
		ThinFunction :silence
	
		tester = SomeBloatedObject.new
		tester.perform.should == nil
	
		ThinFunction :active
		tester.perform.should == 'do the deed'
	
	end

	the 'rebuild reconstructs the entire trait and all applications' do

		class BumperCar
			def fun
				'this is fun'
			end
		end
		trait :othercode do 																				# share memeber name with container
			def fun
				super + ' and more fun'
			end
		end

		bc = BumperCar.new.enrich(othercode).enrich(othercode)				# decorator pattern
		bc.fun.should == 'this is fun and more fun and more fun'

		othercode :silence																						# declare trait silence
		
		bc.fun.should == 'this is fun'																# class member un-affected
		
		othercode :active
		bc.fun.should == 'this is fun and more fun and more fun'			# restores all decorations !!!
		
		# restore the original
		bc.traits.sym_list.each { |ij| bc.eject ij }								# same as before
		bc.fun.should == 'this is fun' 

	end

end

describe 'more interesting uses' do
	
	it 'allows the following' do
		
		jack :PreFunction do
			def pre_function
				puts '++++++++++'
			end
		end
		
		jack :PosFunction do
			def pos_function
				puts '=========='
			end
		end
		
		class Model
			
			inject PreFunction(:silence)
			inject PosFunction(:silence) 
			
			def meth arg
				pre_function
				puts arg * arg
				pos_function
			end
		end
		
		obj = Model.new
		
		$stdout.should_receive(:puts).with(4)
		obj.meth( 2 )
		
		PreFunction(:active)
		PosFunction(:active)

		$stdout.should_receive(:puts).with('++++++++++')
		$stdout.should_receive(:puts).with(4)
		$stdout.should_receive(:puts).with('==========')
		obj.meth( 2 )

	end
end