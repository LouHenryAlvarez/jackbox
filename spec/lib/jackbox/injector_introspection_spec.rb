require "spec_helper"


include Injectors

describe "the introspection api in further detail" do

	describe :traits do
		
		describe "base traits call" do
    
		  # . Name.traits == [j,......]
		  # . Name.traits.by_name == [:name, ......]
		  # . Name.traits.sym_list == [:name, ......]
		  # . Name.traits.collect_by_name(:name) == [j,......]  (default method)
		  #   . same as Name.traits :name
		  # . Name.traits.all_by_sym(:name) == [j,......]  (default method)
		  # . Name.traits.find_by_name(:name) == j
		  # . Name.traits.#Enumerable...
			
			before do
				class InjectorContainer
					trait :function
					trait :style
			
					inject function, style
				end
			end

			the 'base call returns now a list of actual trait objects' do

			  # . Name.traits == [j,......]
		
				# class InjectorContainer
				# 	trait :function
				# 	trait :style
				# 	
				# 	inject function, style
				# end
		
				expect(InjectorContainer.traits).to all( be_an(Injector))                       
				expect(InjectorContainer.traits).to eql([InjectorContainer.function.history.last, InjectorContainer.style.history.last])
		
			end
	
			the 'traits#by_name alias sym_list call now returns the list of trait symbols' do

			  # . Name.traits.by_name == [:name, ......]
		
				expect(InjectorContainer.traits.by_name).to all( be_an(Symbol))
				expect(InjectorContainer.traits.by_name).to eql([:function, :style])
				# alias
				expect(InjectorContainer.traits.sym_list).to all( be_an(Symbol))
		
			end
	
			the 'traits.collect_by_name returns a list of trait objects matching the name' do
	
			  # . Name.traits.collect_by_name(:name) == [j,......]  (default method)

				ic = InjectorContainer.new
				ic.enrich InjectorContainer.style
				ic.traits.by_name.should == [:style, :function, :style]
		
				# returns [Injector.name == :style, Injector.name == :style] only !!
				ic.traits.collect_by_name(:style).should all(be_an(Injector).and have_attributes(:name => :style))
		
				# also aliased
				ic.traits.all_by_sym(:style).should all(be_an(Injector).and have_attributes(:name => :style))
			end
	
			the 'traits.find_by_name call returns one item of class Injector by name <sym>' do
		
			  # . Name.traits.find_by_name(:name) == j

				ic = InjectorContainer.new
				ic.enrich InjectorContainer.style
	
				# result
				ic.traits.by_name.should == [:style, :function, :style]
				ic.traits.find_by_name(:style).should be_an(Injector).and( have_attributes(:name => :style))  # the last one !!!
		
				# also aliased
				ic.traits.last_by_sym(:style).should be_an(Injector).and( have_attributes(:name => :style))  # the last one !!!
		
			end
	
			the 'default calls traits :name/traits :name, :othername, ... get resolved to the previous methods' do
		
			  # . Name.traits.#Enumerable...

				ic = InjectorContainer.new
				ic.enrich InjectorContainer.style
	
				# result
				ic.traits(:style).should eql(InjectorContainer.style.history.last)
				ic.traits(:style, :style).should all(be_an(Injector).and have_attributes(:name => :style))
	
			end
		
		end


		describe "#traits(:all) call" do

			before do
				trait :Example1
				trait :Example2
				Object.inject Example1()
			end
			
			after do
				Example1(:implode)
				Example2(:implode)
			end

			it 'returns all the traits in the ancestor chain of an object' do

				# Object.eject *Object.traits rescue []  # clear all traits from other tests

				Hash.inject Example2()

				Hash.new.traits(:all).should all(be_an(Injector))
				Hash.new.traits(:all).should eql [Example2(), Example1()]  # from Object, and Hash

				# as opposed to simple #traits call
				
				Hash.new.traits.should eql [Example2()] # with no :all option

			end

			it 'with any class' do

				# Object.eject *Object.traits          	# clear all traits from other tests

				class AnyClass
					inject Example2()
				end

				AnyClass.traits(:all).should all(be_an(Injector))
				AnyClass.traits(:all).should eql [Example2(), Example1()]

				# as opposed to simple #traits call
				
				AnyClass.new.traits.should eql [Example2()]

			end

			it 'returns all the traits in the ancestors chain of a module' do

				module AnyModule
					
					inject Example2() do
						include trait :Example3  		# compond trait
					end
					
				end

				AnyModule.traits(:all).should all(be_an(Injector))
				AnyModule.traits(:all).should eql [Example2(), Example3()]
				
				# as opposed to simple #traits call
				
				AnyModule.traits.should eql [Example2()]

			end

			it 'returns all the traits in the ancestors chain of a Injector' do

				Example1 do
					
					include trait :Example2 do
						include trait :Example3					# triple compound trait
					end
					
				end

				Example1().traits(:all).should all(be_an(Injector)) 
				Example1().traits(:all).should eql [Example2(), Example3()]

				# as opposed to simple #traits call
				
				Example1().traits.should eql [Example2()]

			end

			it 'allows the rest of the api on the entire list' do

				Example1 do
					
					include trait :Example2 do
						include trait :Example3					# triple compound trait
					end
					
				end

				Example1().traits(:all).by_name.should == [:Example2, :Example3] 
				Example1().traits(:all).collect_by_name(:Example3).should all(be_an(Injector).and have_attributes(:name => :Example3))
				Example1().traits(:all).find_by_name(:Example2).should == Example2()

			end
		end


		describe '#traits at the class singleton level' do

			the 'traits applied at the CLASS instance level, ie: using extend on the class, show up only on the CLASS instance not 
			its object instances and this only after using the :all directive like above' do

				trait :class_Instance_trait do
					def new *args
						puts "--done--"
						super(*args)
					end
				end

				class InjectorUser
					# ...
				end

				# extend the class singleton

				InjectorUser.extend class_Instance_trait					

				# run tests

				InjectorUser.traits.size.should == 0		# not using the :all directive

				InjectorUser.traits(:all).size.should == 1
				InjectorUser.traits(:all).should all(be_an(Injector).and have_attributes(:name => :class_Instance_trait))

				# on the class instance

				$stdout.should_receive(:puts).with("--done--")
				
				iu = InjectorUser.new
				expect(iu.traits).to be_empty
				expect(iu.traits(:all)).to be_empty

			end

			the ':all option lists CLASS instance traits first and then OBJECT instance traits' do

				trait :two
				trait :one

				Array.inject two 														# injected on objects of the class
				Array.extend one														# extended on the class instance itself

				# result

				Array.traits(:all).sym_list.should == [:one, :two]
				
				Array.new.traits.sym_list.should == [:two] 	# :one is member of Array.singleton_class 
																										# and does not become part of Array.instances
			end
			
			it 'also works on injector instances' do
				
				trait :a, :b
				
				a do
					def foo
						:foo
					end
				end
				o = Object.new.extend(a)
				o.foo.should == :foo
				
				b do
					def faa
						:faa
					end
				end
				a.extend b
				a.faa.should == :faa
				
			end

		end
	end


	describe :history, '#versions' do

		
		jack :Hsample
		             

		it 'does not show original jack' do 
			expect(Hsample().history.first).to eq(nil)
		end 
		
		it "shows additional jacks once hosted, i.e.: after extend/include" do
			
			extend(Hsample(), Hsample())					# host two items
			
			traits.should == Hsample().history		# equal at this point

			expect(Hsample().history.size).to eq(2)
			expect(Hsample().history.last).to eql(traits.last)
			expect(Hsample().history.first).to eq(traits.first)
			expect(traits.size).to eq(2)
			
			eject *traits
			
		end
		
		it "allows you to retreive items using an index" do
			
			extend Hsample(), Hsample()
			
			traits.should == Hsample().history

			expect(Hsample().history.slice(0)).to be_instance_of(Injector)
			expect(Hsample().history.slice(1)).to be_instance_of(Injector) 
			
			eject Hsample(), Hsample()
			
		end
		
		it 'swallows items once ejected' do
			
			extend(Hsample(), Hsample())
			
			traits.should == Hsample().history

			expect(Hsample().history.size).to eq(2)
			expect(traits.size).to eq(2)
			
			eject *traits
			
			expect(traits).to be_empty  							# target traits
			expect(Hsample().history).to be_empty			# Injector history
			
		end
		
		it 'swallows un-hosted elements other than original one' do
			
			Hsample() #un-hosted Hsample 
			Hsample() #un-hosted Hsample
			
			expect(Hsample().history.size).to eq(0)
			
		end
		
		it 'shows hosted items upon inspection' do

			extend Hsample()
			
			expect(Hsample().history.inspect).to match(/\[\(\|Hsample\|.+\)\]/)
			expect(Hsample().history.size).to eq(1)
			
			eject Hsample()
			
		end
		
		describe '#versions/#history under JITY' do
			before do
				trait :One
				
				suppress_warnings do
					OneTag = One do
						def foo
							'foo'
						end
					end
				end
				
				One do
					def foo
						super
					end
				end
				
			end
			
			after do
				suppress_warnings do
					OneTag = nil
				end
				
				One(:implode)
			end
			
				
			it 'should only have one version' do
				
				One().versions.size.should == 1 # OneTag
				One().versions.should == [OneTag]
			end
		end
		
		describe :precedent do

			it 'points to the previous trait in the history' do

				extend Hsample(), Hsample()
				
				# Given that
				traits.should == Hsample().history
				
				# Then 
				expect(Hsample().history.last.precedent).to equal(Hsample().history.first)
				expect(Hsample().history.last.pre).to equal(traits.first)
				expect(traits.last.precedent).to equal(Hsample().history.first)
				expect(traits.last.pre).to equal(traits.first)
				
				eject *traits
				
			end
			
			it 'has spec as the first precedent' do
				
				extend Hsample(), Hsample()
				
				traits.should == Hsample().history
				
				expect(Hsample().history.first.precedent).to equal(Hsample().spec)
				expect(traits.first.precedent).to equal(Hsample().spec)
				
				eject *traits

			end
			
			# but then... aka: its a circular list

			it 'has the latest version as the precedent to spec' do
				
				extend Hsample(), Hsample()
				
				traits.should == Hsample().history
				
				expect(Hsample().history.first.precedent).to equal(Hsample().spec)
				expect(Hsample().precedent.pre.pre).to equal(Hsample().spec)
				expect(Hsample().spec.pre).to eq(Hsample().history.last) 
				
				eject *traits
				
			end
			
		end
	end 
	
	describe 'equality of Injectors' do
		
		before do
			trait :E
			trait :F
		end
		
		after do
			E(:implode)
			F(:implode)
		end
			 
		# For now this is how equality is defined
		describe 'equality and inequality' do
			
			it 'allows comparison between traits' do
				
				# equality
				##################################
				
				E().should == E()
				E().should == E().spec
				E().should == E().pre
				
				# if
				ETag1 = E()											# with no definitions
				# then
				E().should == ETag1							# same thing
				
				# if
				extend E()											# with no definitions
				# then
				traits.first.should == E()		# same
				
				# but
				E().should == E() 							# always
				E().should == E().spec 					
				E(:tag).should == E()	
				
				# inequality
				##################################
		    
				E().should_not eql F()

		    # if E () definitions **
		    E() do
		    	def foo                   
		    	end
		    end     

		    # then (from above)
		    ETag1.should_not == E()         

		    # furthermore
		    traits.first.should_not == E()
		
		    # and
		    E().should_not == E().pre
		
				# but
		    E().should == E()								# always
				E().should == E().spec

			end
			
			it 'has case equality showing its presence in an instance' do
				
				o = Object.new.extend E()
				
				E().should === o
				
				case E()
				when o
					should be_true
				end
				
			end
			
		end
		
		describe :diff do
			
			it 'corroborates equality' do

				# equality in the converse expression
				##################################
				E().diff(E()).should be_empty  	

				# because
				E().should == E()               # like above
				
				
			  # unless changed 
				E().diff.should be_empty

				# because
				E().diff.should == E().diff(E().pre)        
				E().pre.should equal( E().spec )
				# and
				E().should == E().spec      # like above
				# also
				E().diff.should_not be_loaded
				# because
				E().diff.delta.should be_empty
		

				# tags are the same
				ETag2 = E()
				
				E().diff(ETag2).should be_empty
				ETag2.diff(E()).should be_empty

				# because 
				ETag2.should == E() 						
				E().should == ETag2 						# like above
				
			end
				
			it 'differs once injector specalization is present' do
				
		    # difference
		    ##################################

		    #diff(ver=nil)  --( The argument ver=nil defaults to the previous version )

		      E().diff.class.should be(Array)


		    #diff.empty?  --( Is the delta empty? The join could still exist (see below). )

		      E().diff.should be_empty


		      # because
		      E().diff.delta.should be_empty
		      E().diff.join.should be_empty


		      # a tag to compare
		      ETag3 = E()


		      # if some E() definitions **
		      E do
		      	def foo 									
		      	end
		      end


		      # E is changed so...
		      E().diff(ETag3).should_not be_empty


		      # because (like above)
		      ETag3.should_not == E() 

		      # and


		    #diff.delta  --( The difference in methods )

		      E().diff(ETag3).delta.should == [:foo]


		    #diff.loaded? --( Is there both a join and a delta? )

		      E().diff(ETag3).should_not be_loaded

		      # because


		    #diff.join  --( The methods common to both )

		      E().diff(ETag3).join.should == []


		      # even though
		      E().diff(ETag3).delta.should == [:foo]


		      # furthermore
		      E().diff.should == [[], [:foo]] 


		      # being that
		      E().diff.should eq( E().diff(E().precedent) )
		      # and
		      E().progenitor.should equal(E().spec)
				
			end
			
			it 'continues to work with expansion' do
			
				# a tag as precedent
				ETag4 = E()


				# if more E() definitions **
				E do
					def foo 									
					end
					def bar
					end
				end


				# then
				E().diff(ETag4).join.should == []
				E().diff(ETag4).delta.should == [:foo, :bar]
				E().diff.join.should == []
				E().diff.delta.should == [:foo, :bar]
				
				# being that
				E().diff.should eq( E().diff( E().precedent) )
				E().progenitor.should equal( E().spec )
				
			end
			
			it 'exposes join and delta sub-traits for inclusion/extension' do
				
	  		# a tag as precedent
	  		ETag5 = E()


	  		# if E() definitions **
	  		E do
	  			def foo
	  				:foo
	  			end
	  			def bar
	  				:bar
	  			end
	  		end


	  		# then 
	  		E().diff.should_not be_empty

	  		# being that
	  		E().diff.join.should be_empty
	  		E().diff.delta.should_not be_empty
	  		# as for
	  		E().diff.delta.injector.instance_methods.should == [:foo, :bar]
	  		# and
	  		E().diff.delta.injector.should_not eq(E().diff.join.injector)

	  		# being that
	  		E().diff.join.injector.instance_methods.should be_empty
	  		E().diff.delta.injector.instance_methods.should_not be_empty

	  		# allows the following
	  		class Incomplete
	  			inject E().diff.delta.injector
	  		end
	  		# and
	  		Incomplete.new.foo.should eq(:foo)

				# being that
				E().diff.delta.injector.should be_instance_of(Injector)
				E().diff.delta.injector.should be_instance_of(Trait)
				
			end
			
			it 'accepts a negative index' do
				
				extend E(), E(), E()
				
				E() do
					def foo
					end
				end
				
				E().diff( -1 ).should == [[],[:foo]]
				E().diff( -3 ).should == [[],[:foo]]
				E().diff( -4 ).should == [[:foo], []] # self
				
			end
			
		end
	end

end

