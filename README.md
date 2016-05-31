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

<a href="http://jackbox.us"><h1>Jackbox</h1></a>

---
<h2 style="font-family:Impact">Modular Closures©, Ruby Traits©, Code Injectors, Class Constructors, and other Ruby programmer morphins</h2>

The defining thought behind Jackbox is a simple one: If Ruby is like Play-Doh, with Jackbox we aim to turn it into <a href="https://en.wikipedia.org/wiki/Plasticine">Plasticine</a>.  The library functionality at this time takes this idea and materializes it in the concepts of trait injectors, class constructors, the application of versioning to objects, and a model of mix-in inheritance which includes a just-in-time inheritance form that together with the helper functions that bring them together, provide some new and interesting capabilities.  

To make it easier to grasp, **Ruby Traits©** and code injectors can perhaps be thought of as a form of **Modular Closures©** which is to say, closures which can also serve as modules.  These modular closures most of all propose some additional properties to the idea of a mix-in.  For instance, they make it possible to solve several general problems in some areas of OOP, overcoming traditional Ruby shortcomings with the GOF Decorator and Strategy Patterns, and enabling **some new code patterns** of our own.  They instrument control over code presence or the presence of trait injector code in targets with mechanisms involving trait injector canceling or ejection and directives to for example remain as silent traits, and to later force the reactivation of traits.  They give your code the ability to capture the surrounding context and mix it into an indiscriminate target. They extend Ruby's mix-in and method resolution over and beyond what is possible with regular modules. 

Following on this we introduce the concept of Injector Versioning.  This is a feature which allows you to redefine parts of your program in local isolation and without it affecting others.  See Trait/Injector Versioning below. Runtimes can morph their capabilities as they learn about themselves, and they can do so in blocks as granular or as coarse as needed.  These blocks can be updated, ejected, silenced, or re-injected with more function. This versioning also provides a form of inheritance.  We have called this versioned inheritance and it allows newer versions to inherit from previous ones, be tagged and labeled, and this way be capable of reuse.  All this is further enhanced by the ability of Jackbox to resolve methods through the use of the VMC (Virtual Method Cache). See below.

**Class constructors** on the other hand present an alternative way to refine a class.  They provide similar benefits to refinements with a different underpinning. Together with Jackbox trait injectors and helper functions, class constructors can be refined multiple times.  Capabilities can be added and removed in blocks.  Moreover, these constructors acquire introspecting abilities.  A class constructor can be tested for existence, can tell you what traits it uses, and finally can be overridden with a more relevant one. Constructors also work with all Ruby versions including with Ruby 1.9 and related technologies.

Finally, we also present the concept of **Just-In-Time Inheritance©**.  This is a feature which allows the production of an ancestor hierarchy similar to what you find in Ruby classes just as it is needed by your code.  With it you can override previous members of a tag and expect to have access to its super members as part of the call, just like you would with classes.  But, this inheritance is all going on in the mix-in --the Modular Closure.  Families of traits can be built with the use of this and the previous versioned inheritance, and unlike class inheritance be readily applicable to any target.

We have chosen to keep the code obfuscated **for now** because we are a small company and we need to protect our germinating intellectual property.  We take great pride in providing significant value at minimal cost.  Our guiding principle through out it all has been keeping new constructs to a minimum.  There are enough libraries out there which enhance the base Ruby language in many interesting ways but which also bring with them added complexity and a big learning curve.  We on the other hand took an outer minimalistic approach requiring a lot more behind the scenes.  Simplicity takes work.  We hope that all this work is to your liking.

Advantages Of Trait Injector Based Programming
------------------------------------
* Trait Injectors avoid the perils of monkey patching.  You can just create a new version of the trait and leave the old one alone.
* Traits are inherited from their ancestors and can be mixed in with any target.
* With Traits runtime versioning is possible and traits can be upgraded with new versions of the trait.
* Traits can be injected, extended, cancelled, silenced, reinstated, tagged, versioned, and updated.
* Traits enable new and different coding patterns.

---

Basic Methods
--------------------------
There are some basic methods to Jackbox.  These are just rudimentary helpers, which in effect appear to be a form of syntax sugar for every day things.  But, behind their apparent sugar coating lie some additional capabilities as shown the deeper you delve into Jackbox.  For more on them read the following sections, but their preliminary descriptions follow here:

#### #decorate :sym, &blk 
This method allows for decorations to be placed on a single method whether an instance or class method without too much fuss. One important thing about #decorate is that it works like #define_method, but in addition, it also makes possible the use of Ruby's #super within the body of the decorator.  It really presents a better alternative and can be used instead of #alias\_method\_chain.

At the class level:
    
    class One
      def foo
        'foo'
      end
    end
        
    class One
      decorate :foo do
        super() + 'decoration '                   # super available within decoration
      end
    end

    One.new.foo.should == 'foo decoration'

Or, at the instance level:

    one = One.new

    one.decorate :foo do |arg|
      super() + arg                               # again the use of super is possible
    end

    one.foo('after').should == 'foo decoration after'

It also works like so:

    Object.decorate :to_s do
    	super() + " is your object"
    end
    
    Object.new.to_s.should match(/is your object/)


#### #with obj, &blk 
There is also a new version of the #with construct.  The important thing to remember about #with is it has a primary context which is the object passed to it, and a secondary context which is the object you are making the call from.  This allows you to work **with** both contexts at the same time and works as a shortcut between contexts. Used in this fashion it can abstract some of the tediousness of an explicit self in some calls. The other thing about #with is that it allows you to directly place definitions on the object you pass in using its most natural form based on whether it's an instance of Object or Module.  Then it returns the same object you passed into it after the block has done processing it.  You can also pass multiple objects: #with a, b, c for example and the same block applies to all returning a, b, c afterwards.  There are some other nuances to #with later on.

