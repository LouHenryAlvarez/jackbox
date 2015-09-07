<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-58877141-3', 'auto');
  ga('send', 'pageview');

</script>
<!---
# @author Lou Henry Alvarez
-->
Copyright © 2014, 2015 LHA. All rights reserved.

Jackbox   <a href="https://plus.google.com/102732809517976898938" rel="publisher">Google+</a>
=======

The main library function at this time centers around the concept of code Injectors.  To make it easier to grasp the idea behind them, these can perhaps be thought of as a form of **closures which can also serve as modules**.  Most of all Injectors propose some additional interesting properties to the idea of a mix-in.  For instance, they give your code the ability to capture its surrounding context and mix it into an indiscriminate target.  They make it possible to solve several general problems in some areas of OOP, overcoming traditional Ruby shortcomings with the GOF Decorator and Strategy Patterns, and enabling **some new code patterns.**  They instrument control over (code presence) the presence of injector code in targets with mechanisms involving injector ejection and directives.  They extend Ruby's mix-in and method resolution over and beyond what is possible with regular modules. Finally, they introduce the concept of Injector Versioning.  This is a feature which allows you to redefine parts of your program in local isolation and without it affecting others.  See Injector Versioning below.  

Basic Methods
--------------------------
There are some basic methods to Jackbox.  These are just rudimentary helpers, which in effect are a form of syntax sugar for every day things.  But, behind their apparent sugar coating there lie some powerful capability as shown the deeper you delve into Jackbox.  For more on them read the following sections, but their preliminary descriptions follow here:

#### #decorate :sym, &blk 
This method allows for decorations to be placed on a single method, be it an instance or class method without too much fuss. One important thing about #decorate is that it works like #define_method, but in addition, it also makes possible the use of Ruby's #super within the body of the decorator.  It really presents a better alternative and can be used instead of #alias\_method\_chain.

At the class level:

    class One
      decorate :foo do
        super() + 'decoration '                   # super available within decoration
      end
    end

    One.new.foo
    #=> foo decoration

Or, at the object level:

    one = One.new

    one.decorate :foo do |arg|
      super() + arg                               # again the use of super is possible
    end

    one.foo('after')
    #=> foo decoration after

It also works like so:

    Object.decorate :inspect do
      puts super() + " is your object"
    end

    Object.new.inspect
    #=> #<Object:0x00000101787e20> is your object


#### #with obj, &blk 
There is also a new version of the :with construct.  The important thing to remember about #with is it has a primary context which is the object passed to it, and a secondary context which is the object you are making the call from.  This allows you to work **with** both contexts at the same time. The other important thing about #with is that it allows you to directly place definitions on and returns the same object you passed into it. 

Here is some sample usage code:

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
        with One.new do                           # context of One and Two available simultaneously!!!
          return foo faa 'with something'         
        end                                       # return object
      end
    end

    Two.new.meth
    #=> 'in One and in Two with something'

Use it to define function:

    # internal facade for Marshal
    with Object.new do

    	@file_spec = [file, mode]				
    	def dump hash
    		File.open(*@file_spec) do |file|
    			Marshal.dump( hash, file)
    		end
    	end
    	def load hash
    		File.open(*@file_spec) do |file|
    			hash.merge!(Marshal.load( file ))
    		end
    	end

    end

Use it with **#decorate** on singleton classes like this:

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

    
#### #lets sym=nil, &blk 
We could say, this is simple syntax sugar.  It adds readability to some constructs.  It allows the creation of local or global procs using a more function-like syntax. But #lets, also opens the door to a new coding pattern termed Re-Classing.  See below.  The important thing about #lets is that it always defines some method.  Here are some examples:

To define local functions/lambdas. Define symbols in local scope:

    def main
      lets bar =->(arg){ arg * arg }              # read as: lets set bar to lambda/proc 

      # later on ...

      var = bar[3]                                # bar is only available within #main
      #...
    end															

As a shortcut for define_method. Use it for short functional definitions:

    lets( :meth ){ |arg| arg * 2 }                # read as: lets define symbol :meth to be ....
    meth(3)															
    # => 6 

Can be used to define a special values or pseudo-immutable strings:

    lets(:foo){ 3+Math::Pi }                      # read as: lets set :foo to value
    lets(:faa){ 'some important string' }
    

