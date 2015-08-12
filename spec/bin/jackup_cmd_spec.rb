require 'spec_helper'
require_relative "jackup_cmd_shared"

=begin rdoc
	jackup_cmd_spec
	author: Lou Henry
	
  The idea here is:
  We call jackup to add our jackup library onto the project call graph
  on top of bundler as a default dependency manager and on top of rubygems,
  heavily relying on the rubygems infrastructure, especially after 1.9
	
=end
decorate :system do |*args|
	pid = spawn(*args)
	Process.wait(pid, 0)
end

describe 'jackup command', :command do

  # Helpers' module
  # include Spec_Helpers
      
  ###### 	
  # We test for a basic setup: (system requirements)
  # 
  # A basic setup is the availabilty of the bundler gem and rubygems
  # there 'should be a basic setup' do |variable|
	before :all do
    system('which gem').should be
    system('which bundle').should be
  end



  ###### 	
  # There are certain rules to determine which ruby files get 'tooled', and
  # how the whole project dir gets evaluated and contructed if needed.
  
  # when project dir is empty
  context 'if the project dir is empty' do
  		context 'if jackup --no-gem --no-bundle command is issued', :empty_dir do
  			# command issued
      before(:all) { 
	p "----------------------#{Dir.pwd}------------------------------------------"
	system 'jackup --no-gem --no-bundle' }
  			####
  			assure 'a simple structure'
  			it_behaves_like 'a tooled project'
  
  		end
  
    context 'if --no-gem directive is issued', :empty_dir do 
  			# command issued
      before(:all) { system 'jackup --no-gem'}
  			###
  			assure 'a simple structure'
  			assure_it 'has custom files'
      it_behaves_like 'a tooled project'
  
    end
  
    context 'if --no-bundle directive is issued', :empty_dir do 
  			# command issued
      before(:all) { system 'jackup --no-bundle' }
  			####
  			assure_it 'defines a gem project'
  			it_behaves_like 'a tooled project'
  
    end
  
    context 'if default directive is issued', :empty_dir do 
  			# command issued
      before(:all) { system 'jackup'}
  			###
  			assure_it 'defines a gem project'
  			assure_it 'has custom files'
      it_behaves_like 'a tooled project'	
  
    end
  
    context 'when a non-existing empty dir is given', :empty_dir do
  			# command issued
      before(:all) { system 'jackup stage newdir' }
  			###
  			there 'is a dir by the given name' do
        File.exists?('newdir').should be
      end
      describe 'newdir' do
  
        before :all do
          Dir.chdir 'newdir'
        end
  				###
  				assure_it 'defines a gem project'
  				assure_it 'has custom files'
        	it_behaves_like 'a tooled project'
  				###
        after :all do
          Dir.chdir '..'
        end
  
      end
    end
  
  end
  
  
  
  # if project is a plain old ruby project then 
  # this means the presence of a basic ruby structure
  context 'if project is a plain old ruby project' do
    context 'if already a bundler project' do
  	    # if no-bunbler option then 
  	    context 'if the jackup --no-bundle --no-gem directive is issued', :basic_structure do
  				include_context 'create bundle'
  	 			# command issued
  	      before(:all) { system 'jackup --no-bundle --no-gem' }
  	 			###
  				assure 'a simple structure'
  				assure_it 'has custom files'
  				it_behaves_like 'a tooled project'#, on: 'simple strucure'
  
  	    end
  	    # 	else by default use bundler
  	    context 'using bundler but with --no-gem option', :basic_structure do
  				include_context 'create bundle'
  	 			# command issued
  	      before(:all) { system 'jackup --no-gem' }
  	 			###
  				assure 'a simple structure'
  				assure_it 'has custom files'#, on: 'simple structure'
  	      it_behaves_like 'a tooled project'
  
  	    end 
  
  			context 'if jackup --no-bundle is given', :basic_structure do
  				include_context 'create bundle'
  	 			# command issued
  				before(:all) { system 'jackup --no-bundle' }
  				#####
  				assure_it 'defines a gem project'
  				assure_it 'has custom files'
  				it_behaves_like 'a tooled project'
  
  			end
  
  	    context 'using bundler with all defaults', :basic_structure do
  				include_context 'create bundle'
  	 			# command issued
  	      before(:all) { system 'jackup' }
  	 			###
  				assure_it 'defines a gem project'
  				assure_it 'has custom files'
  	      it_behaves_like 'a tooled project'
  
  	    end
  		end
  		
  		context 'if not bunbler project' do
  	    # if no-bunbler option then 
  	    context 'if the jackup --no-bundle --no-gem directive is issued', :basic_structure do
  	 			# command issued
  	      before(:all) { system 'jackup --no-bundle --no-gem' }
  	 			###
  				assure 'a simple structure'
  				it_behaves_like 'a tooled project'#, on: 'simple strucure'
  
  	    end
  	    # 	else by default use bundler
  	    context 'using bundler but with --no-gem option', :basic_structure do
  	 			# command issued
  	      before(:all) { system 'jackup --no-gem' }
  	 			###
  				assure 'a simple structure'
  				assure_it 'has custom files'#, on: 'simple structure'
  	      it_behaves_like 'a tooled project'
  
  	    end 
  
  			context 'if jackup --no-bundle is given', :basic_structure do
  	 			# command issued
  				before(:all) { system 'jackup --no-bundle' }
  				###
  				assure_it 'defines a gem project'
  				it_behaves_like 'a tooled project'
  
  			end
  
  	    context 'using bundler with all defaults', :basic_structure do
  	 			# command issued
  	      before(:all) { system 'jackup' }
  	 			###
  				assure_it 'defines a gem project'
  				assure_it 'has custom files'#, on: 'simple structure'
  	      it_behaves_like 'a tooled project'
  
  	    end
  		end
  end
  


	#
	# if a project is a gem then 
  # 
	context 'if project is a gem' do

	  # when project is a bundler project
	  context 'if project is a bundler project already' do
			context 'if jackup --no-gem --no-bundle', :gem_structure do
				include_context 'create bundle'
	 			# command issued
				before(:all) { system 'jackup --no-gem --no-bundle'}
				#####
				assure_it 'defines a gem project'
				assure_it 'has custom files'
				it_should_behave_like 'a tooled project'

			end
			context 'if jackup --no-gem', :gem_structure do
				include_context 'create bundle'
	 			# command issued
				before(:all) { system 'jackup --no-gem'}
				#####
				assure_it 'defines a gem project'
				assure_it 'has custom files'
				it_should_behave_like 'a tooled project'

			end
			context 'if jackup --no-bundle', :gem_structure do
				include_context 'create bundle'
	 			# command issued
				before(:all) { system 'jackup --no-bundle'}
				#####
				assure_it 'defines a gem project'
				assure_it 'has custom files'
				it_should_behave_like 'a tooled project'

			end
			context 'if default jackup directive issued', :gem_structure do
				include_context 'create bundle'
	 			# command issued
				before(:all) { system 'jackup'}
				#####
				assure_it 'defines a gem project'
				assure_it 'has custom files'
				it_should_behave_like 'a tooled project'

			end
		end

	  context 'if project is not bundler project already' do
			context 'if jackup --no-gem --no-bundle', :gem_structure do
	 			# command issued
				before(:all) { system 'jackup --no-gem --no-bundle'}
				#####
				assure_it 'defines a gem project'
				it_should_behave_like 'a tooled project'

			end
			context 'if jackup --no-gem', :gem_structure do
	 			# command issued
				before(:all) { system 'jackup --no-gem'}
				#####
				assure_it 'defines a gem project'
				assure_it 'has custom files'
				it_should_behave_like 'a tooled project'

			end
			context 'if jackup --no-bundle', :gem_structure do
	 			# command issued
				before(:all) { system 'jackup --no-bundle'}
				#####
				assure_it 'defines a gem project'
				it_should_behave_like 'a tooled project'

			end
			context 'if default jackup directive issued', :gem_structure do
	 			# command issued
				before(:all) { system 'jackup'}
				#####
				assure_it 'defines a gem project'
				assure_it 'has custom files'
				it_should_behave_like 'a tooled project'

			end
		end
	
	end

end #jackup command