Here is some sample usage code:

    class One
      def meth1(arg)
        'in One ' + arg
      end
    end

    class Two
      def meth2(arg)
        'and in Two ' + arg
      end
      def meth
        with One.new do                           # context of One and Two available simultaneously!!!
          return meth1 meth2 'with something'         
        end                                       # return object
      end
    end

    Two.new.meth.should == 'in One and in Two with something'

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
We could say, this is simple syntax sugar.  It adds readability to some constructs, and it allows the creation of local or global procs using a more friendly syntax. But #lets, also opens the door to a new coding pattern using class constructors.  See below.  The important thing about #lets is that it always defines some lambda/proc/method.  It's use apparently differs from that of #define_method only in spirit, but its use with respect to class constructors shows another side to #lets.  Aside from this however, #lets is mostly for one liners.  Here are some examples:

As a shortcut for define_method. Use it for short functional definitions:

    lets( :meth ){ |arg| arg * 2 }                # read as: lets define symbol :meth to be ....
    meth(3)															
    # => 6 

Can be used to define a special values or pseudo-immutable strings:

    lets(:foo){ 3+Math::Pi }                      # read as: lets set :foo to value
    lets(:faa){ 'some important string' }
    
To define local functions/lambdas. Define symbols in local scope:

    def main
      lets bar =->(arg){ arg * arg }              # read as: lets set bar to lambda/proc 

      # later on ...

      var = bar[3]                                # bar is only available within #main
      #...
    end															

Also see Class Constructors below.


Trait Injectors
----------
Trait Injectors are the main tool in Jackbox at the time of this writing. These again are a form of mix-in that have properties of both a closure and a module.  They can also be thought of as an **extended closure** if you will or as a special kind of mix-in if you like.  In the sections below we will discuss some of the methods available to you with Jackbox in connection with Trait Injectors, as well as elaborate on some of the other properties of traits. But, it is essential to understand there are some syntactical differences to Trait Injectors with respect to regular modules.  We will show them first, with some examples: 

**TRAIT INJECTORS ARE DECLARED IN THE FOLLOWING WAYS:**


    injector :name

    #  or...

    Name = injector :name

    # or even ...

    trait :Name                                    # capitalized method, using alias #trait 


Their use and semantics are somewhat defined by the following snippet.  But, to fully understand their implications to your code, you have to understand the sections on injector versioning, their behavior under inheritance, and also trait directives. 

    # somewhere in your code
    include Injectors

    injector :my_trait                          # define the injector 
    
    my_trait do                     
      def bar                  
        :a_bar
      end
    end

    # later on...
    widget.extend my_trait                      # apply the injector
    
    widget.bar
    # => bar
    
    # or...  
    
    Mine = my_trait
    class Target
      inject Mine                               # apply the injector
    end
    
    Target.new.bar
    # => bar
    

**TRAIT INJECTORS HAVE PROLONGATIONS:**

    injector :my_trait

    my_trait do                                # first prolongation

      def another_method
      end

    end

    # ...

    my_trait do                                # another prolongation

      def yet_another_method
      end

    end
    
Prolongations become versions once applied or tagged.  See Tagging/Naming below.  But, in lieu of this, they remain in the Virtual Method Cache (see below) in an un-versioned state and are available to any client.  

#### #trait/#injector :sym
This is a global function.  It defines an object of type Injector with the name of :symbol.  Use it when you want to generate a Trait Injector object for later use.  The symbol can then be used as a handle to the trait whenever you need to prolong the trait by adding methods to it, or to apply it to a target generating a version.  Additionally, this symbol plays a role in defining the trait's scope.  Injectors with capitalized names like :Function, :Style, etc have a global scope.  That is, they are available throughout the program, regardless of where they are defined.  Here is the code:

    class A
      injector :Function                      # defined
    end

    class B
      include Function()                      # applied
    end

    # This is perfectly valid with trait injectors

On the other hand Traits Injectors with a lower case name are only available __from__ the scope in which they were defined, like the following example shows:

    class A
      trait :form
    end

    class B
      include form                                # This genenerates and ERROR!                                 
    end                         
                      
    class B
      include A.form                              # This is valid however!
    end


For all this to happen Jackbox also introduces some additional constructs, namely the keywords #inject and #enrich.  These can be thought as simply new corollaries to #include and #extend. In fact they can be used interchangeably.  If you're working with traits you may want to use them instead, depending on context, to make clear your intent.  Also #inject is public on classes (not on other traits) while #include is not.

#### #include/inject *t
This method is analogous to ruby's #include but its use is reserved for Trait Injectors.  The scope of this method is the same as the scope of #include, and its intended use like that of #include is for class definitions. Use it to "include" a trait into a receiving class.  Also takes multiple traits.  The order of precedence is like that of ruby's #include from left to right.

#### #extend/enrich *t
This method in turn is analogous to ruby's #extend. The scope of this method is also the same as that of #extend, and its intended use is for object definition.  Use it to "extend" the receiver of a trait.  Also takes multiple traits with the same order of precedence.

**IMPORTANT NOTE: Trait Injector lookup follows the method and not the constant lookup algorithm.**

If you need to follow constant lookup, here is the code for that:

    Name = trait :sym ....                     # this also creates a hard tag (see below)

### Trait Injector Versioning

One of the most valuable properties of Jackbox is Trait Injector Versioning.  Versioning is the term used to identify a feature in the code that produces an artifact which contains a certain set of methods and associated outputs, and which represents a snapshot of that trait up until the point it's applied to an object.  From, that point on the object contains only that version of injector methods, and any subsequent overrides to those methods on the trait injector are only members of the "prolongation" of that trait and do not become part of previous targets unless some form of trait re-injection occurs. Newer versions of a trait only become part of newer targets or newer trait injections into existing targets.  With Jackbox Injector Versioning, two different versions of the same code object can be running simultaneously. 

