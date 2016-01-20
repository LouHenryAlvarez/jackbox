require "spec_helper"

describe 'jit inheriatnce' do

	before do
		
		# 
		# Injector
		# 
		trait :Tagger

		suppress_warnings do

			Tag1 = Tagger do
				def m1
					1
				end

				def m2
					:m2
				end
			end

			Tagger do
				def other  					# No overrides No inheritance
					'other'						# -- same ancestors as before
				end 								# -- normal trait inheritance
			end

			Tag2 = Tagger do
				def m1														# The :m1 override invokes JIT inheritance
					super + 1												# -- Tag1 is added as ancestor
				end 															# -- allows the use of super

				def m3							
					'em3'
				end
			end

			class AA6
				inject Tag2
			end

			Tag3 = 	Tagger() do
				def m1
					super * 2 											# second override to #m1 
				end                   						# -- Tag2 added as ancestor
				def m3
					super * 2												# first override to #m3
				end 								
			end

			class AA7
				inject Tag3 
			end

		end
	end

	after do

		suppress_warnings do

			Tag1 = nil
			Tag2 = nil
			Tag3 = nil

		end

		Tagger(:implode)

	end

	it 'works like class inheritance' do

		o = Object.new.extend Tag3
		o.m1.should == 4

	end

	it 'keeps the main trait in sync with the last tag' do

		o = Object.new.extend Tag3
		p = Object.new.extend Tagger()

		# test it

		o.m1.should == 4
		p.m1.should == 4

	end

	it 'also works under inclusion' do

		#
		# Under Inclusion
		# 
		class AA6
			inject Tag2
		end
		aa6 = AA6.new

		# JIT inherited
		aa6.m1.should == 2
		aa6.m3.should == 'em3'

		# Version inherited
		aa6.m2.should == :m2
		aa6.other.should == 'other'

		Tagger().tags.should == [Tag1, Tag2, Tag3]

	end

	it 'goes on down the levels' do

		#
		# Different client/Diferent Tag
		# 
		class AA7
			inject Tag3 
		end
		aa7 = AA7.new

		# JIT inherited
		aa7.m1.should == 4					
		aa7.m3.should == 'em3em3'

		# regular inheritance
		aa7.m2.should == :m2
		aa7.other.should == 'other'

		Tagger().tags.should == [Tag1, Tag2, Tag3]

	end

	it 'allows rebasing methods cancelling that method genetics but keeping the rest' do 

		# 
		# Another prolongation: back to basics
		# 
		Tag4 = Tagger() do
			def m1														# another override but no call to #super
				:m1															# -- just simple override
			end 															# -- could be tagged if needed
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

		Tagger().tags.should == [Tag1, Tag2, Tag3, Tag4]

	end

	it 'still holds on to earlier Tag definitions' do

		# 
		# Test previous Tags are unaffected !!
		# 
		AA6.new.m1.should == 2							# includes Tag2
		AA6.new.m2.should == :m2
		AA6.new.m3.should == 'em3'

		AA7.new.m1.should == 4							# includes Tag3
		AA7.new.m2.should == :m2
		AA7.new.m3.should == 'em3em3'

		#
		# other clients
		#
		class AA6B
			inject Tag2
		end
		aa6b = AA6B.new

		aa6b.m1.should == 2
		aa6b.m2.should == :m2
		aa6b.m3.should == 'em3'

	end

	it 'keeps the VMC in proper working order' do

		#
		# VMC (Virtual Method Cache) method
		#
		Tagger() do
			def m4							
				:m4
			end
		end

		class AA6B
			inject Tag2
		end
		aa6b = AA6B.new

		# jit inherited
		aa6b.m1.should == 2
		aa6b.m3.should == 'em3'

		# version inherited
		aa6b.m2.should == :m2
		aa6b.other.should == 'other'

		aa6b.m4.should == :m4		# vmc method

		# other clients of the VMC
		AA6.new.m4.should == :m4
		AA7.new.m4.should == :m4

	end

	it "allows further ancestor injection" do

		module Mod1
			def m4
				:m4
			end
		end

		Tag5 = Tagger(Mod1) do

			include Mod1											# alternatively

			def m1
				super * 2
			end
			def m3
				:m3															# m3 is rebased
			end
		end

		# test it 

		# jit inherited
		Object.new.extend(Tag5).m1.should == 8 # from Tag3

		# version inherited
		Object.new.extend(Tag5).m2.should == :m2 # from Tag1

		# rebased
		Object.new.extend(Tag5).m3.should == :m3 # from Tag5

		# ancestor injection
		Object.new.extend(Tag5).m4.should == :m4 # from Mod1

	end

	it "also allows on the fly overrides" do

		#
		# On the fly overrides
		# 
		obj = Object.new.extend(
			Tagger {
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

		Object.new.extend(Tagger(){
			def m3
				super * 2
			end
		}).m3.should == 'em3em3em3em3'

	end

	it "does not allow ancestor intrussion" do

		#########################################
		# Masks Ancestor intrussion
		# 

		Tag6 = Tagger do
			def m1														# Injector has internal base
				1
			end
		end

		module Mod1
			def m1
				'one'
			end
		end

		Tag7 = Tagger(Mod1) do 						# Mod1 attempts to intrude on base

			include Mod1

			def m1
				super * 2
			end
		end

		# test it

		o = Object.new.extend(Tag7)			
		# jit inherited
		o.m1.should == 2										# no such luck!!

		p = Object.new.extend(Tagger())
		# jit inherited
		p.m1.should == 2										# no such luck!!

		# version inherited
		o.m2.should == :m2 # from Tag1
		p.m2.should == :m2

	end

	it 'allow overriding methods further down the tree' do

		Tag8 = Tagger do
		  def m1
		    1
		  end
		  def m2 							# original definition
		    2
		  end
		end
		Tag9 = Tagger do
		  def m1
		    'm1'
		  end 								# skipped #m2
		end
		Tag10 = Tagger do
		  def m1
		    super * 2
		  end
		  def m2
		    super * 2					# override # m2 two levels down
		  end
		end
		class AA10
		  inject Tag10
		end

		# test it

		AA10.new.m1.should == 'm1m1'
		AA10.new.m2 == 4

	end

	it 'allows rebasing methods at any level' do

		Tag11 = Tagger do
			def m1
				1																# rebase Tag3
			end
		end

		class AA11
			inject Tagger() do
				def m1
					super + 1											# override
				end
			end
		end

		# test it

		AA11.new.m1.should == 2


		Tag12 = Tagger do
			def m1
				5																# rebase m1 again
			end
		end

		class BB11
			inject Tagger() do
				def m1
					super * 2											# new override
				end
			end
		end

		# test it

		BB11.new.m1.should == 10


	end

	it 'takes Injector Directives' do

		Tag13 = Tagger do
			def m1
				1
			end
		end

		class AA12
			inject Tagger() do
				def m1
					super + 1
				end
			end
		end

		AA12.new.m1.should == 2


		Tag14 = Tagger do
			def m1
				5									# rebase m1
			end
		end

		class BB12
			inject Tagger() do
				def m1
					super * 2				# new override
				end
			end
		end

		BB12.new.m1.should == 10

		# test directives

		Tagger(:silence)

		AA12.new.m1.should == nil										# both bases affected
		BB12.new.m1.should == nil

		Tagger(:active)

		AA12.new.m1.should == 2											# both bases restored
		BB12.new.m1.should == 10

	end

end

describe 'jiti external basing' do

	before do
		
		#
		# Injector
		# 
		trait :Tagger

		suppress_warnings do

			module Base1												# EXTERNAL BASE!!
				def m1
					2
				end
			end

			# 
			# Similar to Above
			# 
			Tag1 = Tagger(Base1) do

				# include Base1										# alternatively

				def m2
					:m2
				end
			end

			Tag2 = Tagger do
				def m1														# The :m1 override invokes JIT inheritance
					super + 1												# -- Tag1 is added as ancestor
				end 															# -- allows the use of super

				def m3							
					'em3'
				end
			end

			Tag3 = 	Tagger() do
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

		end

		Tagger(:implode)

	end

	it 'allows initial external basing' do

		o = Object.new.extend(Tag3)
		o.m1.should == 6										# from Base1 thru Tag3

	end

	it 'also keeps the main trait in sync with the last tag' do

		o = Object.new.extend(Tag3)
		o.m1.should == 6

		p = Object.new.extend(Tagger())
		p.m1.should == 6

	end

	it 'carries on as usual' do

		Tag15 = Tagger do
			def m1
				super() * 2											# on top of Tag3
			end
			def m2
				:m2
			end
		end

		p = Object.new.extend(Tag15)
		p.m1.should == 12

	end

	it 'allows base substitution but keeps the Injector inheritance casing' do

		module Base2
			def m1
				3
			end
		end

		q = Object.new.extend(Tagger(Base2))	# on top or Tag3 thru Tag2....
		q.m1.should == 8

	end

	it 'also injects other ancestor function but keeps inheritance casing' do

		module Base2
			def m1
				4
			end
			def m4
				'new'
			end
		end

		Tag16 = Tagger(Base2) do
			def m1
				super / 2
			end
			def m2
				super
			end
		end

		p = Object.new.extend(Tag16)

		p.m1.should == 5										# external rebase and thru Tag16, Tag3 and Tag2
		p.m2.should == :m2
		p.m4.should == 'new'								# new function

	end

	it 'can mixes in both strategies' do

		Tag17 = Tagger(Base2) do
			def m2 
				6																# rebase #m2
			end
		end

		o = Object.new.extend(Tagger())
		o.m1.should == 10										# Base2 thru Tag3 casing
		o.m2.should == 6										# new #m2

		Tagger() do
			def m1
				super + 1												# on top of Tag17
			end
		end
		
		p = Object.new.extend Tagger()
		p.m1.should == 11

		module Base3
			def m1
				0																# new base
			end
			def m3														
				:m3															# mutee by internal basing
			end
		end

		p = Object.new.extend(Tagger(Base3))
		p.m1.should == 3
		p.m2.should == 6
		p.m3.should == 'em3em3'

		q = Object.new.extend(
			Tagger() do
				def m1
					2															# internal rebse
				end
			end)
		q.m1.should == 2
		q.m2.should == 6
		
		Tag18 = Tagger()
		
		module Base4
			def m1
				'em1'														# muted by internal rebasing
			end
		end
		
		r = Object.new.extend(Tagger(Base4))
		r.m1.should == 2
		r.m2.should == 6

	end
	
end
