require "spec_helper" 

include Injectors

describe 'Injector Directives: ' do
	
	describe "<injector> :implode, the entire injector and all instances eliminated.  Produces different results than 
	ejecting individual injectors, or from using <injector> :collapse and then restored using <injector> :rebuild" do
	
		an 'example of complete injector implosion' do
		
			class Model
				def feature
					'a standard feature'
				end
			end

			injector :extras do
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

		describe 'difference between injector ejection/implosion' do

			the 'Injector reconstitution after ejection is possible through reinjection
			but reconstitution after injector implosion is NOT AVAILABLE' do

				# code defined
				class Job
					injector :agent do
						def call
						end
					end
					inject agent
				end
				Job.injectors.sym_list.should == [:agent]

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

describe '<injector> :collapse.  Injectors can be silenced. This description produces similar results to 
the previous except that further injector method calls DO NOT raise an error they just quietly return nil' do
	
	the 'case with objects' do

		injector :copiable do
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
			injector :code do
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
		
		injector :somecode do 																				# share member name with container
			def fun
				super + ' and more fun'
			end
		end
	
		bc = BumperCar.new.enrich(somecode).enrich(somecode)					# decorator pattern
		bc.fun.should == 'this is fun and more fun and more fun'
	
		somecode :collapse																						# collapse the injector
		
		bc.fun.should == 'this is fun'																# class memeber foo intact
	                                                                    
		# eject all injectors                                             
		bc.injectors.sym_list.each { |ij| bc.eject ij }								# same as before
		bc.fun.should == 'this is fun' 

	end
end

describe '<injector> :rebuild.  Quieted injectors restored without having
to re-inject them into every object they modify' do
	
	the 'case with objects' do

		injector :reenforcer do
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
			injector :ThinFunction do
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

	the 'rebuild reconstructs the entire injector and all applications' do

		class BumperCar
			def fun
				'this is fun'
			end
		end
		injector :othercode do 																				# share memeber name with container
			def fun
				super + ' and more fun'
			end
		end

		bc = BumperCar.new.enrich(othercode).enrich(othercode)				# decorator pattern
		bc.fun.should == 'this is fun and more fun and more fun'

		othercode :silence																						# declare injector silence
		
		bc.fun.should == 'this is fun'																# class member un-affected
		
		othercode :active
		bc.fun.should == 'this is fun and more fun and more fun'			# restores all decorations !!!
		
		# restore the original
		bc.injectors.sym_list.each { |ij| bc.eject ij }								# same as before
		bc.fun.should == 'this is fun' 

	end

end