We'll use some examples to illustrate the point.  This is how versioning occurs:

    # trait injector declaration
    #___________________
    injector :my_trait do 															
      def bar
        :a_bar                                  # version bar.1
      end
      def foo
      	# ...
      end
    end

    ###############################################
    # First object has a preferred version        #
    ###############################################
    
    object1.extend my_trait                     # apply the trait --first snapshot
    object1.bar.should == :a_bar                # pass the test


    # trait injector prolongation
    #__________________
    my_trait do 																			
      def bar
        :some_larger_bar                        # version bar.2 ... re-defines bar
      end
      # ...
    end
    
    ###############################################
    # Second object has now its preferred version #
    ###############################################

    object2.extend my_trait                     # apply the trait --second snapshot
    object2.bar.should == :some_larger_bar      # pass the test


    ###############################################
    # First object has kept its preferred version #
    ###############################################
    
    object1.bar.should == :a_bar                # bar.1 is still the one


When trait re-injection occurs, and only then does the new version of the #bar method come into play. But the object remains unaffected otherwise, keeping its preferred version of methods.  The new version is available for further injections down the line and to newer client code but existing targets are untouched.  Internal local-binding is also preserved.  If a trait is then re-injected on an instance only then does the instance get updated with the newer version.  Here is the code:

    # re-injection
    #_________________
    object1.extend my_trait                     # re-injection --third snapshot

    ###############################################
    # First object now has the updated version    #
    ###############################################

    object1.bar.should == :some_larger_bar      # bar.2 now available

Re-injection on classes is a little bit trickier, because class injection is more pervasive.  To re-inject a class with a new trait we must use the Strategy Pattern (see below or the rspec files) or we have to use private #update's.  Here is an example of Injector Versioning as it pertains to classes:

    # trait injector declaration:
    #___________________
    injector :Versions do
      def meth arg                                # version meth.1
        arg ** arg
      end
    end

    class One
      inject Versions()                           # apply --snapshot
    end


    # trait injector prolongation:                              
    #_________________
    Versions do
      def meth arg1, arg2                         # version meth.2 ... redefines meth.1
        arg1 * arg2
      end
    end

    class Two
      inject Versions()                           # apply --snapshot
    end

    ##############################################
    # Two different trait versions coexisting    #
    ##############################################

    One.new.meth(3).should == 27                  # meth.1
    Two.new.meth(2,4).should == 8                 # meth.2 


To update the class, we then do the following:
    
    class One
      update Versions()                           # private call to #update
    end
    
    ##############################################
    # class One is now updated to the latest     #
    ##############################################

    One.new.meth(2,4).should == 8                 # meth.2 
    Two.new.meth(2,4).should == 8                 # meth.2 
    

### Tagging/Naming

The use of Tags is central to the concept of Versioning.  In a similar fashion to a version control system tags play a role in formalizing a set of changes, but unlike its more mundane sibling these changes represent actual object function and methods.  Once a prolongation is tagged the it is always available in the same state and can be depended upon by any object needing that version of the functionality.  More importantly once a tag is defined it should not be changed, and Jackbox goes to some lengths to prevent you from doing this.  Of course this is Ruby out very own intent is to move from Play-doh to Plasticine.  Tagging happens in the following ways:

    Version1 = trait :function do
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

Version1 and Version2 are two different hard tags of the same Trait Injector.  They introduce a more formal approach to trait versioning and also pave the way for the two different inheritance models described in the introduction.  Aside from hard tags, there are also soft tags (see below).  

### Local Binding

Before we move on, we also want to give some further treatment to injector local-binding.  That is, the binding of a traits' methods is local to the prolongation/version in which they are located before the versioning occurs.  Here, is what we mean by that:

**Note: In the following examples we use the notion of version naming/tagging.  Once a version is tagged it shouldn't be modified.  These tags comprise entities along the hierarchical structure of a trait explained further below.**
                                                          

    # trait declaration
    #_____________________

    Version1 = trait :functionality do
      def basic arg                               # version basic.1
        arg * 2
      end
    end
    o = Object.new.extend Version1                # apply --snapshot (like above)
    
    

    # trait prolongation
    #_____________________

    Version2 = functionality do
      def basic arg                               # version basic.2
        arg * 3                                   # specific use in compound.1
      end

      def compound                                # compound.1 
        basic(3) + 2                                      
      end
    end
    p = Object.new.extend Version2                # apply --snapshot (like above)
    
                                               
    ####################################################
    # #compound.1 bound to the right version #basic.2  #
    ####################################################
    
    p.basic(1).should == 3                        # basic.2 
    p.compound.should == 11                       # compound.1 --bound locally to basic.2
    
    o.basic(1).should == 2                        # basic.1 
    o.compound.should == 11                       # compound.1 --bound locally to basic.2
    
    
Versioning together with local-binding allow the metamorphosis of traits to fit the particular purpose at hand, keeping those local modifications isolated from the rest of your program, and allowing your code to naturally evolve with your program.  They cancel the need to monkey patch anything.  If you need a local version of some code just open up a prolongation create the new version, inject it in to your targets, and leave the older versions and clients untouched.

### Virtual Method Cache (VMC)

When you are working with a trait injector in irb/pry it is often easier to just add methods to the trait without actually having to re-apply the trait to the the target to see the result.  This is just what the Virtual Method Cache is for **among other things.**  The VMC allows working with traits like you would with regular modules.  It also enhances the normal method resolution of modules into that of modules in the chain but who are not directly applied to the target.  Here is what the VMC looks like:

    # definition
    #_______________
    injector :SomeTrait
    
    # application
    #_______________
    class MyClass
      include SomeTrait                           # Application (with no methods)
    end
    
    obj = MyClass.new
    
    SomeMethods do
      def spm1                                    # #spm1 is only defined in the Virtual Method Cache
        :result                                   # It is not actually part of the MyClass yet!!
      end                                         # until this version/prolongation is applied
    end
    
    expect(obj.spm1).to eq(:result)               # yet my obj can use it --no problem
    
