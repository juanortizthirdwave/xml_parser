require 'csv'
require 'cgi'
require 'pry-byebug'
require 'nokogiri'

class XmlParser
  def initialize(file)
    xml = get_object(file)
    @csv_file = CSV.open('converted_file.csv', 'w')
    @main_element = xml.xpath(name = "j2xml").children
    @category = ""
  end

  def convert
    add_columns
    populate_rows
    close_files
  end

  private

  def get_object(file)
    file_name = File.expand_path("./", file)
    xml_file = File.open(file_name)
    Nokogiri::XML(xml_file) { |config| config.options = Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::NOENT | config.options = Nokogiri::XML::ParseOptions::NOCDATA }
  end
  
  def add_columns
    content_fields = @main_element.xpath("//content").first.children.map { |c| c.name }
    columns = (['category'] + content_fields).flatten
    @csv_file << columns
  end

  def populate_rows
    @main_element.each do |e|
      update_category(e)
      add_rows(e)
    end
  end

  def update_category(node)
    @category = node.name == "category" ? node.xpath('title').text : @category
  end

  def close_files
    @csv_file.close
  end

  def add_rows(node)
    if node.name == "content"
      content = node.children.reduce([@category]){|row, el|  row << CGI.unescapeHTML(el.text)}
      @csv_file << content
    end
  end

  def parse_entities(string)
    string.gsub(/<!\[CDATA\[(.*)\]\]>/m){ |m| CGI.unescapeHTML($1) }
  end
end

XmlParser.new("j2xml150620141028111948copy").convert