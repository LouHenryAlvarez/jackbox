require "spec_helper"


include Injectors

describe "the introspection api in further detail" do

	describe :injectors do
		
		describe "base injectors call" do
    
		  # . Name.injectors == [j,......]
		  # . Name.injectors.by_name == [:name, ......]
		  # . Name.injectors.sym_list == [:name, ......]
		  # . Name.injectors.collect_by_name(:name) == [j,......]  (default method)
		  #   . same as Name.injectors :name
		  # . Name.injectors.all_by_sym(:name) == [j,......]  (default method)
		  # . Name.injectors.find_by_name(:name) == j
		  # . Name.injectors.#Enumerable...
			
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
		
				expect(InjectorContainer.injectors.by_name).to all( be_an(Symbol))
				expect(InjectorContainer.injectors.by_name).to eql([:function, :style])
				# alias
				expect(InjectorContainer.injectors.sym_list).to all( be_an(Symbol))
		
			end
	
			the 'injectors.collect_by_name returns a list of injector objects matching the name' do
	
			  # . Name.injectors.collect_by_name(:name) == [j,......]  (default method)

				ic = InjectorContainer.new
				ic.enrich InjectorContainer.style
				ic.injectors.by_name.should == [:style, :function, :style]
		
				# returns [Injector.name == :style, Injector.name == :style] only !!
				ic.injectors.collect_by_name(:style).should all(be_an(Injector).and have_attributes(:name => :style))
		
				# also aliased
				ic.injectors.all_by_sym(:style).should all(be_an(Injector).and have_attributes(:name => :style))
			end
	
			the 'injectors.find_by_name call returns one item of class Injector by name <sym>' do
		
			  # . Name.injectors.find_by_name(:name) == j

				ic = InjectorContainer.new
				ic.enrich InjectorContainer.style
	
				# result
				ic.injectors.by_name.should == [:style, :function, :style]
				ic.injectors.find_by_name(:style).should be_an(Injector).and( have_attributes(:name => :style))  # the last one !!!
		
				# also aliased
				ic.injectors.last_by_sym(:style).should be_an(Injector).and( have_attributes(:name => :style))  # the last one !!!
		
			end
	
			the 'default calls injectors :name/injectors :name, :othername, ... get resolved to the previous methods' do
		
			  # . Name.injectors.#Enumerable...

				ic = InjectorContainer.new
				ic.enrich InjectorContainer.style
	
				# result
				ic.injectors(:style).should eql(InjectorContainer.style.history.last)
				ic.injectors(:style, :style).should all(be_an(Injector).and have_attributes(:name => :style))
	
			end
		
		end


		describe "#injectors(:all) call" do

			before do
				injector :Example1
				injector :Example2
				Object.inject Example1()
			end
			
			after do
				Example1(:implode)
				Example2(:implode)
			end

			it 'returns all the injectors in the ancestor chain of an object' do

				# Object.eject *Object.injectors rescue []  # clear all injectors from other tests

				Hash.inject Example2()

				Hash.new.injectors(:all).should all(be_an(Injector))
				Hash.new.injectors(:all).should eql [Example2(), Example1()]  # from Object, and Hash

				# as opposed to simple #injectors call
				
				Hash.new.injectors.should eql [Example2()] # with no :all option

			end

			it 'with any class' do

				# Object.eject *Object.injectors          	# clear all injectors from other tests

				class AnyClass
					inject Example2()
				end

				AnyClass.injectors(:all).should all(be_an(Injector))
				AnyClass.injectors(:all).should eql [Example2(), Example1()]

				# as opposed to simple #injectors call
				
				AnyClass.new.injectors.should eql [Example2()]

			end

			it 'returns all the injectors in the ancestors chain of a module' do

				module AnyModule
					
					inject Example2() do
						include injector :Example3  		# compond injector
					end
					
				end

				AnyModule.injectors(:all).should all(be_an(Injector))
				AnyModule.injectors(:all).should eql [Example2(), Example3()]
				
				# as opposed to simple #injectors call
				
				AnyModule.injectors.should eql [Example2()]

			end

			it 'returns all the injectors in the ancestors chain of a Injector' do

				Example1 do
					
					include injector :Example2 do
						include injector :Example3					# triple compound injector
					end
					
				end

				Example1().injectors(:all).should all(be_an(Injector)) 
				Example1().injectors(:all).should eql [Example2(), Example3()]

				# as opposed to simple #injectors call
				
				Example1().injectors.should eql [Example2()]

			end

			it 'allows the rest of the api on the entire list' do

				Example1 do
					
					include injector :Example2 do
						include injector :Example3					# triple compound injector
					end
					
				end

				Example1().injectors(:all).by_name.should == [:Example2, :Example3] 
				Example1().injectors(:all).collect_by_name(:Example3).should all(be_an(Injector).and have_attributes(:name => :Example3))
				Example1().injectors(:all).find_by_name(:Example2).should == Example2()

			end
		end


		describe '#injectors at the class singleton level' do

			the 'injectors applied at the CLASS instance level, ie: using extend on the class, show up only on the CLASS instance not 
			its object instances and this only after using the :all directive like above' do

				injector :class_Instance_injector do
					def new *args
						puts "--done--"
						super(*args)
					end
				end

				class InjectorUser
					# ...
				end

				# extend the class singleton

				InjectorUser.extend class_Instance_injector					

				# run tests

				InjectorUser.injectors.size.should == 0		# not using the :all directive

				InjectorUser.injectors(:all).size.should == 1
				InjectorUser.injectors(:all).should all(be_an(Injector).and have_attributes(:name => :class_Instance_injector))

				# on the class instance

				$stdout.should_receive(:puts).with("--done--")
				
				iu = InjectorUser.new
				expect(iu.injectors).to be_empty
				expect(iu.injectors(:all)).to be_empty

			end

			the ':all injector list for classes lists CLASS instance injectors first and then OBJECT instance injectors' do

				injector :two
				injector :one

				Array.inject two 														# injected on objects of the class
				Array.extend one														# extended on the class instance itself

				# result

				Array.injectors(:all).sym_list.should == [:one, :two]
				
				Array.new.injectors.sym_list.should == [:two] 	# :one is member of Array.singleton_class 
																												# and does not become part of Array.instances
			end

		end
	end


	describe :history do

		
		jack :Histample
		             

		it 'does not show original jack' do 
			expect(Histample().history.first).to eq(nil)
		end 
		
		it "shows additional jacks once hosted, i.e.: after extend/include" do
			
			extend(Histample(), Histample())					# host two items
			
			injectors.should == Histample().history		# equal at this point

			expect(Histample().history.size).to eq(2)
			expect(Histample().history.last).to eql(injectors.last)
			expect(Histample().history.first).to eq(injectors.first)
			expect(injectors.size).to eq(2)
			
			eject *injectors
			
		end
		
		it "allows you to retreive items using an index" do
			
			extend Histample(), Histample()
			
			injectors.should == Histample().history

			expect(Histample().history.slice(0)).to be_instance_of(Injector)
			expect(Histample().history.slice(1)).to be_instance_of(Injector) 
			
			eject Histample(), Histample()
			
		end
		
		it 'swallows items once ejected' do
			
			extend(Histample(), Histample())
			
			injectors.should == Histample().history

			expect(Histample().history.size).to eq(2)
			expect(injectors.size).to eq(2)
			
			eject *injectors
			
			expect(injectors).to be_empty  							# target injectors
			expect(Histample().history).to be_empty			# Injector history
			
		end
		
		it 'swallows un-hosted elements other than original one' do
			
			Histample() #un-hosted Histample 
			Histample() #un-hosted Histample
			
			expect(Histample().history.size).to eq(0)
			
		end
		
		it 'shows hosted items upon inspection' do

			extend Histample()
			
			expect(Histample().history.inspect).to match(/\[\(\|Histample\|.+\)\]/)
			expect(Histample().history.size).to eq(1)
			
			eject Histample()
			
		end
		
		describe :precedent do

			it 'points to the previous injector in the history' do

				extend Histample(), Histample()
				
				# Given that
				injectors.should == Histample().history
				
				# Then 
				expect(Histample().history.last.precedent).to equal(Histample().history.first)
				expect(Histample().history.last.pre).to equal(injectors.first)
				expect(injectors.last.precedent).to equal(Histample().history.first)
				expect(injectors.last.pre).to equal(injectors.first)
				
				eject *injectors
				
			end
			
			it 'has spec as the first precedent' do
				
				extend Histample(), Histample()
				
				injectors.should == Histample().history
				
				expect(Histample().history.first.precedent).to equal(Histample().spec)
				expect(injectors.first.precedent).to equal(Histample().spec)
				
				eject *injectors

			end
			
			# but then... aka: its a circular list

			it 'has the latest version as the precedent to spec' do
				
				extend Histample(), Histample()
				
				injectors.should == Histample().history
				
				expect(Histample().history.first.precedent).to equal(Histample().spec)
				expect(Histample().precedent.pre.pre).to equal(Histample().spec)
				expect(Histample().spec.pre).to eq(Histample().history.last) 
				
				eject *injectors
				
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

			# apply the injector
			
			extend Progample(), Progample()       
			
			expect(Progample().history.size).to eq(2)
			
			
			# both generated form spec
			
			expect(Progample().history.first.progenitor).to equal(Progample().spec)
			expect(Progample().history.last.progenitor).to equal(Progample().spec)


			# create a tag
			
			suppress_warnings do # used because of rspec
				ProgenitorsTag = Progample()
			end

			expect(Progample().history.size).to eq(3)
			
			expect(Progample().history.first.progenitor).to equal(Progample().spec)
			expect(Progample().history.last).to equal(ProgenitorsTag)
			expect(Progample().history.last.progenitor).to equal(Progample().spec)
			expect(ProgenitorsTag.progenitor).to equal(Progample().spec)


			# apply the tag
			
			extend ProgenitorsTag

			expect(Progample().history.size).to eq(4)
			expect(Progample().history.last).to equal(injectors.first)
			 
			expect(Progample().history.last.progenitor).to equal(ProgenitorsTag) 
			expect(Progample().history.first.progenitor).to equal(Progample().spec)

		end
		
		it 'points the last progenitor to nil' do
			
			expect(Progample().spec.progenitor).to equal(nil)

		end

		it 'works the same with soft tags' do

			suppress_warnings do
				ProgenitorsTag = Progample()
			end

			expect(Progample().history.size).to eq(1)


			# soft tag
			# debugger
			Progample(:tag) { 'some code'}       			

			expect(Progample().history.size).to eq(2)

			# progenitors are the same
			
			expect(Progample().history.first.progenitor).to eq(Progample().spec)
			expect(Progample().history.last.progenitor).to eq(Progample().spec)
			expect(Progample().history.first.progenitor.progenitor).to eq(nil)
			expect(Progample().history.last.progenitor.progenitor).to eq(nil)

			# tags call
			
			expect(Progample().tags.size).to eq(2)

		end

		it 'carries on the metaphor with injectors are shared from other objects' do
      
			suppress_warnings do
				ProgenitorsTag = Progample()
			end

			class ProgenitorTester1
				 include ProgenitorsTag
			end
			
			class ProgenitorTester2
				include *ProgenitorTester1.injectors   # copying injectors from second class
			end
			
			expect(ProgenitorTester2.injectors.first.progenitor).to equal(ProgenitorTester1.injectors.first)
			expect(ProgenitorTester1.injectors.first.progenitor).to equal(ProgenitorsTag)
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
		describe 'equality and inequality' do
			
			it 'allows comparison between injectors' do
				
				# equality
				##################################
				E().should == E()
				E().should == E().spec
				
				E(:tag).should == E()
				if ETag1 = E()
					ETag1.should == E()
				end
				extend E()
				injectors.first.should == E()
				
				
				# ** definition **
				E() do
					def foo                   
					end
				end     
				# ** definition **


				# inequality
				##################################
				E().should == E()
				ETag1.should_not == E()
				injectors.first.should_not == E()
				
				E(:tag).should == E()
				E().should_not == F()
				
			end
			
		end
		
		describe :diff do
		
			it 'shows the difference between injectors' do

				E().diff.class.should be(Array)

				# equality in the converse expression
				##################################
				# debugger
				E().diff(E()).should be_empty  	

				# because
				E().should == E()               # like above
				
				
			  # unless changed E should be == E().pre or E().spec
				##################################
				E().diff.should be_empty

				# because
				E().diff.should == E().diff(E().pre)        
				E().pre.should equal( E().spec )
				# and
				E().should == E().spec      # like above
		
		
				# unless there is a delta it cannot be loaded?
				##################################
				E().diff.should_not be_loaded

				# because
				E().diff.delta.should be_empty
		

				# tags are the same
				##################################
				ETag2 = E()
				
				E().diff(ETag2).should be_empty
				ETag2.diff(E()).should be_empty

				# because 
				ETag2.should == E() 						
				E().should == ETag2 						# like above
				
			end
				
			it 'differs once a definition is present' do
				
				# a tag to compare
				##################################
				ETag3 = E()


				# ** definition **
				E do
					def foo 									
					end
				end
				# ** definition **


				# E is changed so...
				####################################
				E().diff(ETag3).should_not be_empty

				# because
			  ETag3.should_not == E() 
				# and
				E().diff(ETag3).delta.should == [:foo]
				
				
				# Still not loaded
				##################################
				E().diff(ETag3).should_not be_loaded

				# because
				E().diff(ETag3).join.should == []
				# even though
				E().diff(ETag3).delta.should == [:foo]
		             

				# conversely
				######################################
				E().diff.join.should == [:foo]
				# and
				E().diff.delta.should == []

				# because 
				E().diff.should_not be_loaded
				# and
				E().diff.should == [[:foo], []] 
				 
				# being that
				E().diff.should eq( E().diff(E().progenitor) )
				E().progenitor.should equal(E().spec)
				
			end
			
			it 'works with more methods' do
			
				# a tag to compare
				##################################
				ETag4 = E()


				# ** definition **
				E do
					def foo 									
					end
					def bar
					end
				end
				# ** definition **


				#
				##################################
				E().diff(ETag4).join.should == []
				E().diff(ETag4).delta.should == [:foo, :bar]
				E().diff.join.should == [:foo, :bar]
				E().diff.delta.should == []
				
				# being that
				E().diff.should eq( E().diff( E().progenitor) )
				E().progenitor.should equal( E().spec )
				
			end
			
			it 'creates injectors for inclusion' do
				
				# a tag to compare
				##################################
				ETag5 = E()


				# ** definition **
				E do
					def foo 									
					end
					def bar
					end
				end
				# ** definition **


				E().diff.should be_empty
				E().diff.join.should_not be_empty
				E().diff.delta.should be_empty
				E().diff.delta.injector.should_not eq(E().diff.join.injector)
				
			end
			
		end
	
	end

end

