<!---
# @author Lou Henry Alvarez
-->
Copyright © 2014 LHA. All rights reserved.

Jackbox
=======

Jackbox is a set of programming tools which enhance the Ruby language and/or provide additional software constructs.  

The main library function at this time centers around the concept of code injectors.  To make it easier to grasp the idea behind them, these can perhaps be thought of as a type of closures which can also serve as modules.  With them it is possible to solve several general problems in the area of OOP according to the GOF standard.  For example, they solve traditional Ruby problems in the Decorator Pattern and Strategy Pattern. If the GOF standard is not in your work perhaps it's best to look at Jackbox's ability to inject your methods' surrounding context into a target using a type of closures that have all the properties of modules, but that also make it  possible to control the presence of code within targets with a mechanism involving injector directives.  This makes things like conditional code injection and withdrawal trivial matter.  And, there is more coming soon.

Basic Methods
--------------------------
There are some basic Jackbox methods like #decorate which lets you decorate an instance or class method without resorting to #alias\_method\_chain or other intricate schemes, or #lets which lets you create a local or global scope def in your code using a function-like style.  There is also a new #with method which allows working with an object within the context of another.  These are their descriptions:

#### #decorate(:sym, &blk)
This method allows for decorations to be placed on a single method, be it an instance or class method without too much fuss. It also makes possible the use of ruby's keyword :super within the body of the decorator.  Use it instead of #alias\_method\_chain.

Examples:

    # some class
  	class One
  		def foo
  			'foo '
  		end
  	end
  	# then...
    

At the class level during definition:

    # the same class
  	class One
  		decorate :foo do
  			super() + 'decoration '
  		end
  	end
	
  	One.new.foo
  	#=> foo decoration
    

At the object level during execution:

    
    one = One.new

    one.decorate :foo do |arg|
    	super() + arg
    end

    one.foo('after')
    #=> foo decoration after
    

It also works like so:

		
    Object.decorate :inspect do
    	puts super() + " is your object"
    end

    Object.new.inspect
    #=> #<Object:0x00000101787e20> is your object
	

#### #lets(sym=nil, &blk)
This is simple syntax sugar.  It allows the creation of local or global procs using a more function-like syntax.  It adds readability to some constructs.  Here are some examples:

To define local functions/lambdas. Define symbols in local scope:

    def main
      lets bar =->(arg){ arg * arg }                    # read as lets set bar to lambda/proc 

      # later on ...

      var = bar[3]        # #bar is only available within #main
      #...
    end															

As a shortcut for define_method. Use it for short functional definitions:

    lets( :meth ){ |arg| arg * 2 }                      # read as lets define symbol :meth to be ....
    meth(3)															
    # => 6 

Can be used to define a special values or pseudo-immutable strings:

    lets(:foo){3+Math::Pi}                              # read as lets set :foo to value
    lets(:faa){ 'some important string' }
    
Allows even local blocks:

    lets { puts 'blah blah'}.call                       # lets make this call
    # => blah blah
    
    # or even...
    
    lets {                                              # lets eval this block on condition
      
      # a longer evaluation ...
      
    }.call if true

#### #with(obj, &blk)
There is also a new version of the :with construct.  There is of course some controversy surrounding the applicability of this  construct in Ruby, but we submit to you this new version.  Here is the sample usage code:

    # with includes the calling context
    
  	class One
  		def foo(arg)
  			'in One ' + arg
  		end
  	end
	
  	class Two
  		def faa(arg)
  			'and in Two ' + arg
  		end
  		def meth
  			with One.new do
  				return foo faa 'with something'   # context of One and Two available simultaneously!!!
  			end
  		end
  	end
	
  	Two.new.meth
  	#=> 'in One and in Two with something'
  	

Or its use in the following method:

    def add_line(spec)
    	open spec[:to], 'r+' do |file|
    		lines = file.readlines
    		file.rewind

    		index = 0
    		# look for the first 'require' line in file				
    		lines.each_with_index { |line, i| 
    			if line.match(/^require/).nil?
    				break if index != i
    				index = i + 1
    				next
    			else
    				index = i
    			end 
    		}
    		# insert our line after check to see not already there
    		with lines do
    			format = spec[:format] || required
    			unless join.match(Regexp.new(format.join('|')))
    				insert(
    					index && index + 1 || 0, format.last
    					) 
    			end
    		end

    		file.write lines.join
    	end
    end


