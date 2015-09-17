require "spec_helper"
=begin rdoc
	This file contains the specs for the GOF Decorator Pattern and 
	Strategy Pattern use cases for injectors.
=end

include Injectors

describe 'some use cases', :injectors do 

	describe 'GOF Decortors is one use of this codebase. Traditionally this is only partially solved in Ruby through PORO 
	decorators or the use of modules with the problems of loss of class identity for the former 
	or the limitations on the times it can be re-applied for the latter. We solve that!!' do 
	
		the 'GOF class decorator' do

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
			injector :vanilla do
				def cost
					super() + 0.15
				end
			end

			cup = Coffee.new.enrich(milk).enrich(vanilla)
			cup.should be_instance_of(Coffee)
			cup.cost.should == 1.95
			
		end

		this 'can then be applied multiple times to the same receiver:' do
			
			class Coffee
				def cost
					1.50
				end
			end
			
			jack :milk do
				def cost
					super() + 0.30
				end
			end
			jack :vanilla do
				def cost
					super() + 0.15
				end
			end

			cup = Coffee.new.enrich(milk).enrich(vanilla).enrich(vanilla)
			cup.injectors.sym_list.should == [:milk, :vanilla, :vanilla]
			cup.cost.should == 2.10
			cup.should be_instance_of(Coffee)
			
		end
		
		the 'a further workflow' do

			class Coffee
				def cost
					1.50
				end
			end

			jack :milk do
				def cost
					super() + 0.30
				end
			end
			jack :vanilla do
				def cost
					super() + 0.15
				end
			end

			cup = Coffee.new.enrich(milk).enrich(vanilla)
			cup.should be_instance_of(Coffee)
			cup.cost.should == 1.95
			
			user_input = 'extra red vanilla'
			vanilla do
				define_method :appearance do
					user_input
				end
			end
			
			cup.enrich(vanilla)
			cup.injectors.sym_list.should == [:milk, :vanilla, :vanilla]
			cup.cost.should == 2.10
			cup.appearance.should == 'extra red vanilla'
			
		end
		
		a 'bigger example' do
		             
			# some data

			def database_content
				%{car truck airplane boat}
			end 

			# rendering helper controls

			class MyWidgetClass
				def initialize(content)
					@content = content
				end       

				def render
					"<div id='MyWidget'>#{@content}</div>"
				end
			end

			injector :WidgetDecorator do
				attr_reader :width, :height       

				def dim(width, heigth)
					@width, @heigth = width, heigth
				end
			end

			DesktopDecorator = WidgetDecorator do
				def render
					dim '600px', '200px'
					%{
						<style>
						#MyWidget{
							font: 14px, helvetica;
							width:#{@width};
							height: #{@heigth}
						}
						</style>
						#{super()}
					}
				end
			end

			MobileDecorator = WidgetDecorator do
				def render content
					dim '200px', '600px'
					%{
						<style>
						#MyWidget{
							font: 10px, arial
							width:#{@width}
							height: #{@heigth}
						}
						</style>
						#{super()}
					}
				end
			end


			# somewhere in a view

			browser = 'Safari'
			@content = database_content

			my_widget = case browser
			when match(/Safari|Firefox|IE/)
				MyWidgetClass.new(@content).enrich(DesktopDecorator)
			else
				MyWidgetClass.new(@content).enrich(MobileDecorator)
			end
			expect(                      

			my_widget.render.split.join).to  eq(		# split.join used for comparison
				%{  
					<style>
					#MyWidget {
						font: 14px, helvetica; 
						width:600px; 
						height:200px 
					}
					</style>
					<div id='MyWidget'>car truck airplane boat</div>
				}.split.join
			)
			 
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
					1.50
				end
			  def brew
					@strategy = 'normal-'
			  end
			end

			injector :Sweedish do
				def brew
					@strategy = 'sweedish-'
				end
			end
			injector :French do
				def brew
					@strategy ='french-'
				end
			end

			cup = Coffee.new
			cup.brew
			cup.strategy.should == 'normal-'
			
			cup = Coffee.new.enrich(Sweedish())  # clobbers original strategy for this instance only
			cup.brew
			cup.strategy.should == ('sweedish-')
		
			cup.enrich(French())
			cup.brew
			cup.strategy.should == ('french-')
		end
		
		this 'can be further enhanced by mixing it with the above decorator pattern' do

			injector :Russian do
				def brew
					@strategy = super.to_s + 'vodka-'
				end
			end
			injector :Scotish do
				def brew
					@strategy = super.to_s + 'wiskey-'
				end
			end
			
			cup = Coffee.new
			cup.enrich(Russian()).enrich(Scotish()).enrich(Russian())
			cup.brew
			cup.strategy.should == 'normal-vodka-wiskey-vodka-'
			
		end
		
		it 'is even better or possible to have yet another implementation. This time we completely
		replace the current strategy by actually ejecting it out of the class and then injecting
		a new one' do
			
			class Tea < Coffee  # Tea is a type of coffee ;~Q)
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
			
			Tea.inject Sweedish()
			cup.brew
			friends_cup.brew
			cup.strategy.should == 'sweedish-'
			friends_cup.strategy.should == 'sweedish-'
			
			Tea.eject Sweedish()
			
			Tea.inject French()
			cup.brew
			friends_cup.brew
			cup.strategy == 'french-'
			friends_cup.strategy.should == 'french-'
			
		end
		
	end

	describe "further Jackbox Injector workflows" do
		
		it "allows adding decorators with function to be defined at later statge" do
			
			class Widget
				def cost
					1
				end
			end
			w = Widget.new
			
			injector :decorator
			w.enrich decorator, decorator, decorator, decorator
			
			# user input
			bid = 3.5 

			# define function
			decorator do
				# Global define
				define_method :cost do
					super() + bid
				end
			end
			
			w.cost.should == 15
			
		end
		
 		it "allows for the following workflow using super" do

			jack :Superb

			Superb do
				def process string, additives, index
					str = string.gsub('o', additives.slice!(index))
					super(string, additives, index) + str rescue str
				end
				extend Superb(), Superb(), Superb()
			end   

			Superb().process( 'food ', 'aeiu', 0 ).should == 'fuud fiid feed faad '
			Superb(:implode)

		end

		it 'allows for the following strategy workflow using soft tags' do  

			###########################################################################
			# For a specific example of what can be accomplished using this workflow  #
			# please refer to the examples directory under transformers spec          #
			#                                                                         #
			# #########################################################################
			
			jack :Solution

			Solution( :tag ) do
				def solution
					1
				end
			end
			Solution( :tag ) do
				def solution
					2
				end
			end
			Solution( :tag ) do
				def solution
					3
				end
			end
			

			class Client
				inject Solution()
				
				def self.solve
					Solution().tags.each { |e|
						update e 
						puts new.solution rescue nil
					}                              
					
					# or...
					
					solutions = Solution().tags.each
					begin
						update solutions.next
						puts solved = new().solution()
					end until solved
					solved
				end
				
			end

			$stdout.should_receive(:puts).with(1)
			$stdout.should_receive(:puts).with(2)
			$stdout.should_receive(:puts).with(3)
			$stdout.should_receive(:puts).with(1)
			
			Client.solve
			
		end
		
	end
	
	# describe 'use in rails' do
	# 	
	# 	it 'allows replacing draper'
	# 	it 'allows decorating anything not just models'
	# 	
	# end 

end

