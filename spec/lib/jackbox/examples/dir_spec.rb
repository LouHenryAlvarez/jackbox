require "spec_helper"
=begin rdoc
	dir_spec
	author: Lou Henry
	:nodoc:all
=end

describe Dir do

	#####
	# Dir class tools

	it 'modifies Dir class to include additional methods' do
		Dir.should respond_to(:exists?)
		Dir.should respond_to(:gem?)
		Dir.should respond_to(:empty?)
		Dir.should respond_to(:clear?)
		Dir.should respond_to(:ls)
		Dir.should respond_to(:la)
	end

	describe "Dir.gem?" do
		def gem_structure
			File.open File.basename(Dir.pwd) + '-0.0.1.gemspec', 'w' do |file| end
			File.open 'Rakefile', 'w' do |file|; end
			FileUtils.mkpath File.join('lib', File.basename(Dir.pwd))
			File.open File.join('lib', File.basename(Dir.pwd) + '.rb'), 'w' do |file| end
			File.open File.join('lib', File.basename(Dir.pwd), 'version.rb'), 'w' do |file|;	end
		end
		def rem_structure
			(dir = Dir['*']).each { |d| FileUtils.rm_rf d }
		end

		specify 'Dir.gem? should be true if directory has a gem strucure' do
			gem_structure
			Dir.should be_gem
		end

		specify 'Dir.empty? should be true if dir is empty' do
			rem_structure
			Dir.should be_empty
		end
	end

	describe "Dir.empty?, Dir.clear?" do
		def rfile
			(1..8).map { |c| ('a'..'z').to_a.sample }.join
		end
		
		before :each do
			FileUtils.rm_rf '.'
		end

		example 'if NO files are present' do
			Dir.should be_empty
			Dir.should be_clear
		end

		example 'if just a single regular files are present' do
			FileUtils.touch rfile
			Dir.should_not be_empty
			Dir.should_not be_clear
		end

		example 'empty but not clear/clear is also empty' do

			# add a couple of files
			FileUtils.touch('.tester') 
			FileUtils.touch('mester')

			# delete regular files
			File.delete('mester')

			# should be empty but not clear
			Dir.should be_empty
			Dir.should_not be_clear
			
			# delete .dotfiles
			File.delete('.tester')
			
			# should be empty and clear
			Dir.should be_empty
			Dir.should be_clear

		end
	end
	
	describe 'Dir.new' do
		before do
			FileUtils.rm_rf '.'
		end

		it 'actually creates a somedir directory' do

			# assert conditions before
			Dir.should be_empty
			Dir.should be_clear
			
			# add directory
			somedir = Dir.new 'somedir'

			# assert dir conditions
			Dir.should_not be_empty
			File.should be_directory('somedir')
			# assert variable
			somedir.should be_instance_of(Dir)

		end
	end	
	
	describe 'Dir.entries, ls, la' do
		before do
			FileUtils.rm_rf '.'
		end

		it 'returns a list of members in dir' do

			# add a couple of files
			FileUtils.touch('.tester') 
			FileUtils.touch('mester')
			# add a directory
			somedir = Dir.new 'somedir'
			
			# assert entries returns everything/same as #la
			# Note: done in this funny way because ordering may be PLATFORM dependent
			(['.', '..', '.tester', 'mester', 'somedir'] - Dir.entries('.')).should == []
			(Dir.entries('.') - Dir.la).should == []
			
		end
		
		it 'has ls return only non dotfiles' do
			
			# add a couple of files
			FileUtils.touch('.tester') 
			FileUtils.touch('mester')
			# add a directory
			somedir = Dir.new 'somedir'
			
			# assert entries returns everything/same as #la
			# Note: done in this funny way because ordering may be PLATFORM dependent
			(['mester', 'somedir'] - Dir.ls).should == []
			
		end
		
	end
	
end
