require "spec_helper"


include Injectors

describe "the introspection api in further detail" do

	describe :injectors do
		
	  # . Name.injectors == [j,......]
	  # . Name.injectors.by_name == [:name, ......]
	  # . Name.injectors.sym_list == [:name, ......]
	  # . Name.injectors.collect_by_name(:name) == [j,......]  (default method)
	  #   . same as Name.injectors :name
	  # . Name.injectors.all_by_sym(:name) == [j,......]  (default method)
	  # . Name.injectors.find_by_name(:name) == j
	  # . Name.injectors.#Enumerable...
    
		describe "base injectors call" do
			
			before do
				class InjectorContainer
					injector :function
					injector :style
			
					inject function, style
				end
			end

			the 'base call returns now a list of actual injector objects' do

			  # . Name.injectors == [j,......]
		
				# class InjectorContainer
				# 	injector :function
				# 	injector :style
				# 	
				# 	inject function, style
				# end
		
				expect(InjectorContainer.injectors).to all( be_an(Injector))                       
				expect(InjectorContainer.injectors).to eql([InjectorContainer.function.history.last, InjectorContainer.style.history.last])
		
			end
	
			the 'injectors#by_name alias sym_list call now returns the list of injector symbols' do

			  # . Name.injectors.by_name == [:name, ......]
		
				# class InjectorContainer
				# 	injector :function
				# 	injector :style
				# 
				# 	inject function, style
				# end
	
				expect(InjectorContainer.injectors.by_name).to all( be_an(Symbol))
				expect(InjectorContainer.injectors.by_name).to eql([:function, :style])
				# alias
				expect(InjectorContainer.injectors.sym_list).to all( be_an(Symbol))
		
			end
	
			the 'injectors.collect_by_name returns a list of injector objects matching the name' do
	
				# class InjectorContainer
				# 	injector :function
				# 	injector :style
				# 
				# 	inject function, style
				# end

				ic = InjectorContainer.new
				ic.enrich InjectorContainer.style
				ic.injectors.by_name.should == [:function, :style, :style]
		
				# returns [Injector.name == :style, Injector.name == :style] only !!
				ic.injectors.collect_by_name(:style).should all(be_an(Injector).and have_attributes(:name => :style))
		
				# also aliased
				ic.injectors.all_by_sym(:style).should all(be_an(Injector).and have_attributes(:name => :style))
			end
	
			the 'injectors.find_by_name call returns one item of class Injector by name <sym>' do
		
				# class InjectorContainer
				# 	injector :function
				# 	injector :style
				# 
				# 	inject function, style
				# end

				ic = InjectorContainer.new
				ic.enrich InjectorContainer.style
	
				# result
				ic.injectors.by_name.should == [:function, :style, :style]
				ic.injectors.find_by_name(:style).should be_an(Injector).and( have_attributes(:name => :style))  # the last one !!!
		
				# also aliased
				ic.injectors.last_by_sym(:style).should be_an(Injector).and( have_attributes(:name => :style))  # the last one !!!
		
			end
	
			the 'default calls injectors :name/injectors :name, :othername, ... get resolved to the previous methods' do
		
				# class InjectorContainer
				# 	injector :function
				# 	injector :style
				# 
				# 	inject function, style
				# end

				ic = InjectorContainer.new
				ic.enrich InjectorContainer.style
	
				# result
				ic.injectors(:style).should eql(InjectorContainer.style.history.last)
				ic.injectors(:style, :style).should all(be_an(Injector).and have_attributes(:name => :style))
	
			end
		
		end

		describe '#injectors at the class singleton level' do

			the 'injectors applied at the class INSTANCE level show only on the class not the object instances' do

				injector :class_injector do
					def new *args
						puts "--done--"
						super(*args)
					end
				end

				class InjectorUser
					# ...
				end

				InjectorUser.extend class_injector

				$stdout.should_receive(:puts).with("--done--")
				iu = InjectorUser.new

				InjectorUser.injectors.size.should == 1
				InjectorUser.injectors.should all(be_an(Injector).and have_attributes(:name => :class_injector))

				if iu.respond_to? :injectors								# done to run this file independent of the others
					iu.injectors.should be_empty
				else
					expect{
						iu.injectors
					}.to raise_error(NoMethodError)
				end

			end

			the 'injector list for classes lists CLASS instance injectors first then OBJECT instance injectors' do

				injector :two
				injector :one

				Array.inject two 														# injected on objects of the class
				Array.extend one														# extended on the class instance itself

				# result

				Array.injectors.sym_list.should == [:one, :two]

			end

		end

		describe "#injectors(:all) call" do

			injector :Example1
			injector :Example2

			it 'returns all the injectors in the ancestor chain of an object' do

				Object.eject *Object.injectors rescue []  # clear all injectors from other tests

				Object.inject Example1()
				Hash.inject Example2()

				Hash.new.injectors(:all).should all(be_an(Injector))
				Hash.new.injectors(:all).map(&:spec).should eql [Example2(), Example1()]

				# as opposed to simple #injectors call
				Hash.new.injectors.map(&:spec).should eql [Example2()]

			end

			it 'returns all the injectors in the ancestors chain of a class' do

				# Object.eject *Object.injectors          	# clear all injectors from other tests

				class Aclass
					inject Example2()
				end

				Aclass.injectors(:all).should all(be_an(Injector))
				Aclass.injectors(:all).map(&:spec).should eql [Example2(), Example1()]

				# as opposed to simple #injectors call
				Aclass.new.injectors.map(&:spec).should eql [Example2()]

			end

			it 'returns all the injectors in the ancestors chain of a module' do

				module Amodule
					inject Example2() do
						include injector :Gone
					end
				end

				Amodule.injectors(:all).should all(be_an(Injector))
				Amodule.injectors(:all).map(&:spec).should eql [Example2(), Gone()]

				# as opposed to simple #injectors call
				Amodule.injectors.map(&:spec).should eql [Example2()]

			end

			it 'returns all the injectors in the ancestors chain of a Injector' do

				injector :Example1 do
					include injector :Example2 do
						include injector :Gone
					end
				end

				Example1().injectors(:all).should all(be_an(Injector)) 
				Example1().injectors(:all).map(&:spec).should eql [Example1(), Example2(), Gone()]

				# as opposed to simple #injectors call
				Example1().injectors.map(&:spec).should eql [Example2()]

			end

			it 'allows the rest of the api on the entire list' do

				Example1().injectors(:all).by_name.should == [:Example1, :Example2, :Gone] 
				Example1().injectors(:all).collect_by_name(:Gone).should all(be_an(Injector).and have_attributes(:name => :Gone))
				Example1().injectors(:all).find_by_name(:Example2).name.should == :Example2

			end
		end

	end

	describe :history do

		jack :Histample                  

		it 'does not show original jack' do 
			expect(Histample().history.first).to eq(nil)
		end 
		
		it "shows additional jacks after extended/included" do
			
			extend(Histample(), Histample())
			
			injectors.should == Histample().history

			expect(Histample().history.size).to eq(2)
			expect(Histample().history.last).to eql(Histample())
			expect(Histample().history.last).to_not eq(Histample().spec)
			
			eject *injectors
			
		end
		
		it "allows you to retreive items using an index" do
			
			extend Histample(), Histample()
			
			injectors.should == Histample().history

			expect(Histample().history.slice(0)).to be_instance_of(Injector)
			expect(Histample().history.slice(1)).to be_instance_of(Injector) 
			expect(Histample().history.slice(0)).to eq(Histample())
			expect(Histample().history.slice(1)).to eq(Histample()) 
			
			# values are different than spec
			
			expect(Histample().history.slice(0)).not_to eq(Histample().spec)
			expect(Histample().history.slice(1)).not_to eq(Histample().spec) 
			
			eject Histample(), Histample()
			
		end
		
		it 'swallows items once ejected' do
			
			extend(Histample(), Histample())
			
			expect(Histample().history.size).to eq(2)
			expect(Histample().history.last).to eql(Histample())
			expect(Histample().history.last).to_not eq(Histample().spec)
			
			eject *injectors
			
			expect(injectors).to be_empty  							# target injectors
			
			expect(Histample().history.size).to eq(0)    # Injector history
			expect(Histample().history.first).to eq(nil)
			expect(Histample().history.last).to eq(nil)
			
		end
		
		it 'swallows un-hosted elements other than original' do
			
			Histample() #un-hosted Histample 
			Histample() #un-hosted Histample
			
			expect(Histample().history.first).to eq(nil)
			expect(Histample().history.size).to eq(0)
			expect(Histample().history.last).to eq(nil)
			
		end
		
		it 'shows additional items upon inspection' do

			extend Histample()
			
			expect(Histample().history.size).to eq(1)
			expect(Histample().history.inspect).to match(/\[\(.+\|Histample\|\)\]/)
			
			eject Histample()
			
		end
		
		describe :precedent do

			it 'points to the previous injector in the history' do

				extend Histample(), Histample()

				injectors.should == Histample().history
				
				expect(Histample().history.last.precedent).to equal(Histample().history.first)
				expect(Histample().history.last.pre).to equal(injectors.first)
				expect(injectors.last.precedent).to equal(Histample().history.first)
				expect(injectors.last.pre).to equal(injectors.first)
				expect(Histample().history.first.precedent).to equal(Histample().spec)
				expect(injectors.first.precedent).to equal(Histample().spec)
				expect(Histample().spec.pre).to eq(nil) 
				
				eject *injectors

			end

			it 'has <nil> as the precedent to spec' do
        
				expect(Histample().precedent).to equal(Histample().spec)
				expect(Histample().spec.pre).to eq(nil) 
				expect(Histample().pre.pre).to eq(nil)
				
			end
			
		end
	end 
	
	describe :progenitor do

		before do
			injector :Progample
		end
		after do
			Progample(:implode)
		end

		it 'points to its progenitor: the version of injector generating it' do

			expect(Progample().history).to be_empty
			expect(Progample().progenitor).to equal(Progample().spec)

			extend Progample(), Progample()       
			
			expect(Progample().history.size).to eq(2)
			expect(Progample().history.first.progenitor).to equal(Progample().spec)
			expect(Progample().history.last.progenitor).to equal(Progample().spec)

			suppress_warnings do
				ProgenitorsTag = Progample()
			end

			expect(Progample().history.size).to eq(3)
			expect(Progample().history.first.progenitor).to equal(Progample().spec)
			expect(Progample().history.slice(1).progenitor).to equal(Progample().spec)
			expect(Progample().history.last.progenitor).to equal(Progample().spec)

			extend ProgenitorsTag

			expect(Progample().history.size).to eq(4)
			expect(Progample().history.last).to equal(injectors.last)
			 
			expect(Progample().history.last.progenitor).to equal(ProgenitorsTag) 
			expect(Progample().history.last.progenitor).to equal(Progample().history.slice(2)) 
			expect(Progample().history.slice(2).progenitor).to equal(Progample().spec)
			expect(Progample().history.slice(1).progenitor).to equal(Progample().spec)
			expect(Progample().history.first.progenitor).to equal(Progample().spec)
			expect(Progample().spec.progenitor).to equal(nil)
			expect(ProgenitorsTag.progenitor).to equal(Progample().spec)
			expect(ProgenitorsTag.progenitor.progenitor).to equal(nil)

			# eject *injectors

		end

		it 'should still pass' do

			suppress_warnings do
				ProgenitorsTag = Progample()
			end

			expect(Progample().history.size).to eq(1)
			expect(Progample().history.slice(0)).to equal(ProgenitorsTag)

			Progample(:tag) { 'some code'}       			# soft tag

			expect(Progample().history.size).to eq(2)
			expect(Progample().history.first).to equal(ProgenitorsTag)
			expect(Progample().history.last).to eq(Progample())
			expect(Progample().history.first.progenitor).to eq(Progample().spec)
			expect(Progample().history.last.progenitor).to eq(Progample().spec)
			expect(Progample().history.first.progenitor.progenitor).to eq(nil)
			expect(Progample().history.last.progenitor.progenitor).to eq(nil)
			expect(ProgenitorsTag.progenitor).to equal(Progample().spec)
			expect(ProgenitorsTag.progenitor.progenitor).to equal(nil)

			expect(Progample().tags.size).to eq(2)

		end

		it 'should pass' do
      
			suppress_warnings do
				ProgenitorsTag = Progample()
			end

			class ProgenitorTester1
				 include ProgenitorsTag
			end
			
			class ProgenitorTester2
				include *ProgenitorTester1.injectors
			end
			
			expect(ProgenitorTester2.injectors.first.progenitor).to equal(ProgenitorTester1.injectors.first)
			expect(ProgenitorTester1.injectors.first.progenitor).to equal(ProgenitorsTag)
			expect(ProgenitorsTag.progenitor).to equal(Progample().spec)  
			
			with ProgenitorTester1 do
				eject *injectors
			end
			
			expect(ProgenitorTester2.injectors.first.progenitor).to equal(ProgenitorsTag)
			expect(ProgenitorsTag.progenitor).to equal(Progample().spec)  

		end
		
	end 

	describe :lineage do 
		
		before do
			injector :Lineample
		end
		after do
			Lineample(:implode)
		end
		
		it 'collects all the progenitors of a line of injectors' do 
			
			LineagesTag = Lineample()

			class LineageTester1
				 include LineagesTag
			end
			
			class LineageTester2
				include *LineageTester1.injectors
			end
			
			expect(LineageTester2.injectors.first.progenitor).to equal(LineageTester1.injectors.first)
			expect(LineageTester1.injectors.first.progenitor).to equal(LineagesTag)
			expect(LineagesTag.progenitor).to equal(Lineample().spec)  
			
			expect(Lineample().lineage).to eq([Lineample().spec, Lineample()])
			expect(LineageTester2.injectors.first.lineage).to eq([Lineample().spec, LineagesTag, LineageTester1.injectors.first, LineageTester2.injectors.first])
			expect(Lineample().spec.lineage).to eq([Lineample().spec])
			expect(Lineample().spec.progenitor).to eq(nil)
			
		end

	end

	describe 'equality of Injectors' do
		
		before do
			injector :E
			injector :F
		end
		
		after do
			E(:implode)
			F(:implode)
		end
			 
		# For now this is how equality is defined
		describe 'equality' do
			
			it 'allows comparison between injectors' do
				
				E().should == E()
				E().should_not == E().spec
				
				E(:tag).should == E()
				ETag1 = E()
				ETag1.should == E()
				
				extend E()
				injectors.first.should == E()
				
				E() do
					def foo                   # ** definition **
					end
				end     
				
				E().should == E()
				ETag1.should_not == E()
				injectors.first.should_not == E()
				E(:tag).should == E()
				
				E().should_not == F()
				
			end
			
		end
		
		describe 'difference', :diff do
		
			it 'shows the difference between injectors' do
			  
				E().diff.should_not be_empty
				# because
				E().should_not == E().spec      # like above        
		
		
				##################################
				E().diff.should_not be_loaded
				# because
				E().diff.join.should be_empty
				E().diff.delta.should_not be_empty
		
		
				##################################
				E().diff(E()).should be_empty  	
				# because
				E().should == E()               # like above
				
				ETag2 = E()
				
		
				##################################
				E().diff(ETag2).should be_empty
				ETag2.diff(E()).should be_empty
				# because 
				ETag2.should == E() 						# like above
				
				E do
					def foo 									# ** definition **
					end
				end
				
		
				######################################
				E().diff(ETag2).should_not be_empty
				# because
			  ETag2.should_not == E()        # like above
				
				E().diff(ETag2).delta.should == [:foo]
				E().diff(ETag2).should be_loaded
				# because
				E().diff(ETag2).join.should == [:method_missing]
				# and
				E().diff(ETag2).delta.should == [:foo]
		             
		
				######################################
				E().diff.should be_loaded
				# because 
				E().diff.join.should == [:foo]
				E().diff.delta.should == [:method_missing]
				# because
				E().diff.should all( eql(E()) )		# eql? does not take method differences
				# and 
				E().diff.map(&:instance_methods).should == [[:foo], [:method_missing]]  
				# because
				E().instance_methods.should == [:foo, :method_missing]
				E().progenitor.instance_methods.should == [:foo]
				# being that
				E().progenitor.should equal(E().spec)
				
			end
		end
	
	end

end

