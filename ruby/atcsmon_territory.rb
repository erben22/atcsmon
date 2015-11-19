class ATCSMonTerritory
  require './read_mdb.rb'
  require 'fileutils'
  require 'zip'

  attr_accessor :territory_path

  def initialize(territory_path, atcsmon_dir)
    @territory_path = territory_path
    @extract_dir = ''
    @territory_details = {}
    @atcsmon_dir = atcsmon_dir
  end

  def extract_territory()
    puts "Extracting territory: #{@territory_path}"
    @extract_dir = File.join(ENV['TMPDIR'], 'ATCSMonTerritoryExtract')

    FileUtils.rm_rf(@extract_dir) if File.exist?(@extract_dir)
    FileUtils::mkdir_p @extract_dir

    Zip::File.open(@territory_path) do |zip_file|
      zip_file.restore_times = true
      zip_file.each do |entry|
        puts "  entry is #{entry.name}, size = #{entry.size}, compressed size = #{entry.compressed_size}"
        entry.extract(File.join(@extract_dir, entry.name))
      end
    end

  end

  def get_territory_details()
    @territory_details = {}

    @territory_details[:mdb_file] = Dir.glob(File.join(@extract_dir, '*.mdb'))
    @territory_details[:mcp_file] = Dir.glob(File.join(@extract_dir, '*.mcp'))
    @territory_details[:layout_file] = Dir.glob(File.join(@extract_dir, '*.lay'))
    @territory_details[:ini_file] = Dir.glob(File.join(@extract_dir, '*.ini'))
    @territory_details[:kmz_file] = Dir.glob(File.join(@extract_dir, '*.kmz'))
    @territory_details[:text_file] = Dir.glob(File.join(@extract_dir, '*.txt'))
    @territory_details[:pdf_file] = Dir.glob(File.join(@extract_dir, '*.pdf'))
    @territory_details[:spreadsheet_file] = Dir.glob(File.join(@extract_dir, '*.xls'))
    @territory_details[:doc_file] = Dir.glob(File.join(@extract_dir, '*.doc'))
    @territory_details[:fonts] = Dir.glob(File.join(@extract_dir, '*.ttf'))
    @territory_details[:rtf] = Dir.glob(File.join(@extract_dir, '*.rtf'))
    @territory_details[:sound] = Dir.glob(File.join(@extract_dir, '*.wav'))

    @territory_details
  end

  def stage_territory()

    puts @territory_details

    return unless File.exists?(@atcsmon_dir)
    
    @territory_details[:mdb_file].each do |mdbfile|
      puts "  Processing mdbfile: #{mdbfile}"
      FileUtils.mkdir_p File.join(@atcsmon_dir, 'MCPs/')
      FileUtils.cp_r mdbfile, File.join(@atcsmon_dir, 'MCPs/'), :verbose => true, :preserve => true
    end

  end

end
