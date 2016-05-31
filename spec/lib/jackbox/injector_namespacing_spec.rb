require "spec_helper"
=begin rdoc
	
	Name spacing of traits
	Author: LHA



	Description of the difference between the different namespacing options of traits:
	 
	trait :Main
				vs.
	trait :main

	module X
		trait :Some_Injector
							vs.
		trait :some_trait
	end

	class Y
		trait :Other_Injector
							vs.
		trait :other_trait
	end

=end

###########################
trait :Major
trait :minor            
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
	trait :Maxi																	# use sparringly
	trait :mini
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
	trait :Other_Injector
						# vs.
	trait :other_trait
end
# 
# No example needed!!
############################## 
                             



# Tied to the idea of Injector Name Spaces is the one of Injector Version Naming/Tagging.  In order to make is easier to
# work with trait versions there is a need to tag/name the different versions for later use.
describe 'trait Tagging/Naming and its relationship to Injector Versioning' do
	
	there 'is way to tag/name a particular version for later reuse' do

		trait :Bar
		
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
		
		# This is consistent with the notion of a version:
		# the tag is a snapshot of the Injector at the point of creation
		# . once defined it shouldn't be modified
		# . to make modifications create a new version
		 
	end
		
	it 'does work this way however' do
		
		OtherTag = Bar do 			# New Tag/version!!
			def foo
				:oof
			end
		end 				# Bar is a true method 
		
		class TagsTester
			include SomeTag
		end
		
		TagsTester.new.foo.should == :foo
		
		# update the version a target uses 
		
		class TagsTester
			update OtherTag
		end
		
		TagsTester.new.foo.should == :oof
		
	end
end

describe "tag scoping and naming" do
	
	before do
		suppress_warnings do
			A = Class.new
			B = Class.new
		end
	end
	after do
		suppress_warnings do
			A = nil
			B = nil
		end
	end
	it 'passes on top level' do
		
		jack :M0
		
		TopLevelTag = M0()
		extend TopLevelTag
		
		singleton_class.ancestors.to_s.should match(/TopLevelTag/)
		
	end
	
	it 'passes for nested tags' do
		
		module M1
			jack :j1
		end
		
		module M2
			Atag = M1.j1
		end
		
		class A
			include M2::Atag
		end
		
		A.ancestors.to_s.should match(/Atag/)
		
	end
	
	it 'also passes with deeper nesting' do
		
		module M3
			module M4
				AnotherTag = M1.j1
			end
		end
		
		class B
			include M3::M4::AnotherTag
		end
		
		B.ancestors.to_s.should match(/AnotherTag/)
		
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