Injectors
----------
Injectors are the main tool in Jackbox at the time of this writing. To illustrate, we will use some examples:

    # somewhere in your code
    
    include Injectors

    injector :my_injector do        # define the injector 

    	def bar                  
    		:a_bar
    	end

    end


    # later on...
    
    inject my_injector              # apply the injector
  
    # or...  
  
    enrich my_injector

    puts bar  
    #=> a_bar


#### #injector(:sym)   #=> j
This is the main method.  It builds an object of type Injector with the name of symbol :sym.  Use it when you want to generate an Injector object for later use.  The symbol can then be used as a handle to the injector whenever you need to add methods to it or apply it to another object.

Here is another exmaple:

    class ClosureExpose

    	some_value = 'something'
	
    	injector :capture do
    		define_method :val do
    			some_value
    		end
    	end

    	inject capture
    end

    class SecondClass
    	inject ClosureExpose.capture
    end

    # the result
    SecondClass.new.val.should == 'something'


For all this to happen Jackbox also introduces some additional ruby constructs, namely the keywords #inject and #enrich.  These can be thought of as simply new corollaries to #include and #extend. If you're working with injectors you need to use them depending on context as some of the functionality of Injectors is related to them.

#### #inject(*j*)
This method is analogous to ruby's #include but its use is reserved for Injectors.  The scope of this method is the same as the scope of #include, and its intended use is for class definitions. Use it to "include" an Injector into a receiving class.

#### #enrich(*j*)
This method in turn is analogous to ruby's #extend. The scope of this method is also the same as that of #extend, and its intended use if for object definition.  Use it to extend the receiver of an injector.

### Multiple Injector composition
The composition of multiple injectors into an object can be specified as follows:

    include Injectors
    
    # declare injectors
    injector :FuelSystem
    injector :Engines
    injector :Capsule
    injector :Landing

    # compose the object
    class SpaceShip
    	inject FuelSystem()
    	inject Engines()
    	inject Capsule()
    	inject Landing()

    	def launch
    		gas_tank fuel_lines burners ignition :go
    		self
    	end
    end


    # define functionality
    FuelSystem do
    	def gas_tank arg
    		:gas
    	end

    	def fuel_lines arg
    		:fuel
    	end

    	def burners arg
    		:metal
    	end
    end

    # further define function
    Engines do
    	def ignition arg
    		:spark
    	end
    end

    # create object
    flyer = SpaceShip.new.launch
    # flyer = subject.new.launch

     # in flight definitions, ha ha!!
    Capsule do
    	def o2
    		:oxigen
    	end
    	def hydration
    		:water
    	end
    end

    # more inflight definitions
    var = 'wheels'
    Landing do
    	define_method :gear do            # a closure defining function based on surrounding context
    		var
    	end
    end


*IMPORTANT NOTE: Injector lookup follows the method and not the constant lookup algorithm.*

If you need to follow constant lookup, here is the code for that:

    Name = injector :sym ....

But, this is the basic idea here.  Again, it's a closure/block that can define function for later use.  Using this approach Jackbox goes on to solve the Decorator Pattern problem for the Ruby language.  


### The GOF Decorator Pattern:   
Traditionally this is only partially solved in Ruby through PORO decorators or the use of modules.  However, there are the problems of loss of class identity for the former and the limitations on the times it can be re-applied to the same object for the latter. With Jackbox this is solved.  An injector used as a decorator does not confuse class identity for the receiver. 

Here is the code for that:

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
	injector :sprinkles do
		def cost
			super() + 0.15
		end
	end
	
	cup = Coffee.new.enrich(milk).enrich(sprinkles)
	cup.should be_instance_of(Coffee)

	cup.cost.should == 1.95


Furhtermore, these decorators can be re-applied multiple times to the same receiver:

	cup = Coffee.new.enrich(milk).enrich(sprinkles).enrich(sprinkles)
	# or even..
	cup = Coffee.new.enrich milk, sprinkles, sprinkles

	cup.cost.should == 2.10
	cup.should be_instance_of(Coffee)
	cup.injectors.should == [:milk, :sprinkles, :sprinkles]
	
Decorators are useful in several areas of OOP: graphics, stream processing, command processors to name a few.


