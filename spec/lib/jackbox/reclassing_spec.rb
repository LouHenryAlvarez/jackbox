require "spec_helper"
=begin rdoc
	This file represents a new approach to refining a class using Jackbox modular closures.
	
	lha
=end

# define injectors

StringExtensions = injector :StringExtensions do
  def to_s
		super + '++++'
	end
end


# Jackbox Reclassings

lets String do 
	include StringExtensions
end

assert( String('boo').to_s == 'boo++++' )

describe :String do
	it 'should pass' do
		String('boo').to_s.should == 'boo++++'
	end 
end

              
# define injectors

jack :ary_ext do
	def to_s
		super + '####'
	end
end


# Another Reclassing

lets Array do
	inject ary_ext
end

assert(Array(3).to_s == "[nil, nil, nil]####")

describe :Array do
	it 'allows the following' do
  	Array(3).to_s.should == "[nil, nil, nil]####"
	end
end


# deeper down the hierarchy

module M5
	def self.foo 
		String('foo').to_s
	end
end

assert( M5.foo == 'foo++++' )

describe M5 do
	it 'works' do
		M5.foo.should == 'foo++++'          
	end
end


class A5
	module M6
		def meth arg
			String(arg).to_s
		end
	end
	include M6
end

assert(A5.new.meth("meth")== 'meth++++')

describe A5 do
	it "shold pass" do
		A5.new.meth("meth").should == 'meth++++'
	end
end


# re- Reclassing

MyStringExtensions = StringExtensions() do
	def to_s
		super + '----'
	end
end

describe 're-reclassing' do
	it 'should pass' do
		
		String() do 																	# this is not top level --example level
			update MyStringExtensions
		end
		String('standard').to_s.should == 'standard----'
		
	end
end

# ORIGINAL CLASSES REMAIN UNTOUCHED!!!
##################################################

assert(String.new.to_s == '')
assert(Array.new(3).to_s == '[nil, nil, nil]')

#################################################                  
# ORIGINAL CLASSES REMAIN UNTOUCHED!!!


# Multiple re-classings

injector :ary_pro do
	def to_s 
		super + '!!!!'
	end
end

module M7
	
	# Internal reclassing 
	
	lets Array do
		inject ary_pro
	end
	
	def foo_bar
		Array(2).to_s
	end
end 

class A6
	include M7
end

assert( defined?( M7.Array ) == 'method')

assert( A6.new.foo_bar.to_s == "[nil, nil]!!!!")

describe "Internal Array()" do
	it 'should pass' do
		A6.new.foo_bar.to_s.should == '[nil, nil]!!!!'
	end
end


# TOP LEVEL RECLASSINGS REMAIN UNTOUCHED!!!
##################################################

assert( String('test').to_s == 'test++++' )
assert(Array(3).to_s == '[nil, nil, nil]####')

#################################################                  
# TOP LEVEL RECLASSINGS REMAIN UNTOUCHED!!!


# ORIGINAL CLASSES REMAIN UNTOUCHED!!!
##################################################

assert(String.new.to_s == '')
assert(Array.new(3).to_s == '[nil, nil, nil]')

#################################################                  
# ORIGINAL CLASSES REMAIN UNTOUCHED!!!





