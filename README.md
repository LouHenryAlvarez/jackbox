<!---
# @author Lou Henry Alvarez
-->
Copyright © 2014 LHA. All rights reserved.

Jackbox
=======

Jackbox is a set of programming tools which enhance the Ruby language and provide additional software constructs.  

The main library function at this time centers around the concept of code Injectors.  To make it easier to grasp the idea behind them, these can perhaps be thought of as a form of closures which can also serve as modules.  But, most of all Injectors propose some additional interesting properties to the idea of a mix-in.  For instance, they give your code the ability to capture your methods' surrounding context and introduce it into an indiscriminate target.  They make it possible to solve several general problems in the areas of OOP and GOF standard and traditional Ruby shortcomings with the GOF Decorator and Strategy Patterns.  They instrument your ability to control the presence of injector code in targets with mechanisms involving ejection and injector directives.  This can be applied to presentation layers, security frameworks, and others.  Finally, they introduce the concept of injector versioning.  This is a feature which allows you to redefine parts of your program in local isolation and without it affecting others.  See Injector Versioning below.  

Basic Methods
--------------------------
There are some basic Jackbox methods.  These are their descriptions:

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
        super() + 'decoration '                                  # super available within decoration
      end
    end

    One.new.foo
    #=> foo decoration


At the object level during execution:

    one = One.new

    one.decorate :foo do |arg|
      super() + arg                                             # again the use of super is possible
    end

    one.foo('after')
    #=> foo decoration after


It also works like so:

    Object.decorate :inspect do
      puts super() + " is your object"
    end

    Object.new.inspect
    #=> #<Object:0x00000101787e20> is your object


#### #with(obj, &blk)
There is also a new version of the :with construct.  There is of course some controversy surrounding the applicability of this  construct in Ruby, but we submit to you this new version.  Here is the sample usage code:

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
          return foo faa 'with something'                       # context of One and Two available simultaneously!!!
        end
      end
    end

    Two.new.meth
    #=> 'in One and in Two with something'


Use it with #decorate on singleton classes like this:

    class Dir

      with singleton_class do
        decorate :entries do |name='.', opts=nil| #:doc:
          super name, opts
        end
        decorate :new do |name, &code| #:doc:
          FileUtils.mkpath name unless exists?(name)
          return Dir.open(name, &code) if code
          Dir.open name
        end
      end

    end

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


#### #lets(sym=nil, &blk)
This is simple syntax sugar.  It allows the creation of local or global procs using a more function-like syntax.  It adds readability to some constructs.  Here are some examples:

To define local functions/lambdas. Define symbols in local scope:

    def main
      lets bar =->(arg){ arg * arg }                    # read as lets set bar to lambda/proc 

      # later on ...

      var = bar[3]                                      # bar is only available within #main
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


Injectors
----------
Injectors are the main tool in Jackbox at the time of this writing. These again are a form of mix-in that has properties of both a closure and a module.  In the sections below we will discuss some of the methods available to you with Jackbox in connection with Injectors. There are some syntactical differences to Injectors with respect to regular modules.  We will show them first, with some examples: 

**Injectors are declared in the following ways:**


    injector :name  do end

    #  or...

    Name = injector :name  do end

    # or even ...

    injector :Name  do end                              # capitalized method


Their use and semantics are somewhat defined by the following snippet.  But, to fully understand their implications to your code, you have to understand the section on injector versioning, and perhaps injector directives. 

    # somewhere in your code

    include Injectors

    Mine = injector :my_injector do                     # define the injector 
      def bar                  
        :a_bar
      end
    end

    # later on...
    class One
      inject Mine                                       # apply the injector
    end
    
    One.new.bar

    # or...  

    widget.enrich my_injector
    widget.bar


**Injectors can have prolongations:**

    my_injector do                                      # first prolongation

      def another_method
      end

    end

    # ...

    my_injector do                                      # another prolongation

      def yet_another_method
      end

    end



#### #injector(:sym)   #=> j
This is the main method.  It defines an object of type Injector with the name of symbol :sym.  Use it when you want to generate an Injector object for later use.  The symbol can then be used as a handle to the injector whenever you need to prolong the injector by adding methods to it or apply it to another object.

Here is a more interesting example:

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

### Injector Versioning

One of the most valuable properties of injectors is Injector Versioning.  Versioning is the term used to identify a feature in the code that produces an artifact of injection which contains a certain set of methods with their associated outputs and represents a snapshot of that injector up until the point it's applied to an object.  From, that point on the object contains only that version of methods from that injector, and any subsequent overrides to those methods are only members of the "prolongation" of the injector and do not become part of the object of injection unless some form of re-injection occurs. Newer versions of an injector's methods only become part of newer objects or newer injections into existing targets.

**Note: One important thing to remember about versioning is that it refers to re-definitions of methods in newer prolongations of the same injector and the relationship those methods have to the other members of the version and to client code.**

