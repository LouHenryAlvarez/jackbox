require 'spec_helper'
=begin rdoc
	jackbox_spec
	author: Lou Henry
	:nodoc:all:
=end

include Injectors

#####
# 
# We spec the jackbox library part of this gem
# 
describe Jackbox, 'jackbox library', :library do


	#####
	# Dynamic Method decorators

	it 'adds method decorators' do
		Object.new.should respond_to :decorate
		Object.should respond_to :decorate
	end
	
	describe 'Kernel#decorate', 'dynamic specializations of a method' do
		it 'is available during class definition' do

			class One
				def foo
					'foo '
				end
			end
			class One
				decorate :foo do
					super() + 'decoration'
				end
			end
			One.new.foo.should == 'foo decoration'
		
		end
		
		it 'is available at the object instance level during execution' do

			class One
				def foo
					'foo '
				end
			end
			class One
				decorate :foo do
					super() + 'decoration'
				end
			end
			one = One.new
			one.decorate :foo do |arg|
				super() + arg
			end
			one.foo(' after').should match_regex('foo decoration after')
		
		end
		
		it 'also works like so' do
		
			Object.decorate :to_s do
				super() + " is your object"
			end
			Object.new.to_s.should match(/is your object/)
		
		end

		it 'allows ruby_c objects and singleton classes to be decorated as well' do

			Dir.singleton_class.decorate :chdir do |*args|
				puts 'Changing directory...'
				super(*args)
			end
			
			STDOUT.should_receive(:puts).with("Changing directory...")
			Dir.chdir('.').should == 0
			
			Dir.metaclass.undecorate :chdir

			STDOUT.should_not_receive(:puts).with("Changing directory...")
			Dir.chdir('.').should == 0
			
		end
		
		it 'raises an error when decorating singleton classes without returning them properly' do

			expect {
				
				class File 											# MUST USE #singleton_class or #metaclass
					class << self
						decorate :chown do |*args| end
					end
				end
				
			}.to raise_error(UserError)

			expect {
				
				class File
					metaclass.decorate :chown do |*args| 
						puts 'Changing ownership...'
						super(*args)
					end
				end
				
				File.metaclass.undecorate :chown
				
			}.to_not raise_error		
				
		end

		it 'does not work on undefined methods' do
			
			class SomeCrappyClass
			end
			
			expect {
			class SomeCrappyClass
				decorate :boo do
					:boo
				end
			end
			}.to raise_error(NameError)
		end
		
		it 'is not intended to work on plain modules' do
		
			module Am
				def off
					'off'
				end
			end
			
			class B
				include Am
			end
			
			B.new.off.should == 'off'
			
			module Am
				decorate :off do
					super() + 'on'
				end
			end
			
			expect {
				
				B.new.off.should == 'offon'			#fails!!
				
			}.to raise_error(RSpec::Expectations::ExpectationNotMetError)
			
		end
		
		it 'is not intended for plain traits either' do
			
			Aj = trait :aj do
				def off
					'off'
				end
			end
			
			class Bj
				include Aj
			end
			
			Bj.new.off.should == 'off'
			
			aj do
				decorate :off do
					super() + 'on'
				end
			end
			Bj.inject Aj
			
			expect {
				
				Bj.new.off.should == 'offon'			#fails!!
				
			}.to raise_error(RSpec::Expectations::ExpectationNotMetError)
			
		end
		
		it 'does work on trait/module metaclass' do
			
			trait :tester

			tester do
				extend self																									# extend self
																																		# Note: you cannot self enrich an trait
				def order weight
					lets price =->(weight){ 10 * weight }
					"price for #{weight} is #{price[weight]}"
				end
			end
			tester.order(50).should == 'price for 50 is 500'							# call method extended to self


			tester do
				decorate :order do |num|																		# decorate the same method
					"#{self} says: " + super(num) + ' dollars'
				end	
			end
			tester.order(50).should match(/^\(|tester|.+\) says: price for 50 is 500 dollars/) 				# call decorated method extended to self 
			
			# undecorate
			
			tester.undecorate :order
			tester.order(30).should == 'price for 30 is 300'
		end
		
	end

	describe 'redecoration' do
		
		before do
			class T
				def bar
					'bar '
				end
			end
			class U
				def bar
					'bar'
				end
			end
		end
		
		it 'allows decorating the same method multiple times' do

			class T
				decorate :bar do 																# <- GETS CLOBERED 
					super() + 'none '
				end
			end
			class T
				decorate :bar do
					super() + 'and then some'
				end
			end
			expect{T.new.bar.should == 'bar and then some'}.to_not raise_error 

		end			
		
		it 'also works on instances' do
			
			u = U.new
			
			u.decorate :bar do
				'large ' + super()
			end
			
			u.bar.should == 'large bar'
			
			u.decorate :bar do
				'small ' + super()
			end
			
			u.bar.should == 'small bar'
			
		end
		

	end
	
	describe 'undecoration' do
		
		the 'decoration can be rolled back' do

			class F
				def bar
					'bar '
				end
			end
			class F
				decorate :bar do
					super() + 'the unforseen'
				end
			end
			F.new.bar.should == 'bar the unforseen'	
			class F
				undecorate :bar
			end
			F.new.bar.should == 'bar '		 

		end

		this 'roll-back works on singleton_class also' do

			class G
				class << self
					def moo
						'moooo'
					end
				end
			end
			class G
				singleton_class.instance_eval do
					decorate :moo do
						super() + ' maaaa'
					end
				end
			end
			G.moo.should == 'moooo maaaa'
			class G
				singleton_class.instance_eval do
					undecorate :moo
				end
			end
			G.moo.should == 'moooo'

		end			

		it 'also works like so' do

			Object.decorate :to_s do
				super() + " is your object"
			end
			Object.new.to_s.should match(/is your object/)

			# undecorate

			Object.undecorate :to_s
			Object.new.to_s.should_not match(/is your object/)

		end
		
		it 'also works on object instances' do
			
			class Base
				def foo
					'foo'
				end
			end
			
			o = Base.new
			o.decorate :foo do
				super() + 'oof'
			end
			o.foo.should == 'foooof'

			o.decorate :foo do
				super() + 'foo'
			end
			o.foo.should == 'foofoo'
			
			# undecorate
			
			o.undecorate :foo
			o.foo.should == 'foo'
			
		end
		
	end



	#####
	# lets blocks
	describe '#lets' do
		
		it 'works to define local lambdas/proc' do

			lets close =->(){ 'a really local presence' }
			close.call.should == 'a really local presence'
			
		end
		
		it 'works as shortcut to define define_method' do
			
			class LetsTester
				lets(:far){ 'some great distance'}
			end
			LetsTester.new.far.should == 'some great distance'
			
		end
		
		it 'cannot evaluate a long block' do

			# $stdout.should_receive(:puts).with('perform a long evaluation for a predicate')
			expect {
				
				def tester
					lets {
						puts 'perform a long evaluation for a predicate'
					}.call if true
				end
				tester
				
			}.to raise_error(Jackbox::UserError)
			
		end

		it 'should not forbid the following' do
			
			# does work at the instance level
			expect {
				
				instance_eval {
					lets(:foo){ 'foo bar'}
				}
				
			}.to_not raise_error
			
		end
		
		it 'does allow errors to raise thru' do
			
			lets make =->(something){
				raise something
			}
			
			expect{
				make[:nothing]
			}.to raise_error(TypeError)
			
		end
	end



	#####
	# Object scoping <with> statement

	it 'adds a with statement' do
		should respond_to :with
	end 
	describe 'Object.with' do
		
		it 'includes the calling context' do
			class One
				def foo(arg)
					'in One ' + arg
				end
			end
			class Two
				def faa(arg)
					'and in Two ' + arg
				end
				def tester
					with One.new do
						return foo faa 'with something'  # context of One and Two available simultaneously!
					end
				end
			end
			expect{Two.new.tester}.to_not raise_error
			Two.new.tester.should == 'in One and in Two with something'
			
		end
		
		it 'allows the following' do
			
			a = Object.new
			with a do
				def m1
				end
			end
			b = Object.new 
			with b do
				def m1
				end
			end
			
			with a, b do
				m1
			end
			
		end
		
		it 'raises an error if used with no block' do
			
			expect{with Object.new}.to raise_error(LocalJumpError)
			
		end
		
		it 'raises an error if used on self' do
			expect{
				
				with self do
					# ...
				end
				
			}.to raise_error(ArgumentError)
		end
		
		describe "with and include" do
			it "should raise error" do
				expect{
					with Object.new do
						include Module.new
					end
				}.to raise_error(NoMethodError)
			end
		end

		it 'works with decorate on an object multiple times' do
			
			class Object
				def foo
				end
				def moo
				end
			end
			
			o = with Object.new do
				decorate :foo do
					'foo'
				end
				decorate :moo do
					'moo'
				end
			end
			o.foo.should == 'foo'
			o.moo.should == 'moo'
			
		end	
		
		it 'works with method_missing' do
			
			o = Object.new
			def o.method_missing sym, *args, &code
				:mm
			end
			#existing mm
			o.crap.should == :mm
			
			with o do
				crap.should == :mm
			end
			
			# still working
			o.crap.should == :mm
			
		end
	
	end
	
	describe 'object#with target' do
		
		class BarNone
			def bar
				:large_bar
			end
		end
		class RegularObject
			def object_tester arg
				puts arg or arg
			end
		end
		
		it 'allows access to the receiver and the object of with on different levels' do
			
			$stdout.should_receive(:puts).with(:large_bar)
			
			ro = RegularObject.new 
			o = BarNone.new
			ro.with o do
				
				@var = object_tester bar										# @var is set on o not ro
				
			end
			o.instance_variable_get(:@var).should == :large_bar
			
		end
	end
	
	describe "exiting abnormally" do
		it 'exits via error' do
			expect {
				with Object.new do
					raise ArgumentError, 'should be this error'
				end
			}.to raise_error(ArgumentError, 'should be this error')
			
			expect {
				class Unbelievers
					def erroneous obj
						raise RuntimeError, "#{obj}"
					end
					with Object.new do
						Unbelievers.new.erroneous 'lha is the name'
					end
				end
			}.to raise_error(RuntimeError, 'lha is the name')
			
		end
		
		it 'exits via throw' do
			
			$stdout.should_receive(:puts).with('If this is printed we have a problem').exactly(0).times
			
			catch(:signal) {
				with Object.new do
					throw :signal
				end
				puts 'If this is printed we have a problem'
			}
			
		end
		
		it 'also works this way' do
			
			expect {
				with Object.new do
					throw :signal
				end
			}.to throw_symbol(:signal)
			
		end
		
		it 'is porous to warnings' do
			
			with Object.new do
				warn 'test warning'  # it works (check standard output)
			end
			
		end
		
	end
	

	if RUBY_VERSION < '2.0.0'
	#####
	# #singleton_class
	describe "#singleton_class" do
		it 'returns the singleton_class of an object' do
			singleton = class SingletonProber; class << self; self; end; end
			SingletonProber.singleton_class.should == singleton
		end
		
		the 'singleton class has a reference to its root class' do
			SingletonProber.singleton_class.root().should == SingletonProber
		end
	end
	
	
	#####
	# #singleton_class?
	describe "#singleton_class?" do
		it 'should say when class is singleton_class' do
			singleton = class SingletonProber; class << self; self; end; end
			singleton.singleton_class?.should == true
		end
		
		it 'should say when class is not singleton_class' do
			SingletonProber.singleton_class?.should == false
		end
	end
	end
	
	#####
	# in?
	describe "#in?" do
		
		it 'tests membership' do
			a = [1,2,3]
			1.in?(a).should be
			
			b = (3..6)
			4.in?(b).should be
			
			require 'set'
			s = Set[4,6,8]
			6.in?(s).should be
			
		end
		
	end
	
	
	#####
	# to_filepath
	describe "#to_filepath" do
		
		it 'turns a namespace to a filepath' do
			module Foo
				module Bar
					class One
					end
				end
			end
			Foo::Bar::One.to_filepath.should == 'Foo/Bar/One'
		end
		
	end
	
	
	#####
	# Regular module syntax candifiers
	describe 'Module#const_values' do
		module ConstValuesTester
			A = 123
			B = 'abc'
			C = [A, B]
		end
		it 'returns an array of all the constant values' do
			ConstValuesTester.values.should be_instance_of(Array)
			ConstValuesTester.values.should == [123, 'abc', [123, 'abc']]
		end
	end


end #library spec
