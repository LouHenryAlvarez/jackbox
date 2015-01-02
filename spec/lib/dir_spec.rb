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

		specify 'if files are present' do
			FileUtils.touch rfile
			Dir.should_not be_empty
			Dir.should_not be_clear
		end

		specify 'if NO files are present' do
			Dir.should be_empty
			Dir.should be_clear
		end

		specify 'empty but not clear/clear is also empty' do
			# add a couple of files
			FileUtils.touch('.tester') 
			FileUtils.touch('mester')
			#test for empty
			Dir.should_not be_empty
			Dir.should_not be_clear
			File.delete('mester')
			Dir.should be_empty
			# test for clear of . files
			Dir.should_not be_clear
			File.delete('.tester')
			Dir.should be_empty
			Dir.should be_clear
		end
	end
	
	describe 'Dir.new' do
		before do
			FileUtils.rm_rf '.'
		end
		it 'should have a somedir directory' do
			# add directory
			somedir = Dir.new 'somedir'
			# test dir conditions
			somedir.should be_instance_of(Dir)
			Dir.should_not be_empty
			Dir.ls.grep(/somedir/).should_not be_empty
			File.should be_directory('somedir')
		end
	end	
	
	describe 'Dir.entries' do
		before do
			FileUtils.rm_rf '.'
		end
		it 'returns a list of members in dir' do
			# add a couple of files
			FileUtils.touch('.tester') 
			FileUtils.touch('mester')
			# add a directory
			somedir = Dir.new 'somedir'
			# test for conditions
			Dir.entries.should == ['.', '..', '.tester', 'mester', 'somedir']
		end
	end
	
end
