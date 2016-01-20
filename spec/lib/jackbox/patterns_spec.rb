require "spec_helper"

=begin rdoc
	This file contains the specs for the GOF Decorator Pattern and 
	Strategy Pattern use cases for traits.
=end

include Injectors

describe 'some use cases', :traits do 

	describe 'GOF Decortors is one use of this codebase. Traditionally this is only partially solved in Ruby through PORO 
	decorators or the use of modules with the problems of loss of class identity for the former 
	or the limitations on the times it can be re-applied for the latter. We solve that!!' do 
	
		the 'GOF class decorator' do

			class Coffee
				def cost
					1.50
				end
			end
			
			# debugger
			trait :milk do
				def cost
					super() + 0.30
				end
			end
			trait :vanilla do
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
			cup.traits.sym_list.should == [:vanilla, :vanilla, :milk]
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
			cup.traits.sym_list.should == [:vanilla, :vanilla, :milk]
			cup.cost.should == 2.10
			cup.appearance.should == 'extra red vanilla'
			
		end
		
		a 'bigger example using normal Injector inheritance on web rendering' do
		             
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

			trait :WidgetDecorator do
				attr_reader :width, :height       

				def dim(width, heigth)
					@width, @heigth = width, heigth
				end
			end

			DesktopDecorator = WidgetDecorator do
				def render
					dim '600px', '200px'										# inherited
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
					dim '200px', '600px'										# inherited
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
			
			# apply the decorators

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
			 
			WidgetDecorator(:implode)
			
		end

		a 'different way of doing it using: JIT inheritance' do
		             
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

			
			MainDecorator = trait :WidgetDecorator do
				
				attr_accessor :font, :width, :height       

				def dim(width, heigth)
					@width, @heigth = width, heigth
				end
				
				def render
					%{
						<style>
						#MyWidget{
							font: 14px, #{@font};
							width:#{@width};
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
				# debugger
				MyWidgetClass.new(@content).enrich(WidgetDecorator() do
					
					def render															# override invoking JIT inheritance
						dim '600px', '200px'									# normal inherited method call
						@font = 'helvetica'

						super()
					end
				end)

			else
				MyWidgetClass.new(@content).enrich(WidgetDecorator() do
					
					def render															# override invoking JIT inheritance
						dim '200px', '600px'                  # normal inherited method call
						@font ='arial'

						super()
					end
				end)
			end

			# expect(WidgetDecorator().ancestors).to eq([WidgetDecorator(), MainDecorator])

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

			
			browser = 'mobile'
			@content = database_content
			
			my_widget = case browser
			when match(/Safari|Firefox|IE/)
				# debugger
				MyWidgetClass.new(@content).enrich(WidgetDecorator() do
					
					def render
						dim '600px', '200px'
						@font ='helvetica'
			
						super()
					end
				end)
			else
				MyWidgetClass.new(@content).enrich(WidgetDecorator() do
					def render
						dim '200px', '600px'
						@font ='arial'
			
						super()
					end
				end)
			end
			expect(                      
			
				my_widget.render.split.join).to  eq(		# split.join used for comparison
					%{  
						<style>
						#MyWidget {
							font: 14px, arial; 
							width:200px; 
							height:600px 
						}
						</style>
						<div id='MyWidget'>car truck airplane boat</div>
					}.split.join
			)
			
			WidgetDecorator(:implode)
			 
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

			trait :Sweedish do
				def brew
					@strategy = 'sweedish-'
				end
			end
			trait :French do
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

			trait :Russian do
				def brew
					@strategy = super.to_s + 'vodka-'
				end
			end
			trait :Scotish do
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
				trait :SpecialStrategy do
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
		
		describe 'Delayed Decorator pattern'do
			it "allows adding decorators with function to be defined at later statge" do
			
				class Widget
					def cost
						1
					end
				end
				w = Widget.new
			
				trait :decorator
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
		end
		
		describe 'Super pattern (no its not a superlative pattern)' do
	 		it "allows self-terminating recursion workflow using super" do

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
		end
		
		describe 'Solutions Pattern' do
			it 'allows trying several solutions in workflow using soft tags' do  

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

		describe "jiti as decorators with internal base" do
			before do
				JD1 = trait :jd do
					def m1
						1
					end
				end
				JD2 = jd do
					def m1
						super + 2
					end
				end
			end
			it 'works like normal decorators' do

				o = Object.new
				o.enrich JD2, JD1
				o.m1.should == 3
				
				p = Object.new
				p.enrich JD1, JD2
				p.m1.should == 1
				
			end
			
			it 'raise errors on decorator collusions' do
				
				expect{
					
					r = Object.new
					r.enrich JD1, JD1
					r.m1.should == 1
				
				}.to raise_error(ArgumentError)
				expect{
					
					q = Object.new
					q.enrich JD2, JD2
					q.m1.should == 5
				
				}.to raise_error(ArgumentError)
				
			end
		end
		
		describe "jiti as decorators on external base" do
			before do
				JD1 = trait :jd do
					def m1
						super + 1
					end
				end
				JD2 = jd do
					def m1
						super + 2
					end
				end
				class JDClass
					def m1
						1
					end
				end
			end
			
			it 'can work like normal decorators' do

				o = JDClass.new
				o.enrich JD2, JD1
				o.m1.should == 5
				
				p = JDClass.new
				p.enrich JD1, JD2
				p.m1.should == 5

			end
			
			it 'raises errors on decorator collusions' do
				
				expect{
					
					r = JDClass.new
					r.enrich JD1, JD1
					r.m1.should == 3
				
				}.to raise_error(ArgumentError)
				expect{
					
					q = JDClass.new
					q.enrich JD2, JD2
					q.m1.should == 6

				}.to raise_error(ArgumentError)
				
			end
		end

	end
end

