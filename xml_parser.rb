require 'csv'
require 'cgi'
require 'pry-byebug'
require 'nokogiri'

class XmlParser
  def initialize(file)
    xml = get_object(file)
    @csv_file = CSV.open('converted_file.csv', 'w')
    @main_element = xml.xpath(name = "j2xml").children
    @columns = []
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
    @columns = (['category'] + content_fields).flatten
    ["alias", "title_alias" , "created_by_alias" , "checked_out", "checked_out_time", 
      "publish_up", "publish_down", "images", "urls", "attribs"].each { |el| @columns.delete el }
    @csv_file << @columns
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

  def add_rows(node)
    if node.name == "content"
      row = @columns[1..-1].reduce([@category]) do |content, col_name|
        text = node.xpath("#{col_name}").text
        content << CGI.unescapeHTML(text)
      end
      @csv_file << row
    end
  end

  def close_files
    @csv_file.close
  end

  def parse_entities(string)
    string.gsub(/<!\[CDATA\[(.*)\]\]>/m){ |m| CGI.unescapeHTML($1) }
  end
end

XmlParser.new("j2xml150620141028111948").convert


=begin
'//title' this searches for all <title> elements starting at the root of the document. 
Use either simply 'title' to find child titles, 
or './/title' if you want to find titles even if they are nested inside of other elements.  
=end