The key idea here is that the Virtual Method Cache is the same for all versions of the Injector and all its applications.  This is what allows working with traits as if they were regular modules.  If we redefine VMC methods they are also redefined for all versions.  To actually lock the method versions into place you must apply the Injector with the methods defined in it that you want the version to have.  To then change that application of the trait you then re-inject the target.  But the VMC, provides a scratch pad of methods for you to work with.  The VMC also provides extended method resolution to the injector.  To understand what we mean by this, take a look at following code:

    class Client
      include trait :J1
    end
    J1 do
    	def n1m1
    	end
      include trait :K1
    end
    K1 do
    	def n2m1
    	end
      include trait :L1
    end
    L1 do
      def n3m1
      end
    end

    Client.new.n1m1
    Client.new.n2m1
    Client.new.n3m1
    
Think of how this would be different with regular modules.  For this to happen using regular Ruby modules, K1 and L1 should have to be defined and included prior to their inclusion into our client.  And no it is not just a matter of moving the include to the beginning of each container.

#### #define\_method sym, &blk
There is one more interesting property to method definition with Trait Injectors however. The use of #define\_method to define/re-define methods in any prolongation affects the entire trait and all its versions except for any hard tagged as these are exactly that hard.  This also preserves a fundamental tenet of traits: take some local context, enclose it, and use the trait to introduce it to some indiscriminate target, and additionally has some other uses as we'll see with in our description of Jackbox patterns and trait composition.  

Here is an example of the difference with #define\_method:

    # define trait
    #_________________________
    injector :some_trait do
    	def meth
    	  :meth
    	end
    	
    	def foo_bar
    		'a foo and a bar'
    	end
    end

    class Client                                  
      inject some_trait                           # Injector appplied
    end                                           

    # test it
    
    Client.new.meth.should == :meth
    Client.new.foo_bar.should == 'a foo and a bar'      

    # new prolongation
    #________________________
    some_trait do                                  
    	def meth                                    
    	  puts :them
    	end
    	
    	define_method :foo_bar do                   # new method version
    		'fooooo and barrrrr'
    	end
    end     
                                                  
    ################################
    # Like above!                  #
    # No re-injection == No change #
    ################################

    Client.new.meth.should == :meth 
                  
    ################################
    # Different!!!                 #
    # No re-injection == Change    #
    # . Thanks to define_method    #
    ################################
                                                  
    Client.new.foo_bar.should == 'fooooo and barrrrr'                          
                                                  
This also allows the introduction of what we have termed a new coding pattern based on the late binding of decorators (see below). 

### Trait Injector introspection
Trait Injectors have the ability to speak about themselves.  Moreover traits can speak about their members just like any module or class, and can also inject their receivers with introspecting capabilities.  Every injected/enriched object or module/class can enumerate its traits, and traits can enumerate their members, and so forth.  
    
    injector :Function do
      def far
      end
      def close
      end
    end
    
    trait :Style do
    	def pretty
    	end
    end

    class Parent
      inject Function()
    end

    class Child < Parent
      inject Style()
    end
    
    # a trait's class
    
    Function().class.should == Injector                 
    Style().class.should == Injector 
    
    Injector == Trait

    # traits methods
    
    Function().instance_methods.should == [:far, :close]      
    Style().instance_methods.should == [:pretty]    

    # later on...

    Child.cancel *Child.traits       

