class ATCSMonTerritory
  require './read_mdb.rb'
  require 'fileutils'

  attr_accessor :territory_path

  def initialize(territory_path)
    @territory_path = territory_path
    @extract_dir = ''
  end

  def extract_territory()
    require 'zip'
    puts "Extracting territory: #{@territory_path}"
    @extract_dir = File.join(ENV['TMPDIR'], 'ATCSMonTerritoryExtract')

    FileUtils.rm_rf(@extract_dir) if File.exist?(@extract_dir)
    FileUtils::mkdir_p @extract_dir

    zipfile = Zip::File.new(@territory_path)
    zipfile.each_with_index do |entry, index|
      puts "  entry #{index} is #{entry.name}, size = #{entry.size}, compressed size = #{entry.compressed_size}"
      entry.extract(File.join(@extract_dir, entry.name))
    end
  end

  def get_territory_details()
    territory_details = {}

    territory_details[:mdb_file] = Dir.glob(File.join(@extract_dir, '*.mdb'))
    territory_details[:mcp_file] = Dir.glob(File.join(@extract_dir, '*.mcp'))
    territory_details[:layout_file] = Dir.glob(File.join(@extract_dir, '*.lay'))
    territory_details[:ini_file] = Dir.glob(File.join(@extract_dir, '*.ini'))
    territory_details[:kmz_file] = Dir.glob(File.join(@extract_dir, '*.kmz'))
    territory_details[:text_file] = Dir.glob(File.join(@extract_dir, '*.txt'))
    territory_details[:pdf_file] = Dir.glob(File.join(@extract_dir, '*.pdf'))
    territory_details[:spreadsheet_file] = Dir.glob(File.join(@extract_dir, '*.xls'))
    
    puts territory_details
  end

end