We'll use some examples to illustrate the point.  This is how versioning occurs:

    #___________________
    # injector declaration
    injector :my_injector do 															
      def bar
        :a_bar                                            # version bar.1
      end
      def foo
      	# ...
      end
    end

    enrich my_injector                                    # apply --snapshot:  to any object instance
    bar.should == :a_bar                                  # pass the test

    #__________________
    # injector prolongation
    my_injector do 																			
      def bar
        :some_larger_bar                                  # version bar.2 ... re-defines bar
      end
      def some_other_function
      # ...
      end
    end

    bar.should == :a_bar                                  # bar.1 is still the one  

When re-injection occurs, and only then does the new version of the #bar method come into play. Here is the code:

    #_________________
    # re-injection
    enrich my_injector                                    # re-injection: re-apply --snampshot on any object instance

    bar.should == :some_larger_bar                        # bar.2 now available
    expect{some_other_function}.to_not raise_error        # some_other_function.1 is also present


Here is an example with classes:

    #___________________
    # injector declaration:
    Versions = injector :versions do
      def meth arg                                        # version meth.1
        arg ** arg
      end
    end

    class One
      inject Versions                                     # apply --first snapshot
    end

    #_________________
    # injector prolongation:                              
    versions do
      def meth arg1, arg2                                 # version meth.2 ... redefines meth.1
        arg1 * arg2
      end
    end

    class Two
      inject Versions                                     # apply --second snapshot
    end


    # result
    Two.new.meth(2,4).should == 8                         # meth.2 
                                                                      # two different injector versions
    One.new.meth(3).should == 27                          # meth.1

Re-injection on classes is a little bit trickier.  Why? Because class injection is static --we don't necessarily want to be redefining a class. To re-inject a class we must use the Strategy Pattern or use a private update.  See the rspec files for more on this.  

Right now, we want to give some treatment to injector local binding.  That is, the binding of an injectors' methods is local to the prolongation/version of the injector in which they are located before the versioning occurs.  Here, is the code:

    #_____________________
    # injector declaration
    injector :functionality do
      def basic arg                                       # version basic.1
        arg * 2
      end
    end

    o = Object.new.enrich functionality                   # apply --first snapshot
    o.basic(1).should == 2                                # basic.1 


    #_____________________
    # injector prolongation
    functionality do
      def basic arg                                       # basic.2 ... basic.1 redefined
        arg * 3
      end

      def compound                                        # compound.1 --binding locally to basic.2 in this prolongation
        basic(3) + 2                                      
      end
    end

    p = Object.new.enrich(functionality)                  # apply --second snapshot: like above
    p.basic(1).should == 3                                # basic.2 
    p.compound.should == 11                               # compound.1 
    
    o.basic(1).should == 2                                # basic.1 --NOT basic.2: like above

                                                          ############################################################
    o.compound.should == 11                               # compound.1 --internal local binding to basic.2 NOT basic.1
                                                          ############################################################
                                                          
There is one more interesting property however. The use of #define_method to re-define methods in any prolongation updates the entire injector and all its versions.  This preserves one of the fundamental tenets of injectors: being able to take some local context and through the injector ship it to some indiscriminate place. Here is an example:

    SomeFacet = facet :some_facet do
    	def foo_bar
    		'a foo and a bar'
    	end
    end

    class Client
    	inject SomeFacet
    end

    Client.new.foo_bar.should == 'a foo and a bar'        # expected

    some_facet do
    	define_method :foo_bar do
    		'fooooo and barrrrr'
    	end
    end

    Client.new.foo_bar.should == 'fooooo and barrrrr'     # different

Injector Versioning together with injector local binding allow you to mutate injectors to fit your particular purpose at hand and keep those local modifications isolated from the rest of your program making your code to naturally evolve with your program.


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
    	define_method :gear do            # a definintion based on available surrounding context
    		var
    	end
    end


**IMPORTANT NOTE: Injector lookup follows the method and not the constant lookup algorithm.**

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


Furthermore, these decorators can be re-applied multiple times to the same receiver:

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

The functionality of an injector can be removed from an #enrich to individual objects:
	
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
  	
Or, from an #inject at the class level:

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
This method ejects injector function from a single object or class.  For other forms of injector withdrawal see the next sections.  It is in scope on any classes injected or enriched by an injector.  With this capability we can do the following with our Spaceship example from above:

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
    end

    cup = Coffee.new
    cup.brew
    cup.strategy.should == 'normal'


    injector :sweedish do
    	def brew
    		@strategy = 'sweedish'
    	end
    end

    cup = Coffee.new.enrich(sweedish)                       # clobbers original strategy for this instance only!!
    cup.brew
    cup.strategy.should == ('sweedish')


But, with #eject it is possible to have an even more general alternate implementation. This time we completely replace the current strategy by actually ejecting it out of the class and then injecting a new one:

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

    Tea.eject :SpecialStrategy

    Tea.inject sweedish

    cup.brew
    cup.strategy.should == 'sweedish'

	
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

Please include your platform along with a description of the problem and any available stack trace.  Please keep in mind that, at this time we have limited staff and we will do our best to have a quick response time.

## Licensing

Jackbox is currently free for anyone to **use**.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Copyright © 2014 LHA. All rights reserved.