Injectors
----------
Injectors are the main tool in Jackbox at the time of this writing. These again are a form of mix-in that has properties of both a closure and a module.  They can also be thought of as an **extended closure** if you will or as a special kind of module if you want.  In the sections below we will discuss some of the methods available to you with Jackbox in connection with Injectors, as well as elaborate on some of the other properties of injectors. But, it is essential to understand there are some syntactical differences to Injectors with respect to regular modules.  We will show them first, with some examples: 

**INJECTORS ARE DECLARED IN THE FOLLOWING WAYS:**


    injector :name

    #  or...

    Name = injector :name

    # or even ...

    jack :Name                                    # capitalized method, using alias #jack 
    slot :name                                    # also alias to slot


Their use and semantics are somewhat defined by the following snippet.  But, to fully understand their implications to your code, you have to understand the sections on injector versioning, their behavior under inheritance, and perhaps injector directives. 

    # somewhere in your code
    include Injectors

    injector :my_injector                         # define the injector 
    
    my_injector do                     
      def bar                  
        :a_bar
      end
    end

    # later on...
    widget.enrich my_injector                     # apply the injector
    widget.bar
    # => bar
    
    # or...  
    
    Mine = my_injector
    class Target
      inject Mine                                 # apply the injector
    end
    
    Target.new.bar
    # => bar
    
    # etc ...

Here is a more interesting example:

    class ClosureExpose

    	some_value = 'something'

    	injector :capture do
    		define_method :val do
    			some_value
    		end
    	end
    end

    class SecondClass
    	inject ClosureExpose.capture
    end

    # the result
    SecondClass.new.val.should == 'something'

**INJECTORS HAVE PROLONGATIONS:**

    injector :my_injector

    my_injector do                                # first prolongation

      def another_method
      end

    end

    # ...

    my_injector do                                # another prolongation

      def yet_another_method
      end

    end

#### #injector :sym
This is a global function.  It defines an object of type Injector with the name of symbol.  Use it when you want to generate an Injector object for later use.  The symbol can then be used as a handle to the injector whenever you need to prolong the injector by adding methods to it or apply it to another object. Additionally, this symbol plays a role in defining the injector's scope.  Injectors with capitalized names like :Function, :Style, etc have a global scope.  That is they are available throughout the program:

    class A
      injector :Function
    end

    class B
      include Function()
    end

    # This is perfectly valid with injectors  

On the other hand Injectors with a lower case name are only available __from__ the scope in which they were defined, like the following example shows:

    class AA
      injector :form
    end

    class BB
      include form                                # This genenerates and ERROR!                                 
    end                         
                      
    class BB
      include AA.form
    end

    # This is perfectly valid with injectors  

For all this to happen Jackbox also introduces some additional Ruby constructs, namely the keywords #inject and #enrich.  These can be thought as simply new corollaries to #include and #extend. In fact they can be used interchangeably.  If you're working with injectors you may want to use them instead depending on context to make clear your intent.

#### #include/inject *jack
This method is analogous to ruby's #include but its use is reserved for Injectors.  The scope of this method is the same as the scope of #include, and its intended use like include's is for class definitions. Use it to "include" an Injector into a receiving class.  Takes multiple injectors.

#### #extend/enrich *jack
This method in turn is analogous to ruby's #extend. The scope of this method is also the same as that of #extend, and its intended use if for object definition.  Use it to extend the receiver of an injector.  Takes multiple injectors.

**IMPORTANT NOTE: Injector lookup follows the method and not the constant lookup algorithm.**

If you need to follow constant lookup, here is the code for that:

    Name = injector :sym ....                     # this also creates a hard tag (see below)

### Injector Versioning

One of the most valuable properties of injectors is Injector Versioning.  Versioning is the term used to identify a feature in the code that produces an artifact of injection which contains a certain set of methods with their associated outputs, and represents a snapshot of that injector up until the point it's applied to an object.  From, that point on the object contains only that version of methods from that injector, and any subsequent overrides to those methods are only members of the "prolongation" of the injector and do not become part of the object of injection unless some form of re-injection occurs. Newer versions of an injector's methods only become part of newer objects or newer injections into existing targets.  With Jackbox Injector Versioning two different versions of the same code object can be running simultaneously. 

