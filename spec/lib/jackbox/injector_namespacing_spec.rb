require "spec_helper"
=begin rdoc
	
	Name spacing of injectors
	Author: LHA



	Description of the difference between the different namespacing options of injectors:
	 
	injector :Main
				vs.
	injector :main

	module X
		injector :Some_Injector
							vs.
		injector :some_injector
	end

	class Y
		injector :Other_Injector
							vs.
		injector :other_injector
	end

=end


###########################
injector :Major
injector :minor            
###########################

# upper case vs lower case: semantically equivalent

describe 'Major vs minor' do
	

	example :Major do
		Major{
			lets(:bar) {|arg| arg * arg}
			lets(:far) {|arg| arg * arg * arg}
		}
		
		class Object
			inject Major()
		end
		
		Object.new.bar(3).should == 9
		Object.new.far(2).should == 8
		
		Object.eject Major()
	end
	
	example :minor do
		minor do
			lets(:bar) {|arg| arg * 3}
			lets(:far) {|arg| arg * arg * 3}
		end

		class Object 
			inject minor
		end
	
		Object.new.bar(3).should == 9
		Object.new.far(2).should == 12

		Object.eject minor
	end
	
end


###############################
module X
	injector :Maxi																	# use sparringly
	injector :mini
end
################################

# upper case vs lower case: semantically different
	
describe "X.Maxi vs X.mini" do
	
	# scoped globally: no matter where defined or accessed
	
	example 'X.Maxi' do
		Maxi{
			def bar
				:bar
			end
			def far
				:far
			end
		}

		class MaxiTester
			include Maxi()
		end
		
		MaxiTester.new.bar.should == :bar
		MaxiTester.new.far.should == :far
	end

	# scoped to module/class
	
	example 'X.mini' do
		expect{
			mini do
				def bar
					:barrr
				end
				def far
					:farrr
				end
			end
		}.to raise_error(NoMethodError) # not in scope
		
		X.mini do
			def bar
				:barrr
			end
			def far
				:farrr
			end
		end
		
		expect{
			class TesterFor_mini
				include mini
			end
		}.to raise_error(NameError) # not in scope
		
		class TesterFor_mini
			include X.mini
		end
		
		TesterFor_mini.new.bar.should == :barrr
		TesterFor_mini.new.far.should == :farrr
	end
end

############################# 
# Should follow the same line
# 
class Y
	injector :Other_Injector
						# vs.
	injector :other_injector
end
# 
# No example needed!!
############################## 
                             



# Tied to the idea of Injector Name Spaces is the one of Injector Version Naming/Tagging.  In order to make is easier to
# work with injector versions there is a need to tag/name the different versions for later use.
describe 'injector Tagging/Naming and its relationship to Injector Versioning' do
	
	there 'is way to tag/name a particular version for later reuse' do

		injector :Bar
		
		Tag = Bar do
			def foo_bar
				'a bar and foo'
			end
		end
		
		AnotherTag = Bar do
			def foo_bar
				'a foo and bar'
			end
		end
		

		class TaggerOne
			inject Tag																# first version
		end
		TaggerOne.new.foo_bar.should == 'a bar and foo'
		
		class TaggerTwo
			inject AnotherTag													# second version
		end
		TaggerTwo.new.foo_bar.should == 'a foo and bar'
		
		
		class TaggerThree
			inject Tag																# first version
		end
		TaggerThree.new.foo_bar.should == 'a bar and foo'
		
		class TaggerFour
			inject AnotherTag													# second version
		end
		TaggerFour.new.foo_bar.should == 'a foo and bar'
		
	end
	
	the 'following restriction applies to tags' do

		# cannot redefine tags
		
		SomeTag = Bar do
			def foo
				:foo
			end
		end
		
		expect{
			SomeTag do
				def foo
				end
			end
		}.to raise_error(NoMethodError)
		expect{
			SomeTag() {
				def foo
				end
			}
		}.to raise_error(NoMethodError)
		
		OtherTag = Bar do 			# This works!!
			def foo
				:oof
			end
		end 				# Bar is a true method 
		
		# This is consistent with the notion of a version:
		# the tag is a snapshot of the Injector at the point of creation
		# . once defined it shouldn't be modified
		# . to make modifications create a new version
		# The same tag can be applied to different targets or 
		# a new version created using the original Injector
		
		class TagsTester
			include SomeTag
		end
		
		TagsTester.new.foo.should == :foo
		
		# To update the version a target uses do a target.update
		
		class TagsTester
			update OtherTag
		end
		
		TagsTester.new.foo.should == :oof
		
	end

	it 'passes' do
		
		module M1
			jack :j1
		end
		
		module M2
			Atag = M1.j1
		end
		
		class A4 
			include M2::Atag
		end
		
		A4.ancestors.to_s.should match(/Atag/)       
		
		module M3
			module M4
				AnotherTag = M1.j1
			end
		end
		
		class B4
			include M3::M4::AnotherTag
		end
		
		A4.ancestors.to_s.should match(/Atag/) 
		B4.ancestors.to_s.should match(/AnotherTag/)
		
	end
	
	describe "soft tags" do
		
		it "is possible to create soft tags" do
			
			jack :some_jack
			
			some_jack :tag do
				def mith
					'King Arthur'
				end
			end
			
			some_jack :tag do
				def mith
					'Leprechauns'
				end
			end
			
			some_jack :tag do
				def mith
					'Tooth Fairy'
				end
			end
			
			some_jack.tags.size.should == 3
			       
			$stdout.should_receive(:puts).with("King Arthur")
			$stdout.should_receive(:puts).with("Leprechauns")
			$stdout.should_receive(:puts).with("Tooth Fairy")
			
			some_jack.tags.each { |t| 
				enrich t
				puts mith  
			}
			
		end
		
	end
end


