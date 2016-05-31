=begin rdoc
	
	Copyright © 2014 LHA. All rights reserved.
	
	Dir class extensions
		
=end

# 
# Modifies Dir to include some methods found useful by the author
# * New now really means #new, aka a new directory is created
# * Adds some more predicates to Dir class
# * Adds more contents listing methods and changes some defaults
# * #entries has a default to listing entries in pwd
class Dir
	
	#
	# Methods for Dir singleton
	# 
	with singleton_class do

		decorate :new do |name, &code|
			FileUtils.mkpath name unless exists?(name)
			return Dir.open(name, &code) if code
			Dir.open name
		end
		
		# returns true when a <dir> exists
    def exists? dir 
      File.exists? dir and File.directory? dir
    end
		alias exist? exists?
		
		# return true when reciver has a gem layout
    def gem? 
      Dir['*.gemspec'].size > 0 &&
      Dir.exists?( 'lib' )&&
      File.exists?( File.join('lib', File.basename(pwd) + '.rb') )&&
      Dir.exists?( File.join('lib', File.basename(pwd)) )&&
      File.exists?( File.join('lib', File.basename(pwd), 'version.rb'))
    end

		# true if receiver is completely clear of all entries (including .files)
    def clear? 
      (Dir.entries('.') - ['.', '..']) == []
    end

		# true when receiver is empty of normal files and dirs
    def empty? 
      Dir['*'].empty?
    end

		lets patherize =->(pattern){
			pattern = "#{pattern}/*" if Dir.exists?(pattern)
			pattern
		}   
		
		# lists files and dirs in receiver as [array]
		lets :ls do |pattern='*'|
			Dir.glob patherize[pattern]
		end
		
		# alias for ls used with pry name clash
    alias :list :ls

		# lists all files and dir in receiver (including .files) as [array]
		lets :la do |pattern='*'|
			Dir.glob patherize[pattern], File::FNM_DOTMATCH
		end
		
  end
	
end


