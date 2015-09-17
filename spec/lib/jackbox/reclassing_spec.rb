require "spec_helper"
=begin rdoc
	This file represents a new approach to refining a class using Jackbox modular closures.
	
	lha
=end

# Jackbox Reclassings
############################################

# RubyProf.start

injector :StringExtensions do  										# define injector
  def to_s
		super + '++++'
	end
end

# debugger
lets String do 																		# apply to class
	include StringExtensions()
end

assert( String('boo').to_s == 'boo++++' )	
assert( String("").class == String )

describe :String do
	it 'should pass' do
		String('boo').to_s.should == 'boo++++'
	end
	# introspecting on Type
	it 'should be class String' do
		String('boo').class.should be(String)
	end 
end

              
# Another Reclassing

jack :ArrayExtensions do
	def to_s
		super + '####'
	end
end

lets Array do
	inject ArrayExtensions()
end

assert(Array(3).to_s == "[nil, nil, nil]####")
assert(Array(3).class == Array)

describe :Array do
	it 'allows the following' do
  	Array(3).to_s.should == "[nil, nil, nil]####"
	end
	# introspecting on Type
	it 'should be Array' do
		Array(3).class.should be(Array)
	end
end

# ORIGINAL CLASSES REMAIN UNTOUCHED!!!
##################################################
assert( String.new.to_s == '' )                  #
assert( Array.new(3).to_s == '[nil, nil, nil]' ) #
                                                 #
describe String do                               #
	it 'should remain untouched' do                #
		String.new('bar').should == 'bar'            #
	end                                            #
end                                              #
                                                 #
describe Array do                                #
	it 'should remain untouched' do                #
		Array.new(3).should == [nil, nil, nil]       #
	end                                            #
end                                              #
##################################################                  
# ORIGINAL CLASSES REMAIN UNTOUCHED!!!           

# ORIGINAL KERNEL METHODS REMAIN UNTOUCHED!!!
##################################################
assert( Kernel.String(123) == '123' )            #
assert( Kernel.Array(3) == [3])                  #
                                                 #
describe :'Kernel.String' do                     #
	it 'should reamain untouched' do               #
		Kernel.String(123).should == '123'           #
	end                                            #
end                                              #
                                                 #
describe :'Kernel.Array' do                      #
	it 'should reamain untouched' do               #
		Kernel.Array([1,2,3]).should == [1,2,3]      #
	end                                            #
end                                              #
##################################################                  
# ORIGINAL KERNEL METHODS REMAIN UNTOUCHED!!!





# Namespaced Reclassings
##################################################

jack :NameSpacedArrayExtensions do
	def to_s 
		super + '!!!!'
	end
end

module M7
	
	# Internal reclassing 

	lets Array do
		inject NameSpacedArrayExtensions()
	end
	
	def foo_bar
		Array(2)
	end
end 

class A6
	include M7
end


describe "Internal Array()" do
	it 'should pass' do
		A6.new.foo_bar.to_s.should == '[nil, nil]!!!!'
	end
	# introspecting on Type
	it 'should be an Array' do
		A6.new.foo_bar.class.should be(Array)
	end
end




# Further Introspection
##################################################
# debugger
assert( A6.new.foo_bar.injectors.by_name == [:NameSpacedArrayExtensions] )

