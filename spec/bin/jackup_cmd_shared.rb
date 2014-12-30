require "spec_helper"
=begin rdoc

	Author: LHA

	Shared examples to test the cmdline utility (jackup)
	
=end

# Tester for an empty dir which has no entries
RSpec.shared_context 'an empty dir', :empty_dir do
	before :all do
		tmpdir = rfolder()
		Dir.new tmpdir
		Dir.chdir tmpdir
	end
end


# tests a basic project structure has some files 
RSpec.shared_examples 'a simple structure', on: 'simple structure' do
  there 'should be a simple structure' do
		Dir.should_not be_gem
		Dir.ls('**/*.rb').should_not be_empty
	end
end

# creates a basic folder structure
RSpec.shared_context 'a basic structure', :basic_structure do
	# contexts
	include_context 'an empty dir'
	# create folders and files
	before(:all) do
		# create folders
    [ 'bin', "lib/#{File.basename(Dir.pwd)}", 'spec', 'test'].each { |e| FileUtils.mkpath e }
		# create files
    10.times do
      FileUtils.touch(
        [
          "#{File.basename(Dir.pwd)}.rb",
          "bin/#{File.basename(Dir.pwd)}", 
          "bin/#{File.basename(Dir.pwd)}.rb", 
          "lib/#{File.basename(Dir.pwd)}.rb",
          'lib/lib.rb', 
          "lib/#{(10000..20000).to_a.sample.to_s}.rb",
          'spec/some_spec.rb',
          'test/some_test.rb',
          "#{File.basename(Dir.pwd)}"
        ]
        .sample)
    end 
  end
end


# test has bunlder files
RSpec.shared_examples 'has custom files', on: 'bundle' do
	there 'should be the necessary bunler items' do
		File.should exist('Gemfile')
		File.should exist('Rakefile')
	end
end

# creates a bundle
RSpec.shared_context 'create bundle', :bundle do
	before(:all) do
		FileUtils.touch 'Gemfile'
	end
end


# test for a gem project
RSpec.shared_examples 'defines a gem project', on: 'gem project' do 
  it 'should be a gem' do
		Dir.should be_gem
  end
end

# creates a basic gem structure
RSpec.shared_context 'a gem structure', :gem_structure do
	# contexts
	include_context 'an empty dir'
	# generate files
	before(:all) do
		gemdir = `gem env gemdir`
		gempath = Dir.glob("#{gemdir.chop}/gems/thor*").last
		FileUtils.cp_r gempath, 'thor'
		Dir.chdir 'thor'
	end
end


#
# This is the main test of a "tooled project"
# A tooled project has the jackbox library available somewhere
# in its call graph
RSpec.shared_examples "a tooled project" do
	# test for Rakefile
	there 'should be a Rakefile' do
		File.should exist('Rakefile')
	end
	# test for testing directory
	there 'should be a testing directory' do
		Dir.should exist('spec').or exist('test') 
	end
  # declare what files to check
	let( :weighed_ruby_file) {
    ( 
			[File.join("lib","#{File.basename(Dir.pwd)}.rb")] +
			Dir.ls( '**/*.rb' ).sort
			.push("#{File.basename(Dir.pwd)}") +
			[File.join("bin","#{File.basename(Dir.pwd)}")]
    )
    .flatten.detect { |file| File.exists?(file) }
  } 
	# test the files for contents
  there "should be a proper content line in each filename" do

    {
      "Gemfile" 					=> 					/^gem ['|"]jackbox['|"]/, 
      "Rakefile" 					=> 					/^require ['|"]jackbox\/rake['|"]/,
      weighed_ruby_file 	=> 					/^require ['|"]jackbox['|"]/
    }
    .each do |filename, format|
	
			injector :line_predicates do
				define_method :require_line? do
					self.match( format )
				end
				define_method :blank_line? do
					self == "\n"
				end
			end
			
      File.open filename, 'r' do |file|
				# we must insure require lines are at the beginning
				requires = []
				# do we have any lines if not fail
				lines = file.each_line
				lines.count.should > 0
				# do we have any require's
				lines.rewind
				lines.next until (line = lines.peek).extend(line_predicates) and line.require_line? rescue false
				requires << lines.next while (line = lines.peek).extend(line_predicates) and (line.require_line? or line.blank_line?) rescue false
				# one of the list should be our line
				requires.select { |e| e.match format }.count.should == (1)
      end if filename && File.exists?( filename )
    end
  end
	
	there 'should be a .git directory' do
		Dir.should exist('.git')
	end
	
	it 'allows running rake tasks that produce no errors and have verifiable outputs' do
		def rake_run
			process = %Q{	
				def rake_run
					require 'rake'
					load 'Rakefile'
					Rake.application.tasks.map(&:name)
				end
				puts rake_run
			}			
			%x{env ruby -e "#{process}"}.split
		end
		if Dir.gem?
			(rake_run() & ["build", "default", "install", "release", "spec", "test"]).should == ["build", "default", "install", "release", "spec", "test"]
		else
			(["spec", "test"] & rake_run()).should == ["spec", "test"]
		end
	end

end


