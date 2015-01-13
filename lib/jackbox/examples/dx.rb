require 'fiber' 
require 'shellwords'
=begin rdoc

		Copyright © 2014 LHA. All rights reserved.

		Debugger Extras: 

		We want a methodology to load some very basic debugging help over and beyond the trickery of print and puts statements 
		under current normal use or that somehow crystalizes those current practices and enhances them with some helpful 
		additions like printing program state info and line number.  We also want the ability to call on the debugger at any 
		point without much a-do, or to even automatically break into the debugger on Exception or other condition, and it has
		to be system independent, working with all versions of ruby.

=end
require "jackbox/injectors"


include Injectors


require 'logger'
if RUBY_VERSION < '2.0.0'
	DEBUGGER = 'debugger'
else
	DEBUGGER = 'byebug'
end
require DEBUGGER

module Jackbox
	module Examples
		#
		# Debugging Extras
		#
		module DX
			#
			# Methods to log program or system level information
			# 
			injector :logger do

			  # open a logger
			  def log= log
					@xd_log = log or raise Exception
			  end
			  # set the logger level
			  def level= level
					@so_log.level = level rescue @xd_log.level = level
			  end 
			  # print to logger with DEBUG level
			  def log file=true, frame=0, msg
					with "#{msg}\n \@\[#{$0}\:#{caller[frame]}\]\n#{@_trace}" do
				 		xd_out(file).debug(self)
					end
			  end
			  # logs to the system log
				case
				when OS.windows?
				  def syslog file=false, frame=1, msg
				 		raise ArgumentError unless system(
						"eventcreate /T ERROR /ID #{rand(1000)} /L APPLICATION /SO #{File.basename $0} /D \"#{self.log(file, frame, msg)}\"")
				  end
				else
				  def syslog file=false, frame=1, msg
				 		raise ArgumentError unless system("logger -i #{self.log(file, frame, msg).shellescape}")
				  end
				end
			  # asserts a file was loaded
			  def assert_loaded file=__FILE__
					self.log file + ' was loaded!!'
			  end

			  private
			  def xd_out file
				  unless $DEBUG == true or file == false
						@xd_log ||= Logger.new("#{File.basename($0)}.log")
				  else
						@so_log ||= Logger.new($stdout)
				  end 
			  end
		
			end
			enrich logger

			#
			# Methods to stop normal execution and enter the debugger
			# 
			injector :splatter do
		
				extend DX.logger
				# break to debugger on Excetion type
				def seize log=false, type
					type.decorate :initialize do |*args|
						step_up = 1
						step_up = 3 unless caller.grep(/injectors.rb.+?method_missing/).empty?
						if log
							DX.syslog( false, step_up + 1, type )
						end
						DX.debug(step_up)
					end
				end

				#call the debugger
				if RUBY_VERSION < '2.0.0'
					alias _debug debugger
				else
					alias _debug byebug 
				end
				private :_debug
				def debug *args
					puts "\n\n", @_trace
					_debug(2 + args.first) rescue _debug(2)
				end
				alias splat debug

		
			end
			enrich splatter

			#
			# singleton methods
			# 
			class << self
		
				attr_accessor :tracer
		
				def included(klass)
					# raise TypeError, 'DX not allowed in: Object'  if klass == Object
				  set_trace_func proc { |event, file, line, id, binding, classname|
						DX.tracer.resume(binding) if event == 'call' and id.in?(klass.instance_methods) rescue nil
				  }
		
					klass.instance_methods(false).each do |existing_method| 
						wrap(klass, existing_method)
					end
			
					def klass.method_added(method) # note: nested definition
						unless @trace_calls_internal 
							@trace_calls_internal = true 
							DX.wrap(self, method) 
							@trace_calls_internal = false
						end 
					end
				end
	
				def wrap(klass, method)
					klass.instance_eval do
						method_object = instance_method(method) 

						define_method(method) do |*args, &block|
							DX.tracer = Fiber.new do |binding|
								Fiber.yield
								lnames, inames = binding.eval("local_variables"), binding.eval("instance_variables")
								lvars, ivars = [lnames, inames].map{ |names| 
									names.inject({}) { |vars, name| vars[name] = binding.eval(name.to_s) and vars } rescue nil
								}
								@_trace = %{  -local variables: #{lvars}\n  -instance variables: #{ivars}\n  }
							end
							result = method_object.bind(self).call(*args, &block) 
						end
				
					end
				end
		
			end
	
			inject logger
			inject splatter
		
		end
	end
end
include Jackbox::Examples

def splat *args
	DX.splat( 1 + args.first ) rescue DX.splat(1)
end

# def log *args
# 	DX.log
# end
DX.assert_loaded