We'll use some examples to illustrate the point.  This is how versioning occurs:

    # injector declaration
    #___________________
    injector :my_injector do 															
      def bar
        :a_bar                                    # version bar.1
      end
      def foo
      	# ...
      end
    end

    object1.enrich my_injector                    # apply the injector --first snapshot
    object1.bar.should == :a_bar                  # pass the test

    # injector prolongation
    #__________________
    my_injector do 																			
      def bar
        :some_larger_bar                          # version bar.2 ... re-defines bar
      end
      # ...
    end
    
    object2.enrich my_injector                    # apply the injector --second snapshot
    object2.bar.should == :some_larger_bar

    # result
    
    object1.bar.should == :a_bar                  # bar.1 is still the one

    ###############################################
    # First object has kept its preferred version #
    ###############################################


When re-injection occurs, and only then does the new version of the #bar method come into play. But the object remains unaffected otherwise, keeping its preferred version of methods.  The new version is available for further injections down the line and to newer client code.  Internal local-binding is preserved.  If re-injection is executed then clients of the previous version get updated with the newer one.  Here is the code:

    # re-injection
    #_________________
    object1.enrich my_injector                    # re-injection --third snapshot

    object1.bar.should == :some_larger_bar        # bar.2 now available

    ###############################################
    # First object now has the updated version    #
    ###############################################


Re-injection on classes is a little bit trickier.  Why? Because class injection should be more pervasive --we don't necessarily want to be redefining a class at every step. To re-inject a class we must use the Strategy Pattern (see below) or use a private update.  See the sections below as well as the rspec files for more on this.   

Here is an example of Injector Versioning as it pertains to classes:

    # injector declaration:
    #___________________
    injector :Versions do
      def meth arg                                # version meth.1
        arg ** arg
      end
    end

    class One
      inject Versions()                           # apply --snapshot
    end

    # injector prolongation:                              
    #_________________
    Versions do
      def meth arg1, arg2                         # version meth.2 ... redefines meth.1
        arg1 * arg2
      end
    end

    class Two
      inject Versions()                           # apply --snapshot
    end

    # result

    Two.new.meth(2,4).should == 8                 # meth.2 
    One.new.meth(3).should == 27                  # meth.1

    ##############################################
    # Two different injector versions coexisting #
    ##############################################

To update the class, we then do the following:
    
    class One
      update Versions()                           # private call to #update
    end
    
    One.new.meth(2,4).should == 8                 # meth.2 
    Two.new.meth(2,4).should == 8                 # meth.2 

    ##############################################
    # class One is now updated to the latest     #
    ##############################################
    

### Tagging/Naming

The use of Tags is central to the concept of Injector Versioning.  Tagging happens in the following ways:

    Version1 = jack :function do
      def meth arg
        arg
      end
      def mith
        meth 2
      end
    end

    Version2 = function do
      def mith arg
        meth(arg) * meth(arg)
      end
    end

Version1 and Version2 are two different hard versions/tags/names of the same Injector.  There are also soft tags (see below).  

### Local Binding

Before we move on, we also want to give some further treatment to injector local-binding.  That is, the binding of an injectors' methods is local to the prolongation/version in which they are located before the versioning occurs.  Here, is the code:

**Note: In the following examples we use the notion of version naming/tagging.  This allows you to tag different versions/prolongations of an Injector for later use.  Once a version is tagged it shouldn't be modified**
                                                          

    # injector declaration
    #_____________________

    Version1 = injector :functionality do
      def basic arg                               # version basic.1
        arg * 2
      end
    end
    
    o = Object.new.enrich Version1                # apply --snapshot (like above)
    o.basic(1).should == 2                        # basic.1 

    # injector prolongation
    #_____________________

    Version2 = functionality do
      def basic arg                               # version basic.2
        arg * 3                                   # specific use in compound.1
      end

      def compound                                # compound.1 
        basic(3) + 2                                      
      end
    end
                                               
    p = Object.new.enrich Version2                # apply --snapshot (like above)
    p.basic(1).should == 3                        # basic.2 
    p.compound.should == 11                       # compound.1 --bound locally to basic.2
    
    o.basic(1).should == 2                        # basic.1 
    o.compound.should == 11                       # compound.1 --bound locally to basic.2
    
    ####################################################
    # #compound.1 bound to the right version #basic.2  #
    ####################################################
    
    
### Method Virtual Cache

