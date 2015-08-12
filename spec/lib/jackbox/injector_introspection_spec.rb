require "spec_helper"

include Injectors

describe "the introspection api in further detail" do

  # . Name.injectors == [j,......]
  # . Name.injectors.by_name == [:name, ......]
  # . Name.injectors.sym_list == [:name, ......]
  # . Name.injectors.collect_by_name(:name) == [j,......]  (default method)
  #   . same as Name.injectors :name
  # . Name.injectors.all_by_sym(:name) == [j,......]  (default method)
  # . Name.injectors.find_by_name(:name) == j
  # . Name.injectors.#Enumerable...

	the 'base call returns now a list of actual injector objects' do
  # . Name.injectors == [j,......]
		
		class InjectorContainer
			injector :function
			injector :style
			
			inject function, style
		end
		
		expect(InjectorContainer.injectors).to all( be_an(Injector))                       
		expect(InjectorContainer.injectors).to eql([InjectorContainer.function.history.last, InjectorContainer.style.history.last])
		
	end

	the 'injectors#by_name alias sym_list call now returns the list of injector symbols' do
  # . Name.injectors.by_name == [:name, ......]
		
		class InjectorContainer
			injector :function
			injector :style
		
			inject function, style
		end
	
		expect(InjectorContainer.injectors.by_name).to all( be_an(Symbol))
		expect(InjectorContainer.injectors.by_name).to eql([:function, :style])
		# alias
		expect(InjectorContainer.injectors.sym_list).to all( be_an(Symbol))
		
	end
	
	the 'injectors.collect_by_name returns a list of injector objects matching the name' do
	
		class InjectorContainer
			injector :function
			injector :style
		
			inject function, style
		end
		ic = InjectorContainer.new
		ic.enrich InjectorContainer.style
		ic.injectors.by_name.should == [:function, :style, :style]
		
		# returns [Injector.name == :style, Injector.name == :style] only !!
		ic.injectors.collect_by_name(:style).should all(be_an(Injector).and have_attributes(:name => :style))
		
		# also aliased
		ic.injectors.all_by_sym(:style).should all(be_an(Injector).and have_attributes(:name => :style))
	end
	
	the 'injectors.find_by_name call returns one item of class Injector by name <sym>' do
		
		class InjectorContainer
			injector :function
			injector :style
		
			inject function, style
		end
		ic = InjectorContainer.new
		ic.enrich InjectorContainer.style

		# result
		
		ic.injectors.by_name.should == [:function, :style, :style]
		ic.injectors.find_by_name(:style).should be_an(Injector).and( have_attributes(:name => :style))  # the last one !!!
		
		# also aliased
		ic.injectors.last_by_sym(:style).should be_an(Injector).and( have_attributes(:name => :style))  # the last one !!!
		
	end
	
	the 'default calls injectors :name/injectors :name, :othername, ... get resolved to the previous methods' do
		
		class InjectorContainer
			injector :function
			injector :style
		
			inject function, style
		end
		ic = InjectorContainer.new
		ic.enrich InjectorContainer.style

		# result
		
		ic.injectors(:style).should eql(InjectorContainer.style.history.last)
		ic.injectors(:style, :style).should all(be_an(Injector).and have_attributes(:name => :style))

	end
	
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
			}.to raise_error
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
	

	describe "history" do

		jack :Example3                  
		
		it 'does not show initial jack' do 
			expect(Example3().history.first).to eq(nil)
		end 

		it 'swallows un-hosted elements other than spec' do
			Example3() #un-hosted Example3 duplicated
			Example3() #un-hosted Example3 duplicated
			expect(Example3().history.first).to eq(nil)
			expect(Example3().history.size).to eq(0)
			expect(Example3().history.last).to eq(nil)
		end
		
		it "shows additional jacks after extended/included" do
			extend(Example3())
			expect(Example3().history.size).to eq(1)
			expect(Example3().history.last).to eql(Example3())
			expect(Example3().history.last).to_not eq(Example3().spec)
			eject Example3()
		end
		
		it 'swallows items once ejected' do
			extend(Example3())
			expect(Example3().history.size).to eq(1)
			expect(Example3().history.last).to eql(Example3())
			expect(Example3().history.last).to_not eq(Example3().spec)
			
			eject Example3()
			expect(Example3().history.size).to eq(0)
			expect(Example3().history.first).to eq(nil)
			expect(Example3().history.last).to eq(nil)
		end
		
		it 'shows additional items upon inspection' do
			extend Example3()
			expect(Example3().history.size).to eq(1)
			expect(Example3().history.inspect).to match(/\[\(.+\|Example3\|\)\]/)
			eject Example3()
		end
		
		it "allows you to retreive items using an index" do
			extend Example3(), Example3()
			expect(Example3().history.slice(0)).not_to eq(Example3().spec)
			expect(Example3().history.slice(1)).not_to eq(Example3().spec) 
			eject Example3(), Example3()
		end
		
	end
	
end

