class ATCSMonTerritory
  require './read_mdb.rb'

  attr_accessor :territory_path

  def initialize(territory_path)
    @territory_path = territory_path
  end

  def extract_territory()
    require 'zip'
    puts "Extracting territory: #{@territory_path}"
    dest_file = File.join(ENV['TMPDIR'], 'ATCSMonTerritoryExtract')
     
    zipfile = Zip::File.new(@territory_path)
    zipfile.each_with_index do |entry, index|
      puts "  entry #{index} is #{entry.name}, size = #{entry.size}, compressed size = #{entry.compressed_size}"
      entry.extract(dest_file)
      puts "    Extracted to: #{dest_file}"
    end
  end

end