When you are working with an Injector in irb/pry it is often easier to just add methods to the injector without actually having to re-apply the injector to the the target to see the result.  This is just what the Jackbox method virtual cache is for among other things.  Here is what the code looks like:

    # Facet definition
    facet :SpecialMethods
    
    class MyClass
      include SpecialMethods
    end
    
    obj = MyClass.new
    
    SpecialMethods do
      def spm1                                    # spm1 is only defined in the virtual cache
        :result                                   # It is not actually part of the class yet!!
      end                                         # until this version/prolongation is applied
    end
    
    expect(obj.spm1).to eq(:result)               # yet my obj can use it --no problem
    
The key idea here is that the method virtual cache is the same for all versions of the Injector and all its applications.  If we redefine those methods they also get redefined for all versions.  To actually lock the method versions you must apply the Injector.

#### #define\_method sym, &blk
There is one more interesting property to method definition on Injectors however. The use of #define\_method to re-define methods in any prolongation updates the entire injector and all its versions.  This also preserves a fundamental tenet of injectors: take some local context, enclose it, and use the injector to introduce it to some indiscriminate target, and additionally has some other uses as we'll see with in our description of patterns and injector composition.  

Here is an example of the difference with #define\_method:

    jack :some_jack do
    	def meth
    	  :meth
    	end
    	
    	def foo_bar
    		'a foo and a bar'
    	end
    end

    class Client
    	inject some_jack
    end

    Client.new.meth.should == :meth
    Client.new.foo_bar.should == 'a foo and a bar'      


    some_jack do                                  
    	def meth                                    # New version
    	  puts :them
    	end
    	
    	define_method :foo_bar do                   # New version
    		'fooooo and barrrrr'
    	end
    end     
                                                  ################################
                                                  # Like above!                  #
    Client.new.meth.should == :meth               # No re-injection == No change #
                                                  ################################
    
                                                  ################################
    Client.new.foo_bar.should ==                  # Different!!!                 #
    'fooooo and barrrrr'                          # No re-injection == Change    #
                                                  # . Thanks to define_method    #
                                                  ################################ 

Injector Versioning together with injector local-binding allow the metamorphosis of injectors to fit the particular purpose at hand and keeping those local modifications isolated from the rest of your program making your code to naturally evolve with your program. Use it as an alternative to refinements.

### Injector introspection
Injectors have the ability to speak about themselves.  Moreover injectors can speak about their members just like any module or class, and can also inject their receivers with these introspecting capabilities.  Every injected/enriched object or module/class can enumerate its injectors, and injectors can enumerate their members, and so forth.  
    
    injector :Function do
      def far
      end
      def close
      end
    end
    
    injector :Style do
    	def pretty
    	end
    end

    class Target
      inject Function(), Style()
    end

    # class ?
    
    Function().class.should == Injector                 
    Style().class.should == Injector 
    
