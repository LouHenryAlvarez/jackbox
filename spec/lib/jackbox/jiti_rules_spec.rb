require "spec_helper"

# RubyProf.start

describe 'jit inheriatnce with tagging' do

	before do
		
		# 
		# Trait
		# 
		trait :Functionality

		suppress_warnings do
			# 
			# Works like class inheritance
			# 
			Tag1 = Functionality do
				def m1
					1
				end

				def m2
					:m2
				end
			end

			Functionality do
				def other  												# No overrides No inheritance
					'other'													# -- same ancestors as before
				end 															# -- normal trait inheritance
			end

			# debugger
			Tag2 = Functionality do
				def m1														# The :m1 override invokes JIT inheritance
					super + 1												# -- Tag1 is added as ancestor
				end 															# -- allows the use of super

				def m3							
					'em3'
				end
			end

			# debugger
			Tag3 = 	Functionality() do
				def m1
					super * 2 											# second override to #m1 
				end                   						# -- Tag2 added as ancestor
				def m3
					super * 2												# first override to #m3
				end 								
			end

			A = Class.new
			B = Class.new
			C = Class.new
			D = Class.new

		end
	end

	after do

		suppress_warnings do

			A = nil
			B = nil
			C = nil
			D = nil
			
			Tag1 = nil
			Tag2 = nil
			Tag3 = nil
			Tag4 = nil
			Tag5 = nil
			Tag6 = nil

		end

		Functionality(:implode)

	end

	it 'keeps the main trait in sync with the last tag' do

		o = Object.new.extend Tag3
		p = Object.new.extend Functionality()

		# test it

		o.m1.should == 4
		p.m1.should == 4

	end

	it 'works under object extension' do

		o = Object.new.extend Tag3
		o.m1.should == 4

	end

	it 'also works under class inclusion' do

		#
		# Under Inclusion
		# 
		class A
			inject Tag2
		end
		a = A.new

		# JIT inherited
		a.m1.should == 2
		a.m3.should == 'em3'

		# Version inherited
		a.m2.should == :m2
		a.other.should == 'other'

		Functionality().tags.should == [Tag1, Tag2, Tag3]

	end

	it 'goes on down the levels' do

		#
		# Different client/Diferent Tag
		# 
		class B
			inject Tag3 
		end
		b = B.new

		# JIT inherited
		b.m1.should == 4					
		b.m3.should == 'em3em3'

		# regular inheritance
		b.m2.should == :m2
		b.other.should == 'other'

		Functionality().tags.should == [Tag1, Tag2, Tag3]

	end

	it 'still holds on to earlier tag definitions' do

		class A
			inject Tag2
		end
		class B
			inject Tag3 
		end
		# 
		# Test previous Tags are unaffected !!
		# 
		A.new.m1.should == 2							# includes Tag2
		A.new.m2.should == :m2
		A.new.m3.should == 'em3'

		B.new.m1.should == 4							# includes Tag3
		B.new.m2.should == :m2
		B.new.m3.should == 'em3em3'

		#
		# other clients
		#
		class C
			inject Tag2
		end
		c = C.new

		c.m1.should == 2
		c.m2.should == :m2
		c.m3.should == 'em3'

	end

	it 'keeps the VMC in proper working order' do

		class A
			inject Tag2
		end
		class B
			inject Tag3 
		end
		#
		# VMC (Virtual Method Cache) method
		#
		Functionality() do
			def m4							
				:m4
			end
		end

		class C
			inject Tag2
		end
		c = C.new

		# jit inherited
		c.m1.should == 2
		c.m3.should == 'em3'

		# version inherited
		c.m2.should == :m2
		c.other.should == 'other'

		c.m4.should == :m4		# vmc method

		# other clients of the VMC
		A.new.m4.should == :m4
		B.new.m4.should == :m4

	end

	it 'allows rebasing individual methods' do 

		suppress_warnings do
			# 
			# Another prolongation: back to basics
			# 
			Tag4 = Functionality() do
				def m1														# another override but no call to #super
					:m1															# -- just simple override
				end 															# -- could be tagged if needed
			end
		end

		# test it

		o = Object.new.extend( Tag4 )

		# new version of #m1 !!
		o.m1.should == :m1									

		# JIT inherited
		o.m3.should == 'em3em3'							# old jiti version of m3

		# Version inherited
		o.m2.should == :m2									# old version of m2
		o.other.should == 'other'

		# Total Tags

		Functionality().tags.should == [Tag1, Tag2, Tag3, Tag4]

	end

	it "allows further ancestor injection" do

		module Mod1
			def m4
				:m4
			end
		end

		suppress_warnings do
			Tag4 = Functionality(Mod1) do

				include Mod1											# alternatively

				def m1
					super * 2
				end
				def m3
					:m3															# m3 is rebased
				end
				
			end
		end
		
		# test it 

		# jit inherited
		Object.new.extend(Tag4).m1.should == 8 # from Tag3
                         
		# version inherited  
		Object.new.extend(Tag4).m2.should == :m2 # from Tag1
                         
		# rebased            
		Object.new.extend(Tag4).m3.should == :m3 # from Tag5
                         
		# ancestor injection 
		Object.new.extend(Tag4).m4.should == :m4 # from Mod1

	end

	it "also allows on the fly overrides" do

		#
		# On the fly overrides
		# 
		obj = Object.new.extend(
			Functionality {
				def m1
					super + 3											# on top of Tag1, Tag2, Tag3
				end
				def m4
					:m4
				end
			})

		# new jiti override
		obj.m1.should == 7

		# version inherited
		obj.m2.should == :m2
		obj.m3.should == 'em3em3'
		obj.m4.should == :m4

		# other prolongation

		Object.new.extend(Functionality(){
			def m3
				super * 2
			end
		}).m3.should == 'em3em3em3em3'

	end

	it "blocks external ancestor intrusion enforcing internal trait consistency" do

		#########################################
		# Masks Ancestor intrussion
		# 

		suppress_warnings do
			Tag4 = Functionality do
				def m1														# Injector has internal base method
					1
				end
			end

			module Mod1
				def m1
					'one'
				end
			end

			Tag5 = Functionality(Mod1) do 						# Mod1 attempts to intrude on base

				include Mod1

				def m1
					super * 2
				end
			end
		end
		
		# test it

		o = Object.new.extend(Tag5)			
		# jit inherited
		o.m1.should == 2										# no such luck!!

		p = Object.new.extend(Functionality(Mod1))
		# jit inherited
		p.m1.should == 2										# no such luck!!

		# version inherited
		o.m2.should == :m2 # from Tag1
		p.m2.should == :m2

	end

	it 'allows overriding methods further down the tree' do

		suppress_warnings do
			Tag4 = Functionality do
			  def m1
			    1
			  end
			  def m2 							# original definition
			    2
			  end
			end
			Tag5 = Functionality do
			  def m1
			    'm1'
			  end 								# skipped #m2
			end
			Tag6 = Functionality do
			  def m1
			    super * 2
			  end
			  def m2
			    super * 2					# override # m2 two levels down
			  end
			end
		end
		
		class A
		  inject Tag6
		end

		# test it

		A.new.m1.should == 'm1m1'
		A.new.m2 == 4

	end

	it 'allows rebasing (start fresh) methods at any level' do

		suppress_warnings do
			Tag4 = Functionality do
				def m1
					1																# rebase Tag3
				end
			end

			class A
				inject Functionality() do
					def m1
						super + 1											# override
					end
				end
			end

			# test it

			A.new.m1.should == 2


			Tag5 = Functionality do
				def m1
					5																# rebase m1 again
				end
			end

			class B
				inject Functionality() do
					def m1
						super * 2											# new override
					end
				end
			end
		end
		
		# test it

		B.new.m1.should == 10


	end

	it 'works with Trait Directives' do

		suppress_warnings do
			Tag4 = Functionality do
				def m1
					1
				end
			end

			class A
				inject Functionality() do
					def m1
						super + 1
					end
				end
			end

			A.new.m1.should == 2


			Tag5 = Functionality do
				def m1
					5									# rebase m1
				end
			end

			class B
				inject Functionality() do
					def m1
						super * 2				# new override
					end
				end
			end
		end
		
		B.new.m1.should == 10

		# test directives

		Functionality(:silence)

		A.new.m1.should == nil										# both bases affected
		B.new.m1.should == nil

		Functionality(:active)

		A.new.m1.should == 2											# both bases restored
		B.new.m1.should == 10

	end

