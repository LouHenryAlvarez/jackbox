require "spec_helper" 
require "jackbox/examples/transformers" 

$sources = [
	REXML::Document.new(open('spec/lib/jackbox/examples/source1.xml')), 
	REXML::Document.new(open('spec/lib/jackbox/examples/source2.xml')),
	REXML::Document.new(open('spec/lib/jackbox/examples/source3.xml'))
]

REXML::Document.new(open('spec/lib/jackbox/examples/result.xml')).write $xml = '', 1

describe "transformers" do
	it 'uses this pattern to process xml' do

		$sources.each { |so|  
		
			peeps = People.new
		
			with Transformer().tags do
				
				reverse_each { |v| 
					peeps.extend( v ) 
					peeps.load(so) 
					break unless peeps.transform.empty?
				}
				
			end
			
			peeps.to_xml.should == $xml
			# puts so, peeps.to_xml, $xml

		}

	end
end