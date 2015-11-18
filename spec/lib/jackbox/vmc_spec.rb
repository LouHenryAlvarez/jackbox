require "spec_helper"
=begin rdoc
	
	VIRTUAL METHOD CACHE
	
	Virtual methods are methods that have not beeen applied as part of any injection as of yet.  They are not part of a version, execpt for the current one.
	In as such, they are common to all injectors, and can service any of them.  They stop being virtual when they become part of an injector application.
=end
include Injectors



# RubyProf.start
describe "VMC (Virtual Method Cache)" do
	
	before do
		jack :J1
		jack :K1
		jack :L1
		jack :M1
		jack :N1
	end
	
	after do
		J1(:implode)
		K1(:implode)
		L1(:implode)
		M1(:implode)
		N1(:implode)
	end
	
	it 'goes 3 deep' do
		
		class AA4
		  inject J1()
		end
		J1 do
			def n1m1
			end
		  inject K1()
		end
		K1 do
			def n2m1
			end
		  inject L1()
		end
		L1 do
		  def n3m1
		  end
		end
		# debugger
		AA4.new.n1m1
		AA4.new.n2m1
		AA4.new.n3m1
		
	end
	
	it 'goes even deeper' do
		
		class AA5
		  inject J1()
		end
		J1 do
		  inject K1()
		end
		K1 do
		  inject L1()
		end
		L1 do
		  inject M1()
		end
		M1 do
			def daa
			end
		end
		AA5.new.daa
		
	end

	it "does full coverage" do
		
		Object.inject J1()  												# pretty low-level injection!!  usually going to be higher than Object!!

		o = Object.new

		J1 do
		  def j1																			# Virtual Method: not actually    /\
			:j1                                         # part of any injection yet!      |                         
		  end                                         # The injection happened before --  
		end 																					# 1st level
		o.j1.should == :j1


		J1 do
		  inject K1()
		end
		K1 do
		  def k1																			# Virtual Method!!
				:k1																				# 2nd level
		  end
		end
		o.k1.should == :k1


		K1 do
			inject L1()
		end
		L1 do
			def l1																			# Virtual Method!!
				:l1																				# 3rd level
			end
		end
		o.l1.should == :l1


		L1 do
			inject M1()
		end
		M1() do
			def m1																			# Virtual Methods!!
				:m1																				# 4th level
			end
			def meth
				:meth
			end
		end
		o.m1.should == :m1


		L1 do
			inject N1()
		end
		N1 do
			def n1																			# Virtual Method!!
				:n1																				# 4th level also: same container
			end
		end
		o.n1.should == :n1

																									# ...
																									
		expect{
			o.j2
		}.to raise_error(NoMethodError)
			
		expect{
			o.n2
		}.to raise_error(NoMethodError)
			
	end

	the "converse example" do
		
		J1 do 																			# actual version methods
		  def j1																			# they becomen part of the
				:j1
		  end 																				# following application of 
		end 																					# this injector
		
		K1 do
		  def k1
				:k1
		  end
		end
		J1 do
		  inject K1()															# injector application!
		end
		
		L1 do
			def l1																			# actual version methods
				:l1
			end
		end
		K1 do
			inject L1()															# injector application
		end
		
		M1() do
			def m1
				:m1
			end
		end
		L1 do
			inject M1()
		end
		
		Object.inject J1()
		o = Object.new

		expect {
			o.j1.should == :j1
			o.k1.should == :k1
			o.l1.should == :l1
			o.m1.should == :m1
		}.not_to raise_error
		
		expect{
			o.j2
		}.to raise_error(NoMethodError)
			
	end

	it 'allows the use of super' do
		
		Object.inject J1()
		
		J1 do
			def j1																			# virtual methods
				:j1
			end
			def meth
				super + "#{j1}"
			end
		end

		J1().inject K1()
		
		K1 do
			def k1																			# virtual methods
				:k1
			end
			def meth
				super + "#{k1}"
			end
		end
		
		K1().inject L1() 
		
		L1 do
			def meth																		# virtual methods
				"#{:l1}"
			end
		end
		
		o = Object.new
		o.meth.should == 'l1k1j1'											# this call is on the VMC!!!
		
	end


end

# profile = RubyProf.stop
# RubyProf::FlatPrinter.new(profile).print(STDOUT)
# RubyProf::GraphHtmlPrinter.new(profile).print(open('profile.html', 'w+'))
# RubyProf::CallStackPrinter.new(profile).print(open('profile.html', 'w+'))
