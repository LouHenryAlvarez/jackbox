require "spec_helper"
=begin rdoc
	abstract_spec
	author: Lou Henry
	:nodoc:all
=end


class Object
	include Meta
end

describe Abstract do
	it 'introduces module Abtract' do
		Abstract.should be
	end
	# using public include now
	describe Abstract, 'abstract class quality' do
		a 'use case scenario' do
			class Vector
				extend Abstract
				def speed
					0
				end
				def direction
				end
			end
			expect{Vector.new}.to raise_error(NoMethodError)
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
		
		end #describe Abstract
		it 'should not afect later descendants' do
			class Top
				extend Abstract
			end
			expect{Top.new}.to raise_error(NoMethodError)
			class Middle < Top
			end
			expect{Middle.new}.to_not raise_error
			class Bottom < Middle
			end
			expect{Bottom.new}.to_not raise_error
		end
	
	end
end