### Injector introspection
Injectors have the ability to speak about themselves and inject their receivers with these introspecting capabilities.  Every injected/enriched object or class can enumerate its injectors.  Moreover injectors can speak about its members just like any module or class.
    
    class Target
    end

    injector :Function do
      def far
        puts :faaaar
      end
    end
    injector :Style do
    	def pretty
    		'oohooo'
    	end
    end

    Target.inject Function(), Style()

    Target.injectors.should == [:Function, :Style] 

    Function().instance_methods.should == [:far]
    Style().instance_methods.should == [:pretty]    

    
#### #injectors(*syms)
Called with no arguments returns a list of injector symbols.  A call with a list of injector symbols however returns an array of actual Injector objects. An example use goes like this:

    class Target
      inject function
      inject style
    end
    
    # later on...
    Target.injectors.each{ |ij| Target.eject ij }  

### Other Capabilities of Injectors

The functionality of an injector can be removed from the individual objects enriched by it.
	
  	class Coffee
  		def cost
  			1.00
  		end
  	end
  	injector :milk do
  		def cost
  			super() + 0.50
  		end
  	end

  	cup = Coffee.new.enrich(milk)
  	friends_cup = Coffee.new.enrich(milk)

  	cup.cost.should == 1.50
  	friends_cup.cost.should == 1.50

  	cup.eject :milk
  	
  	cup.cost.should == 1.00
  	
  	# friends cup didn't change price
  	friends_cup.cost.should == 1.50
  	
Or at the class level, i.e.: after using the #inject keyword:

    # create the injection
    class Home
    	injector :layout do
    		def fractal
    		end
    	end
    	inject layout
    end
    expect{Home.new.fractal}.to_not raise_error

    # build
    my_home = Home.new
    friends = Home.new

    # eject the code
    class Home
    	eject :layout
    end

    # the result
    expect{my_home.fractal}.to raise_error
    expect{friends.fractal}.to raise_error
    expect{Home.new.fractal}.to raise_error


	
The code for this makes use of :eject which is also part of Jackbox and opens the door to some additional functionality provided by injectors.  This additional function allows Injectors to be truly used to inject and eject code at will.

#### :eject(sym)
This method ejects injector function from a single object or class.  For other forms of injector withdrawal see the next sections.  It is in scope on any classes injected or enriched by an injector.

With this capability we can do the following with our Spaceship example from above:

    SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
    flyer.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
    flyer.fuel_lines :on
    flyer.ignition :on
    flyer.o2
    flyer.gear.should == 'wheels'

    # eject class level injector at the object level
    flyer.eject :Capsule

    # expect errors
    SpaceShip.injectors.should == [:FuelSystem, :Engines, :Capsule, :Landing]
    flyer.injectors.should == [:FuelSystem, :Engines, :Landing]
    expect{flyer.o2}.to raise_error
    flyer.fuel_lines :dead
    flyer.ignition :on
    flyer.gear.should == 'wheels'


For more details see the Rspec examples in this project.

### The GOF Strategy Pattern:
Another pattern that Jackbox helps with is the GOF Strategy Pattern.  This is a pattern with changes the guts of an object as opposed to just changing its face. Traditional examples of this pattern use PORO component injection within constructors. 

Here are a couple alternate implementations:

    class Coffee
    	attr_reader :strategy

    	def initialize
    	  @strategy = nil
    	end
    	def cost
    		1.00
    	end
      def brew
    		@strategy = 'normal'
      end
    	def mix
    	end
    end

    cup = Coffee.new
    cup.brew
    cup.strategy.should == 'normal'


    injector :sweedish do
    	def brew
    		@strategy = 'sweedish'
    	end
    end
    injector :french do
    	def brew
    		@strategy ='french'
    	end
    end

    cup = Coffee.new.enrich(sweedish)    # clobbers original strategy for this instance only!!
    cup.brew
    cup.strategy.should == ('sweedish')
    cup.mix

    cup.enrich(french)
    cup.brew
    cup.strategy.should == ('french')
    cup.mix


It is possible to have an even more general alternate implementation. This time we completely replace the current strategy by actually ejecting it out of the class and then injecting a new one:

    class Tea < Coffee  # Tea is a type of coffee!! ;~Q)
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

    Tea.inject sweedish
    cup.brew
    friends_cup.brew
    cup.strategy.should == 'sweedish'
    friends_cup.strategy.should == 'sweedish'

    Tea.inject french
    cup.brew
    friends_cup.brew
    cup.strategy == 'french'
    friends_cup.strategy.should == 'french'

	
