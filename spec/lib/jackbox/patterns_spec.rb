require "spec_helper"
=begin rdoc
	This file contains the specs for the GOF Decorator Pattern and 
	Strategy Pattern use cases for injectors.
=end

include Injectors

describe 'some use cases', :injectors do 

	describe 'GOF Decortors is one use of this codebase' do
		the 'GOF class decorator:   Traditionally this is only partially solved in Ruby through PORO 
		decorators or the use of modules with the problems of loss of class identity for the former 
		or the limitations on the times it can be re-applied for the latter.' do

			class Coffee
				def cost
					1.50
				end
			end

			injector :milk do
				def cost
					super() + 0.30
				end
			end
			injector :sprinkles do
				def cost
					super() + 0.15
				end
			end
			cup = Coffee.new.enrich(milk).enrich(sprinkles)
			cup.should be_instance_of(Coffee)
			cup.cost.should == 1.95
			
			user_input = 'extra red sprinkles'
			sprinkles do
				define_method :appearance do
					user_input
				end
			end
			
			cup.enrich(sprinkles)
			cup.appearance.should == 'extra red sprinkles'
			cup.cost.should == 2.10
		end

		this 'can be applied multiple times to the same receiver:' do
			
			class Coffee
				def cost
					1.50
				end
			end
			injector :milk do
				def cost
					super() + 0.30
				end
			end
			injector :sprinkles do
				def cost
					super() + 0.15
				end
			end
			
			cup = Coffee.new.enrich(milk).enrich(sprinkles).enrich(sprinkles)
			cup.injectors.should == [:milk, :sprinkles, :sprinkles]
			cup.cost.should == 2.10
			cup.should be_instance_of(Coffee)
			
		end
		
		it 'can use the surrounding context in even a two-stage closure' do
			
			user_input = 'extra red sprinkles'												# first stage
			sprinkles do 																							
				appearance = user_input																	# seconde stage
				define_method :appearance do 														
					appearance
				end
			end
			
			cup = Coffee.new
			cup.enrich(sprinkles)
			cup.appearance.should == 'extra red sprinkles'
			cup.cost.should == 1.65 
			
			user_input = 'cold milk'
			milk do
				temp = user_input.split.first
				define_method :temp do 
					temp
				end
			end
			
			cup.enrich milk
			cup.temp.should == 'cold'
			cup.cost.should == 1.95
			cup.appearance.should == 'extra red sprinkles'

		end
	end
	
	describe 'strategy pattern.' do
		this 'is a pattern with changes the guts of an object as opposed to just changing its face. Traditional 
		examples of this pattern use PORO component injection within constructors. Here is an alternate 
		implementation' do
			class Coffee
				attr_reader :strategy
				def initialize
				  @strategy = nil
				end
				def cost
					1.00
				end
			  def brew
					@strategy = 'normal'
			  end
				def mix
				end
			end
			
			cup = Coffee.new
			cup.brew
			cup.strategy.should == 'normal'
			
			
			injector :sweedish do
				def brew
					@strategy = 'sweedish'
				end
			end
			injector :french do
				def brew
					@strategy ='french'
				end
			end
		
			cup = Coffee.new.enrich(sweedish)  # clobbers original strategy for this instance only
			cup.brew
			cup.strategy.should == ('sweedish')
			cup.mix
		
			cup.enrich(french)
			cup.brew
			cup.strategy.should == ('french')
			cup.mix
		end
		
		this 'can be further enhanced using Injectors in the following above pattern' do
			injector :russian do
				def brew
					@strategy = super.to_s + 'vodka'
				end
			end
			injector :scotish do
				def brew
					@strategy = super.to_s + 'wiskey'
				end
			end
			
			cup = Coffee.new
			cup.enrich(russian).enrich(scotish).enrich(russian)
			cup.brew
			cup.strategy.should == 'normalvodkawiskeyvodka'
		end
		
		it 'is even better or possible to have yet another implementation. This time we completely
		replace the current strategy by actually ejecting it out of the class and then injecting
		a new one' do
			
			class Tea < Coffee  # Tea is a type of coffee!! ;~Q)
				injector :SpecialStrategy do
					def brew
						@strategy = 'special'
					end
				end
				inject SpecialStrategy()
			end
			
			cup = Tea.new
			cup.brew
			cup.strategy.should == 'special'
			friends_cup = Tea.new
			friends_cup.strategy == 'special'
			
			Tea.eject :SpecialStrategy
			
			Tea.inject sweedish
			cup.brew
			friends_cup.brew
			cup.strategy.should == 'sweedish'
			friends_cup.strategy.should == 'sweedish'
			
			Tea.inject french
			cup.brew
			friends_cup.brew
			cup.strategy == 'french'
			friends_cup.strategy.should == 'french'
			
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

