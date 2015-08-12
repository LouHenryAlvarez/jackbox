require "rexml/document"
require 'jackbox'

class Person
  attr_accessor :first_name
  attr_accessor :last_name
  def initialize(attributes={})
    attributes.each do |k,v|
      send("#{k}=", v)
    end
  end
end

class People
  def initialize(people=[])
    @people = people
  end
  def <<(person)
    @people << person
  end
  def empty?
    @people.empty?
  end
  def to_xml
		doc = REXML::Document.new("<?xml version='1.0'?>")
		root = doc.add_element("people")
	  @people.each do |p|
	    with root.add_element("person") do
	      with add_element("name") do
	        add_element("first").text = p.first_name
	        add_element("last").text = p.last_name
	      end
	    end
	  end 
		doc.write xml = '', 1
		xml
  end

end


injector :Transformer do
	def load(file_name_or_doc)
    @doc = if file_name_or_doc.is_a?(REXML::Document)
      file_name_or_doc
    else
      REXML::Document.new(open(file_name_or_doc))
    end
  end
  def transform                                       
    person_nodes = @doc.get_elements(person_xpath_query) 
    unless person_nodes.nil? 
      @people = person_nodes.map do |node|
        Person.new(
          :first_name => node.get_elements(first_name_xpath_query).first.text,
          :last_name => node.get_elements(last_name_xpath_query).first.text)
      end
    end
	end
end


AddressBookT = Transformer( :tag ) do
	def person_xpath_query
		 "//address_book/contact/name"
	end
	def first_name_xpath_query
		'first'
	end
	def last_name_xpath_query
		'last'
	end
end 

Transformer( :segment ) do 									# unnamed tag or segment
	def person_xpath_query
		"//employees/employee"
	end
	def first_name_xpath_query
		'first_name'
	end
	def last_name_xpath_query
		'surname'
	end
end   

Transformer( :segment ) do                   # unnamed segment
	def person_xpath_query
		"//people/person"
	end
	def first_name_xpath_query
		'first_name'
	end
	def last_name_xpath_query
		'last_name'
	end
end



                                	