end

describe 'jiti soft external basing' do

	####################################################################
	# Soft external basing should be the preferred way of doing things #
	# . The alternative hard internal basins (see below) is not as     #
	# flexible and inrtoduces fixed ancestor ordering --once the       #
	# the ancestors are layout the keep their precedence unlsess you   #
	# stick only to injectors.																				 #
	# . Soft ancestors don't suffer from this like: 									 #
	# 																																 #
	# 	trait :a, :b, :c 																							 #
	# 																																 #
	# 	x = a b c																											 #
	# 	y = a c b																											 #
	# 																																 @
	# For more on this see the compostion spec												 #
	# ##################################################################
	
	before do
		
		#
		# Injector
		# 
		trait :Functionality


		module Base1												# EXTERNAL BASEs!!
			def m1
				2
			end
		end

		module Base2
			def m1
				3
			end
		end

		suppress_warnings do
			# 
			# Similar to Above
			# 
			Tag1 = Functionality(Base1) do

				# include Base1										# NO INTERNAL BASE!! for #m1

				def m2
					:m2
				end
			end

			# debugger
			Tag2 = Functionality(Base2) do
				def m1														# The :m1 override invokes JIT inheritance
					super + 1												# -- Tag1 is added as ancestor
				end 															# -- allows the use of super

				def m3							
					'em3'
				end
			end

			# debugger
			Tag3 = 	Functionality(Base1) do
				def m1
					super * 2 											# second override to #m1 
				end                   						# -- Tag2 added as ancestor
				def m3
					super * 2												# first override to #m3
				end 								
			end

		end
	end

	after do

		suppress_warnings do

			Tag1 = nil
			Tag2 = nil
			Tag3 = nil
			Tag4 = nil
			Tag5 = nil
			Tag6 = nil

		end

		Functionality(:implode)

	end
	
	it 'works for Tag1' do

		o = Object.new.extend(Tag1)
		o.m1.should == 2
		
	end
	
	it 'works for Tag2' do
		
		o = Object.new.extend(Tag2)
		o.m1.should == 4
		
	end

	it 'works with initial external basing' do

		o = Object.new.extend(Tag3)
		# debugger
		o.m1.should == 6										# from Base1 thru Tag3

	end

	it 'also keeps the main trait in sync with the last tag' do

		p = Object.new.extend(Functionality(Base1))
		p.m1.should == 6

	end

	it 'allows external base substitution --keeps the Trait Injector shell/jacket' do

		q = Object.new.extend(Functionality(Base2))	# on top or Tag3 thru Tag2....
		q.m1.should == 8

	end

	it 'follows the other normal rules' do

		suppress_warnings do
			Tag4 = Functionality(Base1) do
				def m1
					super() * 2											# on top of Tag3
				end
				def m2
					:m2
				end
			end
		end
		p = Object.new.extend(Tag4)
		p.m1.should == 12

	end

	it 'also allows other external base function' do

		module Base2
			def m4
				'new'
			end
		end

		suppress_warnings do
			Tag4 = Functionality(Base2) do
				
				# inject Base2
				def m1
					super / 2
				end
				def m2
					super
				end
			end
		end
		# p = Object.new.extend(Tag4, Base2)
		p = Object.new.extend(Tag4)

		p.m1.should == 4										# external rebase and thru Tag16, Tag3 and Tag2
		p.m2.should == :m2
		p.m4.should == 'new'								# new function
		
		module Base3
			def m1
				5
			end
		end
		
		suppress_warnings do
			Tag5 = Functionality(Base3) do
				
				# inject Base3
				def m1
					super + 1
				end
			end
		end
		# q = Object.new.extend(Tag5, Base3)
		q = Object.new.extend(Tag5)
		
		# debugger
		q.m1.should == 7

	end

	it 'enforces internal basing once applied --blocks further external intrusion (like above)' do

		suppress_warnings do
			Tag4 = Functionality() do
				# ...															# on top of Tag3
				def m2 
					6																# rebase #m2
				end
			end
			o = Object.new.extend(Functionality(Base2))
			
			o.m1.should == 8										
			o.m2.should == 6										

			Functionality() do
				def m1
					super + 1												# thru Tag4 on top of Tag3
				end
			end
			p = Object.new.extend Functionality(Base2)

			p.m1.should == 9
			p.m2.should == 6


			module Base3 												# EXTERNAL NEW BASE!!
				def m1
					0																# rebase #m1
				end
				def m3														
					:m3															# muted by internal basing
				end
			end
			p = Object.new.extend(Functionality(Base3))

			p.m1.should == 3
			p.m2.should == 6
			p.m3.should == 'em3em3'


			q = Object.new.extend(							# INTERNAL NEW BASE!!
				Functionality() do
					def m1
						2															# internal rebase blocks outside one
					end
				end)
				
			q.m1.should == 2
			q.m2.should == 6

			module Base4												# EXTERNAL NEW BASE 
				def m1
					'em1'														# muted by internal rebasing
				end
			end
			r = Object.new.extend(Functionality(Base4))

			r.m1.should == 2
			r.m2.should == 6
		end
		
	end
	
