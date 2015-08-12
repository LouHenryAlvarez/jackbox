# require "spec_helper"
# =begin rdoc
# 
# 	#####
# 	# eXtra Dude: Debugger Helper specification
# 
# 	Current Practice is:
# 		.
# 		.
# 		log or puts (some_variable)
# 		or
# 		open(some_file) do |file| ... or Logger.new()
# 			file.puts(some_variable) ... log.debug(some_variable)
# 		end
# 		... later in the program life, these statements must be commented out
# 
# 	We want a methodology to load some very basic debugging help over and beyond the trickery of puts statements 
# 	in current use or that somehow crystalizes those current practices and enhances them with some helpful 
# 	additions like loging program state info and line number.  We also want the ability to call on the debugger at any 
# 	point without much a-do, or to even automatically break into the debugger on Exception or other condition, and it has
# 	to be system independent, working with all versions of ruby.
# 
# =end
# 
# 	
# describe DX, :dx do
# 
# 	before do
# 		tmpdir = rfolder()
# 		FileUtils.mkpath tmpdir
# 		Dir.chdir tmpdir
# 	end
# 
# 	describe 'ability to break into debugger' do
# 		
# 		it 'has a method to break into debugger mode' do
# 			DX.should_receive :debug
# 			DX.debug
# 		end
# 		
# 		it 'can break into the debugger on exception' do
# 			DX.seize TypeError
# 			DX.should_receive :debug
# 			expect{String.new 3}.to raise_error
# 		end
# 		
# 	end
# 	
# 	
# 	# #####
# 	# # Enhanced Practice should be:
# 	#  
# 	# it should automatically knows where to output with only minor options
# 	# it should automatically output program state at point of call
# 	# it should not need removal in production adding to the program function
# 	describe 'enhancing current debugging practice' do
# 	
# 		describe 'automatically know where to output program state with only minor options' do
# 			
# 			let!(:program){
# 				open 'tester', 'w+' do |file|
# 					file.puts %{
# 	
# 						require 'jackbox'
# 						require 'jackbox/examples/dx'
# 						some_variable = 'crap'
# 						def program tester
# 							DX.log 'this is a test'
# 						end
# 						program 'play'
# 	
# 					}
# 				end
# 			}
# 			
# 			describe 'know where to ouput' do
# 	
# 				it 'outputs to file named after the program in $0' do
# 					File.should exist('tester')
# 					launch 'tester'
# 					File.should exist('tester.log')
# 					open 'tester.log', 'r' do |f|
# 						f.readlines.grep(/this is a test/).should_not be_empty
# 					end
# 				end
# 	
# 				it 'creates output file in the location of the user' do
# 					File.should exist('tester')
# 					FileUtils.mkpath 'folder'
# 					Dir.chdir 'folder'
# 					launch '../tester'
# 					File.should exist('tester.log')
# 					open 'tester.log', 'r' do |f|
# 						f.readlines.grep(/this is a test/).should_not be_empty
# 					end
# 				end
# 			
# 			end
# 	
# 			describe 'options' do
# 	
# 				it 'has an option to output to terminal standard out' do
# 					DX.logger :active
# 					$stdout.should_receive(:write).with(/This is a screen test/)
# 					DX.log false, 'This is a screen test'
# 				end
# 	
# 				it 'has an option to output to system logs' do
# 					DX.syslog 'a test message for syslog'
# 					sleep 0.2
# 					if !OS.windows?
# 							open "/var/log/system.log", 'r' do |file|
# 								file.readlines.to_a[-5, 5].grep(%r{a test message for syslog}).should_not be_empty
# 							end
# 					end
# 				end
# 				
# 			end
# 	
# 		end
# 	
# 		
# 		describe 'automatically output program state at point of call.  #log, #syslog, and #seize calls not only output 
# 		the given msg but also extra program information at the point of call.  If complete class DX injection is
# 		used then even more info is available. See below.' do
# 			
# 			
# 			let!(:program){
# 				open 'tester', 'w+' do |file|
# 					file.puts %{
# 	
# 						require 'jackbox'
# 						require 'jackbox/examples/dx'
# 						some_variable = 'crap'
# 						def program tester
# 							DX.log 'some programmer non-sense'
# 						end
# 						program 'play'
# 						
# 						DX.syslog 'a load of crap'
# 						
# 					}
# 				end
# 			}
# 	
# 			describe 'DX.log and DX.syslog calls' do
# 				
# 				the 'DX.log call' do
# 					File.should exist('tester')
# 					launch 'tester'
# 					File.should exist('tester.log')
# 					open 'tester.log', 'r' do |f|  # in this case rspec is in $0
# 						lines = f.readlines
# 						lines.grep(/programmer non-sense/).should_not be_empty  # programmer's message
# 						lines.grep(/tester:tester:\d+:in/).should_not be_empty  # program name and file/caller info is part of the log from above
# 					end					
# 				end
# 	
# 				the 'DX.syslog call' do
# 					File.should exist('tester')
# 					launch 'tester'
# 					File.should exist('tester.log')
# 					if !OS.windows?
# 						open "/var/log/system.log", 'r' do |f|
# 							lines = f.readlines
# 							lines[-5, 5].grep(%r{a load of crap}).should_not be_empty  # programmer's message
# 							lines[-5, 5].grep(/tester:tester:\d+:in/).should_not be_empty  # program name and file/caller info is part of the log from above
# 						end
# 					end
# 				end
# 				
# 			end
# 			
# 			
# 			describe 'DX.seize call: logging Exception information' do
# 					
# 				it 'allows system Exception info to be logged instead of stopping the program' do
# 					DX.logger :active
# 					DX.splatter :active
# 					DX.seize true, TypeError
# 					DX.should_receive :debug
# 					expect{String.new 3}.to raise_error
# 					sleep 0.2
# 					if !OS.windows?
# 						open('/var/log/system.log', 'r') do |file|  # named 'rspec.log' because rspec is $0
# 							lines = file.readlines[-10, 10]
# 							lines.grep(/TypeError/).should_not be_empty
# 							lines.grep(/rspec/).should_not be_empty
# 						end
# 					end
# 				end
# 				
# 			end
# 		end
# 		
# 		
# 		describe 'no need for removal of each and every individual call in production having an 
# 		option to "turn-off" all calls on a per module/injector basis' do
# 	
# 			the 'logger goes silent if collapse is called' do
# 				# call collapse on logger
# 				DX.logger :collapse
# 				DX.assert_loaded.should == nil
# 				DX.syslog('baa').should == nil
# 			end
# 					
# 			the 'debugger goes silent if collapse is called' do
# 				# collapse debugger
# 				DX.splatter :collapse
# 				DX.debug  # nothing happens even without expectacion
# 			end
# 		
# 		end
# 		
# 		describe 'rebuilding the modules' do
# 		
# 			this 'is logger rebuilding' do
# 				DX.logger :collapse
# 				DX.assert_loaded('something').should == nil
# 				DX.syslog('boo').should be_nil
# 				# ...
# 				DX.logger :rebuild
# 				DX.assert_loaded('something').should_not == nil
# 				$stdout.should_receive(:write).with(/The hot thing/)
# 				DX.syslog false, 'The hot thing'
# 				sleep 0.2
# 				if !OS.windows?
# 					open '/var/log/system.log', 'r' do |file|
# 						lines = file.readlines
# 						lines.grep(/The hot thing/).should_not be_empty
# 					end
# 				end
# 			end
# 		
# 			this 'example shows splatter rebuilding' do
# 				DX.splatter :collapse
# 				DX.debug.should be_nil
# 				# ...
# 				DX.splatter :rebuild
# 				DX.should_receive :debug
# 				DX.debug
# 				
# 				# DX.seize NameError
# 				# DX.should_receive :debug
# 				# expect{eval('while crap do end')}.to raise_error
# 			end
# 			
# 		end
# 	end
# 	
# 	
# 	describe 'the case with complete class DX module injection to automatically output 
# 	greater program state at point of call by creating a tracer.	However and can 
# 	slow down your times depending on context' do
# 	
# 		subject {
# 			
# 			# DX.splatter :rebuild
# 			# DX.logger :rebuild
# 			
# 			class Animal
# 				inject DX
# 				
# 				def initialize(var)
# 				  @var = var
# 				end
# 				def crawl arg1, *args
# 					val = arg1
# 					h = args
# 					something = 'nothing'
# 					syslog 'We are in a crawl'
# 					self
# 				end
# 				def annomaly
# 					debug
# 				end
# 				self
# 			end
# 				
# 		}
# 		
# 		it 'outputs caller info' do
# 			subject.new("snail").crawl("in dirt", "slowly")
# 			sleep 0.2
# 			if !OS.windows?
# 				open('/var/log/system.log', 'r') do |file|  # naned 'rspec.log' because rspec is $0
# 					lines = file.readlines[-10, 10]
# 					lines.grep(/We are in a crawl/).should_not be_empty
# 					lines.grep(/@var\W+snail/).should_not be_empty
# 					lines.grep(/arg1\W+in dirt/).should_not be_empty
# 					lines.grep(/args\W+slowly/).should_not be_empty
# 					lines.grep(/something\W+nothing/).should_not be_empty
# 				end
# 			end
# 		end
# 	
# 		the 'same goes from the #seize call' do
# 			class Animal
# 				inject DX
# 				
# 				def disease
# 					seize false, TypeError
# 					String.new 3
# 				end
# 			end
# 			dog = subject.new('dog')
# 			DX.should_receive :debug
# 			expect{dog.disease}.to raise_error
# 		end
# 		
# 		it 'is also possible to log from the seize call' do
# 			class Animal
# 				inject DX
# 				
# 				def secret
# 					seize true, ZeroDivisionError  # break false turns into a log entry
# 					var = 1/0
# 				end
# 			end
# 			emu = subject.new('emu')
# 			DX.should_receive :debug
# 			expect{emu.secret}.to raise_error
# 			sleep 0.2
# 			if !OS.windows?
# 				open('/var/log/system.log', 'r') do |file|  # naned 'rspec.log' because rspec is $0
# 					lines = file.readlines[-10, 10]
# 					lines.grep(/ZeroDivisionError/).should_not be_empty
# 					lines.grep(/rspec.+?dx_spec.rb/).should_not be_empty
# 				end
# 			end
# 		end
# 		
# 		it 'still allows program stops for debug' do
# 			weirdo = subject.new('cat-dog')
# 			weirdo.should_receive :debug
# 			weirdo.annomaly
# 		end
# 		
# 		# it 'is not posible to include DX at the top level' do
# 		# 	expect{Object.inject DX}.to raise_error
# 		# end
# 	
# 	end
# 	
# end
# 