#### #injectors *sym
Called with no arguments returns a list of injectors.  A call with a list of injector symbols however returns an array of actual Injector objects matching the names supplied in a LIFO fashion. An example use goes like this:

    # injectors (in this target) ?
    
    Target.injectors 
    => [(#944120:|Function|), (#942460:|Style|)] 
    
    # injectors :name ?
    
    Target.injectors :Function
     => [(#944120:|Function|)]                    # same as #injectors.collect_by_name :name
     
    Target.injectors :all                         # all injectors in this class's hierarchy 
                                                  (see section on Inheritance)
     
The method also extends into a minuscule API: 
    
    Target.injectors.by_name.should == [:Function, :Style] 
    # ...
    Target.injectors(:all).by_name
    # aliased to :sym_list
    
    Target.injectors.collect_by_name :name        # see above
    # ...
    Target.injectors(:all).collect_by_name :name
    # aliased to :all_by_sym
    
    Target.injectors.find_by_name :Function       # last one in first out
     => (#944120:|Function|)      
    # ...
    Target.injectors(:all).find_by_name :name
    # aliased to last_by_sym
    
    Function().instance_methods.should == [:far, :close]      
    Style().instance_methods.should == [:pretty]    

    # later on...

    # eject all injectors in target
    Target.injectors.each{ |j| Target.eject j }
    
    # or..
    
    Target.eject *Target.injectors       

#### #history alias #versions
This method returns a trace of all the target hosted Injectors which is ordered based on the order in which they are created.  It includes tags and soft tags which can be specifically accessed thru the #tags method below.  Here is the code:

    # create our injector
    injector :HistorySample
                        
    # host it a couple of times
    extend( HistorySample(), HistorySample() )
    
    # expect the following
    expect(injectors).to eq(HistorySample().history)
    expect(HistorySample().history.size).to eq(2)
    expect(HistorySample().history.last).to eql(HistorySample())
    expect(HistorySample().history.last).to_not eq(HistorySample().spec)
    
    # create a tag
    HistorySampleTag = HistorySample()
    
    expect(HistorySample().history.size).to eq(3)
    expect(HistorySample().history.last).to equal(HistorySampleTag)
    
#### #tags
This method traces the tags only.  Here is the code:

    # at this point from the above
    expect(HistorySample().tags.size).to eq(1)
    
    HistorySample(:tag) do
      # some definitions
    end
    
    # expect the following
    expect(HistorySample().tags.size).to eq(2) 

Take a look at the Transformers Pattern below for an application of this and also the Jackbox blog at <a href="http://jackbox.us">http://jackbox.us</a>

#### #precedent and #progenitor (alias #pre, #pro)
The #pre method gets the previous element in the history. Here is the code:

    # create the injector
    injector :HistorySample

    # create some history
    extend HistorySample(), HistorySample()
                         
    # expect the following
    expect(HistorySample().history.last.precedent).to equal(HistorySample().history.first)
    
The #pro method is a little different.  It gets the version from which a particular injector was generated. This may not necessarily be the precedent.  Take a look at the following code.

    # create the injector
    injector :Progample
    
    # expect the following
    expect(Progample().history).to be_empty
    expect(Progample().progenitor).to equal(Progample().spec)
   
    # create some history
    extend Progample(), Progample()       

    # expect the following
    expect(Progample().history.size).to eq(2)
    expect(Progample().history.first.progenitor).to equal(Progample().spec)
    expect(Progample().history.last.progenitor).to equal(Progample().spec)

For more on this see the rspec files.     

### Injector composition
The composition of multiple injectors into an object can be specified as follows:

    include Injectors
    
    # declare injectors
    injector :FuelSystem                          # capitalized methods
    injector :Engines
    injector :Capsule
    injector :Landing

    # compose the object
    class SpaceShip
    
    	inject FuelSystem(), Engines(), Capsule(), Langing()    # capitalized method use

    	def launch
    		gas_tank fuel_lines burners ignition :go
    		self
    	end
    end
    
    Spaceship.injectors.by_name == [:FuelSystem, :Engines, :Capsule, :Landing]

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

    # ...
    
    # create object
    flyer = SpaceShip.new.launch


    # in-flight definitions, ha ha ha
    var = 'wheels'
    
    Landing do
    	define_method :gear do                      # a clolsure !!
    		var
    	end
    end

### Inheritance
The behavior of Injectors under inheritance is partially specified by what follows:

    injector :j
    
    class C
    end
    C.inject j {                                  #foo pre-defined at time of injection
      def foo
        'foo'
      end
    }
    C.injectors.by_name.should == [:j]
    C.new.injectors.by_name.should == [:j]

    C.new.foo.should == 'foo'

    # D inherits from C

    class D < C                                   # methods are inherited from j 
    end
    D.injectors.by_name.should == []
    D.injectors(:all).by_name == [:j]

    # New Objects
    C.new.foo.should == 'foo'											
    D.new.foo.should == 'foo'


More importantly though is the following:

    slot :player do                       
    	def sound                               
    		'Lets make some music'                
    	end                                     
    end                                       

    TapePlayer = player do                        # version Tag
    	def play                                      # inherirts :sound
    		return 'Tape playing...' + sound()                          
    	end                                     
    end                                       

    CDPlayer = player do                          # another version Tag
    	def play                                      # also inherits sound
    		return 'CD playing...' + sound()
    	end
    end

    class BoomBox
    	include TapePlayer

    	def on
    		play
    	end
    end

    class JukeBox < BoomBox                       # regular class inheritance
    	inject CDPlayer
    end

    BoomBox.new.on.should == 'Tape playing...Lets make some music'
    JukeBox.new.on.should == 'CD playing...Lets make some music'
    
    jack :speakers

    Bass = speakers do                            # adding composition   
    	def sound                               
    		super + '...boom boom boom...'        
    	end                                     
    end                                       
    JukeBox.inject Bass

    JukeBox.new.on.should == 'CD playing...Lets make some music...boom boom boom...'
    
From all this, the important thing to take is that injectors provide a sort of versioned inheritance.  The version inherits all of the pre-existing methods from the injector and freezes that function.  We can either Tag/Name it of simply include/extend into a target but the function is frozen at that time.  Tags cannot be modified or more clearly shouldn't be modified.  Classes retain the frozen version of the injector until the time an update is made.  Of course, there is always #define\_method.   For more on all this see, the Rspec examples.


---
But, this is the basic idea here.  An extended closure which can be used as a mix-in, prolonged to add function, and versioned and renamed to fit the purpose at hand. 

---
Using this approach Jackbox also goes on to solve the Decorator Pattern problem in the Ruby language.  

### The GOF Decorator Pattern:   
Traditionally this is only partially solved in Ruby through PORO decorators or the use of modules.  However, there are the problems of loss of class identity for the former and the limitations on the times it can be re-applied to the same object for the latter. With Jackbox this is solved.  An injector used as a decorator does not confuse class identity for the receiver. Decorators are useful in several areas of OOP: presentation layers, stream processing, command processors to name a few.  

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
	injector :vanilla do
		def cost
			super() + 0.15
		end
	end
	
	cup = Coffee.new.enrich(milk).enrich(vanilla)
	cup.should be_instance_of(Coffee)

	cup.cost.should == 1.95


Furthermore, these same decorators can be then re-applied MULTIPLE TIMES to the same receiver.  This is something that is normally not possible with the regular Ruby base language.  Here are further examples:

	cup = Coffee.new.enrich(milk).enrich(vanilla).enrich(vanilla)
	
	# or even...
	
	cup = Coffee.new.enrich milk, vanilla, vanilla

	cup.cost.should == 2.10
	cup.should be_instance_of(Coffee)
	cup.injectors.should == [:milk, :vanilla, :vanilla]

	
### Other Capabilities of Injectors

The functionality of Injectors can be removed from individual targets be them class targets or instance targets in various different ways.  This allows for whole 'classes' of functionality to be removed and made un-available and then available again at whim and under programer control.  

Here is an Injector removed after an #enrich to individual instance:
	
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
  	
Here it is removed after an #inject at the class level:

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

	
The code for these examples makes use of the #eject method which is also opens the door to some additional functionality provided by injectors.  See the Strategy Pattern just below this.  

#### #eject *sym
This method ejects injector function from a single object or class.  It is in scope on any classes injected or enriched by an injector.  For other forms of injector withdrawal see the next sections as in addition to this method, there are other ways to control code presence in targets through the use of Injector Directives.  See below.  For more on this also see the rspec examples.

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

    cup = Coffee.new.enrich(sweedish)           # clobbers original strategy for this instance only!!
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

### Soft Tags
Just like hard tags above but a name is not needed:

    jack :SomeJack do
      def foo
        :foo
      end
    end

    SomeJack(:tag) do                             # New Version, not named
      def foo
        :foooooooo
      end
    end

---
### Patterns of a Different Flavor

There are also some additional coding patterns possible with Jackbox Injectors.  Although not part of the traditional GOF set these new patterns are only possible now thanks to languages like Ruby that permit the morphing of traditional forms into newer constructs.  Here are some new patterns: 

__1) Late Decorator.-__ Another flow that also benefits from #define\_method in an interesting way is the following:   

    class Widget
    	def cost
    		1
    	end
    end
    w = Widget.new

    injector :decorator

    w.enrich decorator, decorator, decorator, decorator

    # user input
    bid = 3.5 

    decorator do
    	define_method :cost do                      # defines function on all injectors of the class
    		super() + bid
    	end
    end

    w.cost.should == 15

The actual injector function is late bound and defined only after some other data is available.

__2) The Super Pattern.-__ No.  This is not a superlative kind of pattern.  Simply, the use of #super can be harnessed into a pattern of controlled recursion, like in the following example: 

    jack :Superb

    Superb do
    	def process string, additives, index
    		str = string.gsub('o', additives.slice!(index))
    		super(string, additives, index) + str rescue str
    	end
    	extend Superb(), Superb(), Superb()
    end   

    Superb().process( 'food ', 'aeiu', 0 ).should == 'fuud fiid feed faad '
    Superb(:implode)                                 

__3) The Transformer Pattern.-__  For a specific example of what can be accomplished using this workflow please refer to the rspec directory under the transformers spec.  Here is the basic flow:

    jack :Solution

    Solution( :tag ) do
    	def solution
    		1
    	end
    end
    Solution( :tag ) do
    	def solution
    		2
    	end
    end
    Solution( :tag ) do
    	def solution
    		3
    	end
    end


    class Client
    	inject Solution()
	
    	def self.solve
    		Solution().tags.each { |e|
    			update e 
    			puts new.solution rescue nil
    		}                              
		
    		# or...
		
    		solutions = Solution().tags.each
    		begin
    			update solutions.next
    			puts solved = new().solution()
    		end until solved
    		solved
    	end
	
    end

    Client.solve

__4) The Re-Classing Pattern.-__  Our base method #lets has one more interesting use which allows for an alternative way to refine classes.  We have termed this Re-Classing.  Look at the following code:

    # define injectors

    StringExtensions = injector :StringExtensions do
      def to_s
    		super + '++++'
    	end
    end


    # Jackbox Reclassing

    lets String do 
    	include StringExtensions
    end

    assert( String('boo').to_s == 'boo++++' )

    describe :String do
    	it 'should pass' do
    	
    		String('boo').to_s.should == 'boo++++'
    		
    	end 
    end

The important thing to remember here is that #String() is a method now. We can redefine it, name-space it, test for its presence, etc.  We can also use it to redefine the re-class's methods.  For more on this see, the rspec files and the Jackbox blog.              

### Injector Equality and Difference 

Injectors can be compared.  This allows for further introspection capabilities which could be used to determine if a certain piece of code possesses a block of capabilities, test if those are equal to some other component's capabilities, or test what the difference is.  It only follows that if injectors can be applied and withdrawn from any target we should be able to test for their similarities to other injectors.  Here is how equality is defined:

    # Equality
    
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
    
Here is how difference is defined:

    # Difference

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


Again, for more on this see the rspec files.

### Injector Directives
Once you have an injector handle you can also use it to issue directives to the injector.  These directives can have a profound effect on your code.

#### :collapse directive
This description produces similar results to the one for injector ejection (see above) except that further injector method calls DO NOT raise an error.  They just quietly return nil. Here are a couple of different cases:

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

  	a = SomeClass.new
  	b = SomeClass.new

  	# collapse
  	SomeClass.code :collapse

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
    		'=====|||====='
    	end
    end

    o1 = Object.new.enrich(reenforcer)
    o2 = Object.new.enrich(reenforcer)

    reenforcer :collapse

    o1.thick_walls.should == nil
    o2.thick_walls.should == nil

    reenforcer :rebuild

    o1.thick_walls.should == '=====|||====='
    o2.thick_walls.should == '=====|||====='


The case with a class receiver:

  	class SomeBloatedObject
  		injector :ThinFunction do
  			def perform
  				'do the deed'
  			end
  		end
  		inject ThinFunction()
  	end
  	SomeBloatedObject.ThinFunction :silence  # alias to :collapse

  	tester = SomeBloatedObject.new
  	tester.perform.should == nil

  	SomeBloatedObject.ThinFunction :active   # alias to :rebuild
  	tester.perform.should == 'do the deed'
  	
  	
#### :implode directive
This directive totally destroys the injector including the handle to it.  Use it carefully!

    class Model
    	def feature
    		'a standard feature'
    	end
    end

    injector :extras do
    	def feature
    		super() + ' plus some extras'
    	end
    end

    car = Model.new.enrich(extras)
    car.feature.should == 'a standard feature plus some extras'

    extras :implode

    # total implosion
    car.feature.should == 'a standard feature'

    expect{extras}.to raise_error(NameError, /extras/)
    expect{ new_car = Model.new.enrich(extras) }.to raise_error(NameError, /extras/)
    expect{
    	extras do
    		def foo
    		end
    	end
    	}.to raise_error(NameError, /extras/)



---
For more information and additional examples see the rspec examples on this project.  There you'll find a long list of nearly __200__ rspec examples and code showcasing some additional features of Jackbox Injectors along with some additional descriptions.

---
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

Jackbox is current available for Linux, Mac, and Windows versions of Ruby 1.9.3 thru 2.2.1

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

Also please follow us at http://jackbox.us

## Licensing

Jackbox is currently free for anyone to **use**.
Copyright © 2014, 2015 LHA. All rights reserved.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

In the above copyright notice, the letters LHA are the english acronym 
for Luis Enrique Alvarez (Barea) who is the author and owner of the copyright.
