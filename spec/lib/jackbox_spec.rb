require 'spec_helper'
=begin rdoc
	jackbox_spec
	author: Lou Henry
	:nodoc:all:
=end


#####
# 
# We spec the jackbox library part of this gem
# 
describe Jackbox, 'jackbox library', :library do


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
					super() + 'decoration '
				end
			end
			One.new.foo.should match_regex(/decoration/)
		
		end
		
		it 'allows decorating the same method multiple times' do
			class T
				def bar
					'bar '
				end
			end
			class T
				decorate :bar do 		# <<--- SHOULD GET CLOBERED **** 
					super() + 'none '
				end
			end
			class T
				# debugger
				decorate :bar do
					super() + 'and then some'
				end
			end
			expect{T.new.bar.should == 'bar and then some'}.to_not raise_error 
		end			
		
		it 'is available at the object instance level during execution' do
			one = One.new
			one.decorate :foo do |arg|
				super() + arg
			end
			one.foo('after').should match_regex('foo decoration after')
		
		end
		
		it 'allows ruby_c objects and singleton classes to be decorated as well' do
			STDOUT.should_receive(:puts).with("Changing directory...")
			Dir.singleton_class.instance_eval do
				decorate :chdir do |*args|
					puts 'Changing directory...'
					super(*args)
				end
			end
			Dir.chdir('.').should == 0
			Dir.singleton_class.instance_eval { undecorate :chdir }
		end
		
		it 'raises an error when decorating singleton classes without returning them properly' do
			expect {
				class File
					class << self
						decorate :chown do |*args| end
					end
				end}.to raise_error
			expect {
				class File
					singleton_class.instance_eval do  # MUST USE :singleton_class 
						decorate :chown do |*args| end
					end
				end}.to_not raise_error		
		end
		
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
				# remove_method :bar
				undecorate :bar
			end
			F.new.bar.should == 'bar '		 
		end
		
		this 'un-decoration works on singleton_class also' do
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
		
		it 'does not work on undefined methods' do
			
			class SomeCrappyClass
			end
			
			expect {
			class SomeCrappyClass
				decorate :boo do
					:boo
				end
			end
			}.to raise_error
		end
		
		it 'also works like so' do
			
			STDOUT.should_receive(:puts).with(/is your object/)
			Object.decorate :inspect do
				puts super() + " is your object"
			end
			Object.new.inspect
			
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
		
		it 'can evaluate a long block for predicat' do

			$stdout.should_receive(:puts).with('perform a long evaluation for a predicate')
			expect {
				
				def tester
					lets {
						puts 'perform a long evaluation for a predicate'
					}.call if true
				end
				tester
				
			}.to_not raise_error
			
		end
		
		it 'should forbid the following' do
			# does not work at the instance level
			expect {
				instance_eval {
					lets(:foo){ 'foo bar'}
				}
			}.to raise_error(Jackbox::Error)
			
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
		
		it 'allows passing instance variables' do
			STDOUT.should_receive(:puts).with('in One#foo with arg tester')
			STDOUT.should_receive(:puts).with('in One#foo with arg mester')
			STDOUT.should_receive(:puts).with('in One#foo with arg in Two#faa with arg me')
			class One
				def foo(arg)
					'in One#foo with arg ' + arg
				end
			end
			class Two
				
				def faa arg='yuyu'
					'in Two#faa with arg ' + arg
				end

				def fii
					@tester = 'tester'
					@mester = 'mester'
				
					with One.new, @tester, @mester do  |*args|
						args.each { |e| puts foo e }
						puts foo faa 'me'
						# puts @var
					end
				end
				
			end
			Two.new.fii
		end
		
		it 'raises an error if not used properly' do
			expect{with Object.new}.to raise_error
		end
		
		it 'allows you to decorate an object multiple methods' do
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
	
	end
	
	describe 'object#with target' do
		class Target
			def bar
				:large_bar
			end
		end
		class RegularObject
			def object_tester arg
				puts arg or arg
			end
		end
		
		it 'allows access to the receiver and the object of with all at the same time' do
			$stdout.should_receive(:puts).with(:large_bar)
			ro = RegularObject.new 
			ro.with Target.new do
				object_tester bar
			end
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
					def fuckall obj
						raise RuntimeError, "#{obj}"
					end
					with Object.new do
						Unbelievers.new.fuckall 'lha is the name'
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
		
	end
	
end #library spec