#### #traits/#injectors *sym
Called with no arguments returns a list of traits.  A call with a list of trait symbols however returns an array of actual Trait Injector objects matching the names supplied in a LIFO fashion. The method also extends into a micro API.  An example use goes like this:

    #traits   --(in this target)
    
      Child.traits 
      => [(|Style|:#942460)] 
    
    #traits :all   --(all traits in hierarchy)
    
      Child.traits :all
      => [(|Function|:#944120), (|Style|:#942460)] 
      
    #traits *sym
    
      c = Child.new.extend Style()
      c.traits :Style
      => [(|Style|:#942460), (|Style|:#890234)] 
                                                   
    
    #traits.by\_name *sym  --(names only)
    
      Child.traits.by_name.should == [:Style] 
      Child.traits(:all).by_name.should == [:Function, :Style]
      # also aliased to :sym_list
    
    #traits.collect\_by\_name *sym  --(all #traits of :name, same as #traits *sym  from above)
    
      Child.traits.collect_by_name :Style
       => [(|Style|:#942460)]
     
      Child.traits :Style
       => [(|Style|:#942460)]
     
      Child.traits :Function
       => nil
     
      Child.traits :all, :Function
       => [(|Function|:#944120)]                    

      Child.traits(:all).collect_by_name :Function
       => [(|Function|:#944120)]                    
      # also aliased to :all_by_sym
    
    #traits.find\_by\_name *sym  --(highest ranking trait by :name)

      Child.traits.find_by_name :Style       # last one in first out
      => (|Style|:#942460)

      Child.traits.find_by_name :Function
       =>nil
       
      Child.traits(:all).find_by_name :Function
       => (|Function|:#944120)                    
      # aliased to last_by_sym
    
#### #history alias #versions
This method returns a trace of all the applied trait injector versions ordered based on the order in which they are created.  It also includes the version hard tags and soft tags which can also be specifically accessed through the #tags method below.  It is primarily a view of all existing versions of a trait. Here is the code:

    # create our trait and
    # host it a couple of times
    
    trait :HistorySample
    extend HistorySample(), HistorySample()
    
    # expect the following
    
    expect(HistorySample().history.size).to eq(2)
    expect(traits).to eq(HistorySample().history)
    expect(HistorySample().history.last).to eql(traits.last)
    expect(HistorySample().history.last).to eql(HistorySample())
    
    # create a hard tag
    
    HistorySampleTag = HistorySample()
    
    expect(HistorySample().history.size).to eq(3)
    expect(HistorySample().history.last).to equal(HistorySampleTag)
    
    # create a soft tags
    
    HistorySample(:tag) do
      # some definitions
    end
    
    expect(HistorySample().history.size).to eq(4)
    expect(HistorySample().history.last).to equal(HistorySample())
    
#### #tags
This method traces tags only.  It also extends into a micro API returning hard and soft tags independently. Here is the code:

    # at this point from the above...
    
    #tags
    
      expect(HistorySample().tags.size).to eq(3)
    
    #tags.hard
    
      expect(HistorySample().tags.hard.size).to eq(1) 
      HistorySample().tags.hard
       => [(HistorySampleTag:|HistorySample|)]
       
    #tags.soft
    
      expect(HistorySample().tags.soft.size).to eq(2) 
      HistorySample().tags.hard
      => [(|HistorySample|:#234435),(|HistorySample|:#876679)]

Hard tags are an aid to inheritance while soft tags help with composition.  For more on this take a look at the Solutions Pattern below for an application of soft tags and at JITI (Just-In-Time Inheritance) for and example of hard tags and its connection to inheritance.  See also the Jackbox blog at <a href="http://jackbox.us">http://jackbox.us</a> and the rspec files for the project.

#### #precedent and #progenitor (alias #pre, #pro)
The #pre method gets the previous element in the history. Here is the code:

    # create the trait
    trait :HistorySample

    # create some history
    extend HistorySample(), HistorySample()
                         
    # expect the following
    expect(HistorySample().history.last.precedent).to equal(HistorySample().history.first)
        
For more on this see the rspec files.     

### Other Capabilities of Trait Injectors

The functionality of Trait Injectors can be removed from individual targets, whether class or instance targets, in various different ways.  This allows for whole 'classes' of functionality to be removed or withdrawn and then made available again at whim and under programer control.  The first method of injector withdrawal is trait canceling or ejection.  This is where a trait is completely removed from a target precipitating further calls on the trait to generate an error.  Second there is trait silencing and reactivation.  This on the other hand allows for the temporary quieting of a trait but which may need to be reactivated at a later time.  Trait canceling or ejection can take place at the instance or the class level. 

Here we have a Trait Injector removed after an #enrich to individual instance:
	
    class Coffee
    	def cost
    		1.00
    	end
    end
    trait :milk do
    	def cost
    		super() + 0.50
    	end
    end

    cup = Coffee.new.enrich(milk)
    friends_cup = Coffee.new.enrich(milk)

    cup.cost.should == 1.50
    friends_cup.cost.should == 1.50

    cup.cancel :milk

    cup.cost.should == 1.00

    # friends cup didn't change price
    friends_cup.cost.should == 1.50

Here it is removed after an #inject at the class level:

    # create the injection
    class Home
    	trait :layout do
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

	
The code for these examples makes use of the #cancel alias #eject method which opens the door to this additional functionality provided by traits.  See also the Strategy Pattern just below this. It is important to keep in mind that ejection is "permanent" (not really, can always be re-injected) and that this permanence is more of its intent.  There are other ways to control code presence in targets through the use of Injector Directives.  See below.  For more on this also see the rspec examples.

#### #cancel *sym  (alias #eject)
This method cancels or ejects trait function from a single object or class.  It is in scope on any classes injected or enriched with a trait.  Its effect is that of completely removing one of our modular closures from the ancestor chain.  Once this is done method calls on the trait will raise an error.  

### Injector Directives
Once you have a trait handle you can also use it to issue directives to the trait.  These directives can have a profound effect on your code.  There are directives to silence a trait, to reactivate it, to create a soft tag, or to completely obliterate the trait including the handle to it.

#### :silence/:collapse directive
This description produces similar results to the one for trait ejection (see above) except that further trait method calls DO NOT raise an error.  They just quietly return nil. Here are a couple of different cases:

The case with multiple object instances:

  	trait :copiable do
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
  		trait :code do
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


#### :active/:rebuild directive
Trait Injectors that have been silenced or collapsed can at a later point be reactivated.  Here are a couple of cases:

The case with multiple object receivers:

    trait :reenforcer do
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
  		trait :ThinFunction do
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
  	
#### :tag/:version directive
This directive creates a soft tagged version of a trait.  For more on this see Soft Tags below.
  	
#### :implode directive
This directive totally destroys the trait including the handle to it.  Use it carefully!

    class Model
    	def feature
    		'a standard feature'
    	end
    end

    trait :extras do
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

### Soft Tags
Just like hard tags above but a name is not needed.  They come about by the :tag directive from above and are intended as markers for versions of algorithms that need to be accessed at a later time on demand.  For more on this see the Solutions Pattern below.

    jack :SomeJack do
      def foo
        :foo
      end
    end
    SomeJack :tag                       # Unnamed version

    SomeJack(:tag) do                   # New unnamed version
      def foo
        :foooooooo
      end
    end

Accessible through trait#tags (an Array).  Also available **trait#tags.hard** and **trait#tags.soft**.  See introspection above.

### Trait Injector Equality and Difference 

Injectors can be compared.  This allows further introspection capabilities which can be used to determine if a certain piece of code possesses a certain block of capabilities, test if those are "equal" to some other component's capabilities in terms of duck types, or determine what the difference is.  This is similar to what you would find with simple modules, but capabilities are compared on a method basis.  It only follows that if traits can be applied and withdrawn from any target we should be able to test for their similarities to other traits.  Injector difference is the complement to all this, and it finds the actual delta between traits and returns those differences.  

Here is how equality is defined:

    # equality
    ######################################

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
		injectors.first.should == E()		# same
		
		# but
		E().should == E() 							# always
		E().should == E().spec 					
		E(:tag).should == E()	
		


Inequality is based on a trait injector's methods.  Once you add method definitions to a trait, that trait tests as an inequality to its precedent provided this is not the original (#spec) injector.  This original trait is also the #pre and #pro to all others. It always tests as equal to its handle, but versions past or since do not.  A different injector with the same methods is also not equal to the trait.

Here is how inequality is defined:

    # inequality
    ######################################

		E().should_not == F()

    # if some E () definitions **
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

Difference is deeper than simple inequality.  It returns the actual delta between what you have and what you pass in to the call as an array of two elements.  The first element is comprised of the methods common to both operands, the second is the delta from the first to the second.  This method also exposes a micro API.  Furthermore, the elements of the array which are special arrays themselves also return a partial trait with their actual injector payload which can be used in further trait injection.  Here is how difference is defined:

#### #trait.diff ver=nil

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


    #diff.join.injector
    #diff.delta.injector
    
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
		
    

The version argument can be negative index (-1, etc), or another version.  By default, it uses the previous version.  NOTE: the previous version of an un-altered trait is equal to the trait.  Again, for more on this see the rspec files.

### Trait Injector composition
The composition of multiple traits into an object can be specified as follows:

    include Injectors
    
    # declare traits
    trait :FuelSystem                          # capitalized methods
    trait :Engines
    trait :Capsule
    trait :Landing

    # compose the object
    class SpaceShip
    
    	inject FuelSystem(), Engines(), Capsule(), Langing()    # capitalized method use

    	def launch
    		gas_tank fuel_lines burners ignition :go              # call through the VMC
    		self
    	end
    end
    
    Spaceship.traits.by_name == [:FuelSystem, :Engines, :Capsule, :Landing]

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
    	define_method :gear do                      # a closure of surrounding context
    		var
    	end
    end
    
For full examples see the rspec code.  One thing to note is the difference between defining function through the VMC, which allows working with traits already applied to targets and predefining function of a trait before application and versioning.  The first allows a flow similar to that of regular modules and the later makes use of the true nature of trait injectors and allows customizing trait injectors to their targets.

### Unbound Dependency (Soft Ancestors)

Another important feature of trait injectors is a property of injectors to combine with other traits in multiple ways (with different function or precedence) without actually permanently binding to any of their ancestors or their function.  This on-the-fly soft binding allows for multiple combinations of form and function from the same basic components.  This is another area where Jackbox mix-ins go beyond what is possible with regular modules. In the following example we combine the same injectors in this (soft) way to derive different function.

    #####
    # injector declarations

    injector :drive do
      def drive_result
        payload * 2
      end
    end

    trait :strings do
      def payload
        '+++++'
      end
    end

    trait :numbers do
      def payload
        10
      end
    end

    #####
    # soft ancestry declarations

    Result1 = drive strings
    Result2 = drive numbers


    class Driven
      include Result1
    end

    Driven.new.drive_result.should == '++++++++++'


    class Driven
      update Result2
    end

    Driven.new.drive_result.should == 20


    #################################
    # remain unbound to ancestry
    #################################

    drive.ancestors.should == [drive]

    #################################
    # ----------amazing-------------
    #################################

Granted this is a somewhat contrived example but you get the idea.  Think again how is this different than what is available from modules.  With modules once one module is included in another that relationship is permanent.  With Jackbox trait injectors and soft ancestors the same components can be reused in multiple bindings tying their function locally only but remaining globally decoupled.

### Inheritance
Inheritance with trait injectors comes in two flavors.  The first form comes from the normal versioning of a trait.  The second comes from JITI which follows a model similar to what you find in regular classes.  With versioning a trait injector inherits all the function from its progenitor allowing customization of only the parts needed for the specific application at hand but cannot call upon previous versions of itself.  With JITI this later dimension of access to its own ancestry is possible.

But before we get into all this, the behavior of Trait Injectors under normal class inheritance is also of interest.  Trait injectors act upon a class and its children.  Introspection on traits under class inheritance is possible and is achieved with the :all directive on the #traits/#injectors method.  The behavior of trait injectors under normal class inheritance is partially specified by what follows:

    injector :j

    class C
    end

    C.inject j {                                  #foo pre-defined at time of injection
      def foo
        'foo'
      end
    }
    C.traits.by_name.should == [:j]
    C.new.traits.by_name.should == [:j]

    C.new.foo.should == 'foo'

    # D inherits from C

    class D < C                                   # methods are inherited from j 
    end
    D.traits.by_name.should == []
    D.traits(:all).by_name == [:j]

    # New Objects
    C.new.foo.should == 'foo'											
    D.new.foo.should == 'foo'

For more on this also see the rspec files. 

More importantly though is the inheritance native to injectors.  The following example touches on the first form of native trait injector inheritance, the inheritance due to versioning.  Here we have an example of how inheritance due to versioning can be harnessed to promote the re-use of common elements.  Like previously stated, the concept of tagging/naming also plays an important role with inheritance as illustrated in the following code:

    trait :player do                       
    	def sound                               
    		'Lets make some music'                
    	end                                     
    end                                       

    TapePlayer = player do                        # TapePlayer version tag
    	def play                                    # --inherirts #sound
    		return 'Tape playing...' + sound()                          
    	end                                     
    end                                       

    CDPlayer = player do                          # CDPlayer version tag
    	def play                                    # --also inherits #sound
    		return 'CD playing...' + sound()
    	end
    end

    class BoomBox
    	include TapePlayer

    	def on
    		play
    	end
    end
    
    class JukeBox < BoomBox                       
    	inject CDPlayer                             # Mixed class and injector inheritance models
    end


The different versions inherit all of the pre-existing methods from the previous one and "freeze" that function.  We can either Tag/Name them for later use or simply include/extend then into a new target, but the function is fixed at that time.  Tags cannot be modified or more clearly shouldn't be modified.  Classes retain the fixed version of the trait until the time an update is made.  But, trait injectors then also inherit new methods through the VMC (see above).  For more on all this see, the Rspec examples.

### Just-In-Time Inheritance (JITI)

This flavor of the inheritance model on the other hand allows our modular closures to have similar properties to the inheritance of classes.  With it you can expect to have access to the trait's super/ancestor members as part of the call, just like you would with class inheritance. In addition to the inheritance resulting from versioning, JITI presents a more complete scenario adding color to the inheritance picture painted by trait injectors with one caveat, we must be aware of colluding ancestry when creating decorators based on JITI.  This very narrow case is explained in the specs and Jackbox itself warns you of this however.  The key takeaway here is: trait injectors are a form of mix-in that share a similar inheritance model with classes, but all happening in the mix-in however. You can version them to gain access to versioned inheritance or you can tag and then override its members to access an ancestor chain comprised of all previous tags.  As always we will use some example code to illustrate:

    # 
    # Our Trait Injector
    # 
    Tag1 = injector :Functionality do
    	def m1
    		1
    	end
	
    	def m2
    		:m2
    	end
    end

    # 
    # Normal versioned inheritance
    # 
    Functionality do
    	def other  					
    		'other'						# -- same ancestors as before
    	end 								
    end
    expect(Functionality().ancestors).to eql( [Functionality()] )

    #####
    # test function

    o  = Object.new.extend(Functionality())

    o.m1.should == 1
    o.m2.should == :m2
    o.other.should == 'other'


    #
    # JITI
    # 
    Tag2 = Functionality do
    	def m1							# The :m1 override invokes JIT Inheritance
    		super + 2					# -- Tag1 is summoned into ancestor chain
    	end 								# -- allows the use of super
	
    	def m3							
    		'em3'
    	end
    end

    #####
    # test it

    p = Object.new.extend(Tag2)

    # JIT inherited
    p.m1.should == 3

    # regular inheritance
    p.m2.should == :m2
    p.m3.should == 'em3'
    p.other.should == 'other'

    expect(Functionality().ancestors).to eql( [Functionality(), Tag1] )
    expect(Tag2.ancestors).to eql( [Tag2, Tag1] )

### The Rules of JITI

JITI (Just-In-Time Inheritance) is governed by a set of rules framing its behavior.  Here are these rules and their descriptions:

1. JITI works like class inheritance but at the mix-in.  It holds onto method definitions of earlier version hard tags.  It lets you override or rebase (start fresh) individual methods at any level.  It works for object extension.  It works for class inclusion.  
2. The trait injector handle (its access method) is always in sync with the last hard tag.  This also means the injector definitions use the last hard tag as a departing base for any further changes.
3. It allows initial external basing and also external base substitution.  A trait injector can be based on an external trait or even module serving as a shell or casing for external function as long as any internal definitions don't overwrite the external ones.
4. It forces internal basing once instated.  Definitions internal to the trait injector always take precedence over external definitions by the same signature.  This blocks external ancestor intrusion enforcing internal injector consistency. 
5. It works with the VMC.  Like all trait injectors, the VMC is always available, acting as a cache of methods available globally to all versions of the injector and which fills in those version methods from the main injector onto its descendants, supplementing this inheritance models as well.
6. It works with directives.  Like all trait injectors, JITI trait injectors respond to normal injector directives.  Here they work to cancel and reinstate entire trait hierarchies.

For more on all of this please see the rspec files in the GitHub project, or visit our blog at http://jackbox.us.  But, this is the basic idea here.  Trait injectors are an extended modular closure which can be used as a mix-in and prolonged to add function, shaped, versioned, tagged, and overridden to fit the purpose at hand. With trait injectors however you avoid the perils of monkey patching.  You can just create a new version of the injector and leave the old one alone.  They allow you to combine work flows from both modules and traits through the use of the VMC.  They provide inheritance in enhanced forms and a compositional model that loosely couples member traits.  Finally, they work under code directives.  Moreover, using trait injectors Jackbox also goes on to solve some traditional shortcomings of Ruby with some of the GOF(Gang of Four) object oriented patterns.  

---


### The GOF Decorator Pattern:   
Traditionally this is only partially solved in Ruby through PORO decorators or the use of modules.  However, there are the problems of loss of class identity for the former and the limitations on the times it can be re-applied to the same object for the latter. Here are a couple of articles on the matter: <a href="https://robots.thoughtbot.com/evaluating-alternative-decorator-implementations-in">Evaluating Alternative Decorator Implementations</a> and <a href="http://nithinbekal.com/posts/ruby-decorators/">Decorator Pattern in Ruby</a> With Jackbox however all of this is solved.  A trait injector used as a decorator does not confuse class identity for the receiver. Decorators are useful in several areas of OOP: presentation layers, string processing, command processors to name a few.  Here is the code:

    class Coffee
    	def cost
    		1.50
    	end
    end

    trait :milk do
    	def cost
    		super() + 0.30
    	end
    end
    trait :vanilla do
    	def cost
    		super() + 0.15
    	end
    end

    cup = Coffee.new.enrich(milk).enrich(vanilla)
      cup.should be_instance_of(Coffee)

    cup.cost.should == 1.95


Additionally, these same decorators can then be re-applied MULTIPLE TIMES to the same receiver.  This is something that is normally not possible with the regular Ruby base language.  Here is the code:

    cup = Coffee.new.enrich(milk).enrich(vanilla).enrich(vanilla)

    # or even...

    cup = Coffee.new.enrich milk, vanilla, vanilla

    cup.cost.should == 2.10
    cup.should be_instance_of(Coffee)
    cup.traits.should == [:milk, :vanilla, :vanilla]

    # Important Note:
    # vanilla and coffe can be div tags 
    # and other markup in html or... 

	
### The GOF Strategy Pattern:
Another pattern that Jackbox helps with is the GOF Strategy Pattern.  This is a pattern which changes the guts of an object as opposed to just changing its outer shell. Traditional examples of this pattern in Ruby use PORO component injection within constructors, and then a form of delegation.  With Jackbox Trait Injectors all this is eliminated.  

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


    trait :sweedish do
    	def brew
    		@strategy = 'sweedish'
    	end
    end

    cup = Coffee.new.enrich(sweedish)           # clobbers original strategy for this instance only!!
    cup.brew
    cup.strategy.should == ('sweedish')

But, with #cancel/#eject it is possible to have an even more general alternate implementation. This time we completely replace the current strategy by actually ejecting it out of the class and then injecting a new one:

    class Tea < Coffee  # Tea is a type of coffee!! ;~Q)
    	trait :SpecialStrategy do
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

### Patterns of a Different Flavor

Jackbox Traits also make possible some additional coding patterns.  Although not part of the traditional GOF set these new patterns are only possible thanks to languages like Ruby that although not as flexible as Lisp, permit the morphing of normal forms into newer ones. We hope that as Ruby evolves it continues to give programmers more power redefining the language itself. Here are some new patterns: 

__1) Late Decorator.-__ Another flow that also benefits from #define\_method in an interesting way is the following:   

    class Widget
    	def cost
    		1
    	end
    end
    w = Widget.new

    trait :decorator

    w.enrich decorator, decorator, decorator, decorator

    # user input
    bid = 3.5 

    decorator do
    	define_method :cost do                      # defines function on all traits of the class
    		super() + bid
    	end
    end

    w.cost.should == 15

The actual decorating trait function is late bound and defined only after some other process has completed.

__2) The Super Pattern.-__ No.  This is not a superlative kind of pattern.  Simply, the use of #super can be harnessed into a pattern of controlled recursion, like in the following example: 

    trait :Superb

    Superb do
    	def process string, additives, index
    		str = string.gsub('o', additives.slice!(index))
    		super(string, additives, index) + str rescue str
    	end
    	extend Superb(), Superb(), Superb()
    end   

    Superb().process( 'food ', 'aeiu', 0 ).should == 'fuud fiid feed faad '
    Superb(:implode)                                 

__3) The Solutions Pattern.-__  For a specific example of what can be accomplished using this workflow please refer to the rspec directory under the transformers spec.  Here is the basic flow:

    jack :Solution do
      def meth
        1
      end
    end

    Solution( :tag ) do
    	def solution
    		meth + 1
    	end
    end
    Solution( :tag ) do
    	def solution
    		meth + 2
    	end
    end
    Solution( :tag ) do
    	def solution
    		meth + 3
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

__4) The Class Constructor Pattern.-__  Our base method #lets has one more interesting use which allows for an alternative way to refine classes.  We have originally termed this Re-Classing but after further consideration and user input we have refocused the intent of this pattern and we now define it as class constructors.  Look at the following code:

		module Work
			lets String do
				def self.new(*args)
					"+++#{super}+++"
				end
			end
		end
		
		class WorkAholic
			include Work
			
			def work_method
				String('Men-At-Work')
			end
		end
	
		str = WorkAholic.new.work_method              # Our String re-class
		str.should == '+++Men-At-Work+++'

		str = String.new('men-at-work')               # Regular String
		str = 'men-at-work'
		
		str = String('Men-At-Work')										# Regular Kernel version
		str = 'Men-At-Work'
		

The important thing to remember here is that #String() is a method now. We can redefine it, name-space it, test for its presence, etc.  We can also use it to redefine the class's methods.  

    jack :Log do
    	require 'logger'

    	def to_log arg
    		(@log ||= Logger.new($stdout)).warn(arg)
    	end
    end

    String() do
    	inject Log()
	
    	def show
    		to_log self
    	end
    end
    
    str = String('don't leave a trace')
    str.show                                      # doh!!
    

For more on this see, the rspec files and the Jackbox blog at <a href="http://jackbox.us">http://jackbox.us</a>.  

#### #constructor?/#reclass?(klass)

This helper verifies a certain re-class exists within the current namespace.  It returns a boolean.  Example:

    module One
      if constructor? String
        String('our string')
      end
    end

__5. The Web Widget Pattern.__
This example uses Jackbox Ruby Traits to render web controls.  There are a couple of different variations possible which we show in the rspec files.  Here we'll use the one based on JITI.  Here is the code:

    # some data

    def database_content                # could be any model
    	%{car truck airplane boat}
    end 

    # rendering helper controls

    class MyWidget
    	def initialize(content)
    		@content = content
    	end       

    	def render
    		"<div id='MyWidget'>#{@content}</div>"
    	end
    end


    MainFace = trait :WidgetFace do     # our trait
	
    	attr_accessor :font, :width, :height       

    	def dim(width, heigth)
    		@width, @heigth = width, heigth
    	end
	
    	def render
    		%{
    			<style>
    			#MyWidget{
    				font: 14px, #{@font};
    				width:#{@width};
    				height: #{@heigth}
    			}
    			</style>
    			#{super()}
    		}
    	end
    end

    # somewhere in a view

    browser = 'Safari'                  # the user selected media
    @content = database_content


    my_widget = case browser
    when match(/Safari|Firefox|IE/)

    	MyWidget.new(@content).enrich(WidgetFace() do
		
    		def render															# override invoking JIT inheritance
    			dim '600px', '200px'									# normal inherited method call
    			@font = 'helvetica'

    			super()
    		end
    	end)

    else

    	MyWidget.new(@content).enrich(WidgetFace() do
		
    		def render															# override invoking JIT inheritance
    			dim '200px', '600px'                  # normal inherited method call
    			@font ='arial'

    			super()
    		end
    	end)

    end

    WidgetFace(:implode)
		 

For more information and additional examples see the rspec examples on this project.  There you'll find a long list of over __250__ rspec examples and code showcasing features of Jackbox Trait Injectors along with some additional descriptions.

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

There is also command line utility called **jackup** that simply allows users to bring projects up to a *"Jackbox level"*.  It inserts the right references and turns the targeted project into a bundler gem if it isn't already one also adding a couple of rake tasks.

## Availability

Jackbox is current available for Linux, Mac, and Windows versions of Ruby 1.9.3 thru 2.2.1

## Installation and Testing

Add this line to your application's Gemfile:

    gem 'jackbox'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jackbox
    
And then execute the following command inside the project directory:

    $ jackup 
    
To run the test suite inside the gem directory, run the command test-jacks.  This will run the test battery using rspec with Jackbox isolated within the confines of its own gem directory.
    
    $ test-jacks


## Support
Any questions/suggestions can be directed to the following email address: 

__service.delivered@ymail.com__.  

Please include your platform along with a description of the problem and any available stack trace.  Please keep in mind that, at this time we have limited staff and we will do our best to have a quick response time. 

Also please follow us at http://jackbox.us

## Licensing

Jackbox single use and multi-use licenses are free.
Copyright © 2014, 2015 LHA. All rights reserved.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

In the above copyright notice, the letters LHA are the English acronym 
for Luis Enrique Alvarez (Barea) who is the author and owner of the copyright.