describe "introspection" do
	
	# introspecting on capabilities

	it 'should allow injector introspection' do
		# # top level re-class
		Array() do
			injectors.by_name.should == [:ArrayExtensions]
		end
		# debugger
		Array(){injectors.by_name}.should == [:ArrayExtensions]
		
		# top level re-class instances
		Array(1).injectors.by_name == [:ArrayExtensions]
		
	end
	
	it 'works on namespaced reclassings' do
		module M7
			# debugger
			Array() do
				injectors.by_name.should == [:NameSpacedArrayExtensions]
			end
		end
	end
	
	it 'can test the existence of a re-classing' do

		reclass?(String).should == true
		reclass?(Array).should == true
		
		module M7 
			reclass? Array
		end.should == true
		
		module M8 
			reclass? Array
		end.should == false
		
		module M9
			reclass? String
		end.should == false
		
	end
	
	it 'works' do
		
		# Injector declaration

		jack :StringRefinements do
			lets String do
				with singleton_class do
					alias _new new
					def new *args, &code
						super(*args, &code) + ' is a special string'
					end
				end
			end
		end

		class OurClass
			include StringRefinements()

			def foo_bar
				String('foo and bar')
			end
		end

		c = OurClass.new
		c.foo_bar.class.should == String
		c.foo_bar.should == 'foo and bar is a special string'
		expect{c.foo_bar.extra.should == :extra}.to raise_error(NoMethodError)

		StringRefinements do
			String() do
				def extra
					:extra
				end
			end
		end

		c.foo_bar.should == 'foo and bar is a special string'
		c.foo_bar.class.should == String
		c.foo_bar.extra.should == :extra

		SR = StringRefinements do 										# New Version
			lets String do
				def to_s
					super + '****'
				end
			end
		end

		# c is still the same

		c.foo_bar.should == 'foo and bar is a special string'
		c.foo_bar.class.should == String
		c.foo_bar.extra.should == :extra


		class OurOtherClass
			include SR																# Apply new version
			# to another class
			def foo_bar
				String('foo and bar')
			end
		end

		d = OurOtherClass.new
		d.foo_bar.should == 'foo and bar'
		d.foo_bar.to_s.should == 'foo and bar****'
		expect{ d.extra }.to raise_error(NoMethodError)
			
	end
end





# Calls deeper down the hierarchy
##################################################

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
	it 'should be String' do
		M5.foo.class.should be(String)
	end
end

# even deeper

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
	# introspecting on Type
	it 'should be a String' do
		A5.new.meth("meth").class.should be(String)
	end
	
	it 'should hold access to top level re-class' do
		class A5
			module M6
				String(){injectors.by_name}.should == [:StringExtensions]
			end
		end
	end 
end




# re- Reclassing
################################################

MyStringExtensions = StringExtensions() do
	def to_s
		super + '----'
	end
end

describe 're-reclassing' do
	it 'should pass' do
		String() do 																	
			update MyStringExtensions
		end

		String('standard').to_s.should == 'standard----'
	end
	# introspecting on Type
	it 'should be a String' do
		String('standard').class.should be(String)
	end
	
	it 'should introspect' do
		String(){injectors}.first.should == MyStringExtensions
	end
end



# TOP LEVEL RECLASSINGS REMAIN UNTOUCHED!!!
##################################################
                                                 #
assert( String('test').to_s == 'test++++' )      #
assert( Array(3).to_s == '[nil, nil, nil]####' ) #
                                                 #
##################################################                  
# TOP LEVEL RECLASSINGS REMAIN UNTOUCHED!!!

# TOP LEVEL RECLASSING TYPES REMAIN UNTOUCHED!!!
##################################################
                                                 #
assert( String('test').class == String )         #
assert( Array(3).class == Array )                #
                                                 #
##################################################                  
# TOP LEVEL RECLASSING TYPES REMAIN UNTOUCHED!!!

# ORIGINAL CLASSES REMAIN UNTOUCHED!!!
##################################################
                                                 #
assert(String.new.to_s == '')                    #
assert(Array.new(3).to_s == '[nil, nil, nil]')   #
                                                 #
##################################################                  
# ORIGINAL CLASSES REMAIN UNTOUCHED!!!

# ORIGINAL KERNEL METHODS REMAIN UNTOUCHED!!!
##################################################
                                                 #
assert( Kernel.String(123) == '123' )            #
assert( Kernel.Array(3) == [3])                  #
                                                 #
##################################################                  
# ORIGINAL KERNEL METHODS REMAIN UNTOUCHED!!!

# profile = RubyProf.stop
# RubyProf::FlatPrinter.new(profile).print(STDOUT)
# RubyProf::GraphHtmlPrinter.new(profile).print(open('profile.html', 'w+'))
# RubyProf::CallStackPrinter.new(profile).print(open('profile.html', 'w+'))