### Injector Directives
Once you have an injector handle you can also use it to issue directives to the injector.  These directives can have a profound effect on your code.

#### :collapse directive
This description produces similar results to the previous except that further injector method calls DO NOT raise an error.  They just quietly return nil. Here are a couple of different cases:

The case with multiple objects

	injector :copiable do
		def object_copy
			'a dubious copy'
		end
	end

	o1 = Object.new.enrich(copiable)
	o2 = Object.new.enrich(copiable)

	o1.object_copy.should == 'a dubious copy'
	o2.object_copy.should == 'a dubious copy'

	copiable :silence

	o1.object_copy.should == nil
	o2.object_copy.should == nil


The case with a class receiver:

  	class SomeClass
  		injector :code do
  			def tester
  				'boo'
  			end
  		end

  		inject code
  	end

  	# collapse
  	SomeClass.code :collapse

  	# build
  	a = SomeClass.new
  	b = SomeClass.new

  	a.tester.should == nil
  	b.tester.should == nil

  	# further
  	SomeClass.eject :code 
  	expect{ a.tester }.to raise_error
  	expect{ b.tester }.to raise_error



#### :rebuild directive
Injectors that have been collapsed can at a later point then be reconstituted.  Here are a couple of cases:

The case with multiple object receivers:

    injector :reenforcer do
    	def thick_walls
    		'=====  ====='
    	end
    end

    o1 = Object.new.enrich(reenforcer)
    o2 = Object.new.enrich(reenforcer)

    reenforcer :collapse

    o1.thick_walls.should == nil
    o2.thick_walls.should == nil

    reenforcer :rebuild

    o1.thick_walls.should == '=====  ====='
    o2.thick_walls.should == '=====  ====='


The case with a class receiver:

  	class SomeBloatedObject
  		injector :ThinFunction do
  			def perform
  				'do the deed'
  			end
  		end
  		inject ThinFunction()
  	end
  	SomeBloatedObject.ThinFunction :silence

  	tester = SomeBloatedObject.new
  	tester.perform.should == nil

  	SomeBloatedObject.ThinFunction :active
  	tester.perform.should == 'do the deed'
  	
  	
#### :implode directive
This directive totally destroys the injector including the handle to it.  Use it carefully!

For more information and additional examples see the rspec examples on this project.  There you'll find a long list of rspec example code showcasing some additional features of Jackbox Injectors along with some additional descriptions.


## Additional Tools
Jackbox includes a couple of additional ancillary tools.  The first is an Abstract class base that prevents instantiation of the base class itself but not of its descendants.  The second is a persistent properties module named Prefs; it creates class/module/namespace level persistent properties.

With Abstract the code goes like this:

    class Vector
    	extend Abstract
    	def speed
    		0
    	end
    	def direction
    	end
    end
    expect{Vector.new}.to raise_error
    
    class Velocity < Vector
    	def speed
    		super + 35
    	end
    	def direction
    		:north
    	end
    end
    
    expect{Velocity.new}.to_not raise_error
    Velocity.new.speed.should == 35


With Prefs you can add persistent properties to a class.  These properties persist even through program termination. Here is the example code:

    module Jester
    	extend Prefs
	
    	pref :value => 10
    end
    
    Jester.value.should == 10
    Jester.value = 3
    Jester.value.should == 3
    Jester.reset :value
    Jester.value.should == 10 
  
There is also command line utility called **jackup** that simply allows users to bring their projects into a *"Jackbox level"*.  It inserts the right references and turns the targeted project into a bundler gem if it isn't already one also adding a couple of rake tasks.

## Availability

Jackbox is current available for Linux, Mac, and Windows versions of Ruby 1.9.3 thru 2.1.1

## Installation

Add this line to your application's Gemfile:

    gem 'jackbox'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jackbox
    
And then execute the following command inside the project directory:

    $jackup 
    


## Support
Any questions/suggestions can be directed to the following email address: 

__service.delivered@ymail.com__.  

Please include your platform along with a description of the problem and any available stack trace.  Please keep in mind that all questions will be addressed in the order in which they are received.

## Licensing

Jackbox is currently free for anyone to use.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Copyright © 2014 LHA. All rights reserved.