end

describe 'jiti hard external basing' do

	####################################################################
	# Soft external basing should be the preferred way of doing things #
	# . The alternative hard internal basing (see below) is not as     #
	# flexible and inrtoduces fixed ancestor ordering --once the       #
	# the ancestors are layout the keep their precedence unlsess you   #
	# stick only to injectors.																				 #
	# . Soft ancestors don't suffer from this like: 									 #
	# 																																 #
	# 	trait :a, :b, :c 																							 #
	# 																																 #
	# 	x = a b c																											 #
	# 	y = a c b																											 #
	# 																																 @
	# For more on this see the compostion spec												 #
	# ##################################################################
	
	before do
		
		#
		# Injector
		# 
		trait :Functionality


		module Base1												# EXTERNAL BASEs!!
			def m1
				2
			end
		end

		module Base2
			def m1
				3
			end
		end

		suppress_warnings do
			# 
			# Similar to Above
			# 
			Tag1 = Functionality() do

				include Base1										# SAME AS AN INTERNAL BASE PRACTICALLY!!

				def m2
					:m2
				end
			end

			Tag2 = Functionality() do
				
				include Base2
				
				def m1														# The :m1 override invokes JIT inheritance
					super + 1												# -- Tag1 is added as ancestor
				end 															# -- allows the use of super

				def m3							
					'em3'
				end
			end

			Tag3 = 	Functionality() do
				
				include Base1											# THIS DOESN'T WORK!!!
																					# Base1 was already an ancestor before Base2
				def m1
					super * 2 											# second override to #m1 
				end                   						# -- Tag2 added as ancestor
				def m3
					super * 2												# first override to #m3
				end 								
			end

		end
	end

	after do

		suppress_warnings do

			Tag1 = nil
			Tag2 = nil
			Tag3 = nil
			Tag4 = nil
			Tag5 = nil
			Tag6 = nil

		end

		Functionality(:implode)

	end
	
	it 'works for Tag1' do
		
		# SAME AS ABOVE
		
		o = Object.new.extend(Tag1)
		o.m1.should == 2
		
	end
	
	it 'works for Tag2' do
		
		# SAME AS ABOVE
		
		o = Object.new.extend(Tag2)
		o.m1.should == 4
		
	end

	it 'works with initial external basing' do
		
		# DIFFERENT THAN ABOVE
		
		o = Object.new.extend(Tag3)
		o.m1.should == 8              

	end

	it 'also keeps the main trait in sync with the last tag' do

		# SAME AS ABOVE
		
		p = Object.new.extend(Functionality(Base1))	# THIS DOESN'T WORK EITHER!!!
		p.m1.should == 8

	end

	it 'allows external base substitution --keeps the Trait Injector shell/jacket' do

		# SAME AS ABOVE
		
		q = Object.new.extend(Functionality())	# Base2 comming from internal spec!!!!
		q.m1.should == 8

	end

	it 'follows the other normal rules' do

		# DIFFERENT THAN ABOVE
		
		suppress_warnings do
			Tag4 = Functionality(Base1) do 				# THIS DOESN'T WORK EITHER!!!
				def m1
					super() * 2											
				end
				def m2
					:m2
				end
			end
		end
		p = Object.new.extend(Tag4)
		p.m1.should == 16

	end
	
end
# profile = RubyProf.stop
# RubyProf::FlatPrinter.new(profile).print(STDOUT)
# RubyProf::GraphHtmlPrinter.new(profile).print(open('profile.html', 'w+'))
# RubyProf::CallStackPrinter.new(profile).print(open('profile.html', 'w+'))
