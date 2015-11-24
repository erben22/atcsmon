class ATCSMonTerritory
  require './read_mdb.rb'
  require 'fileutils'
  require 'zip'
  require 'pathname'

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
        #puts "  entry is #{entry.name}, size = #{entry.size}, compressed size = #{entry.compressed_size}"
        #puts "  entry.time: #{entry.time}"

        entry.extract(File.join(@extract_dir, entry.name))
        File.utime(entry.time, entry.time, File.join(@extract_dir, entry.name))
      end
    end
  end

  def get_territory_details()
    @territory_details = {}

    @territory_details[:mdb_file] = Dir.glob(File.join(@extract_dir, '*.mdb'))
    @territory_details[:mcp_file] = Dir.glob(File.join(@extract_dir, '*.mcp'))

    @territory_details[:layout_file] = Dir.glob(File.join(@extract_dir, '*.lay'))
    @territory_details[:text_file] = Dir.glob(File.join(@extract_dir, '{[!readme]}*.txt'))

    @territory_details[:ini_file] = Dir.glob(File.join(@extract_dir, '*.ini'))
    @territory_details[:readme_file] = Dir.glob(File.join(@extract_dir, 'readme*.txt'))

    @territory_details[:kmz_file] = Dir.glob(File.join(@extract_dir, '*.kmz'))

    @territory_details[:doc_file] = Dir.glob(File.join(@extract_dir, '*.doc'))
    @territory_details[:pdf_file] = Dir.glob(File.join(@extract_dir, '*.pdf'))
    @territory_details[:rtf] = Dir.glob(File.join(@extract_dir, '*.rtf'))
    @territory_details[:spreadsheet_file] = Dir.glob(File.join(@extract_dir, '*.xls'))

    @territory_details[:fonts] = Dir.glob(File.join(@extract_dir, '*.ttf'))
    @territory_details[:sound] = Dir.glob(File.join(@extract_dir, '*.wav'))

    @territory_details
  end

  def stage_territory()

    puts @territory_details

    return unless File.exists?(@atcsmon_dir)

    # Stage the MCP database.  This can be either an MDB file,
    # or a text-based version in an MCP file.

    @territory_details[:mdb_file].each do |mdbfile|
      puts "  Processing mdbfile: #{mdbfile}"
      FileUtils.mkdir_p File.join(@atcsmon_dir, 'MCPs/')
      FileUtils.cp_r mdbfile, File.join(@atcsmon_dir, 'MCPs/'), :verbose => true, :preserve => true
    end

    @territory_details[:mcp_file].each do |mcpfile|
      puts "  Processing mdbfile: #{mcpfile}"
      FileUtils.mkdir_p File.join(@atcsmon_dir, 'MCPs/')
      FileUtils.cp_r mcpfile, File.join(@atcsmon_dir, 'MCPs/'), :verbose => true, :preserve => true
    end

    # TODO: Now, process the staged MCP database file(s)
    # and add them to the master database.

    puts "We will be a processing the MDB/MCP file here..."

    # Stage the layout file.

    @territory_details[:layout_file].each do |layoutfile|
      puts "  Processing layoutfile: #{layoutfile}"
      FileUtils.mkdir_p File.join(@atcsmon_dir, 'Layouts/')
      FileUtils.cp_r layoutfile, File.join(@atcsmon_dir, 'Layouts/'), :verbose => true, :preserve => true
    end

    @territory_details[:text_file].each do |textfile|
      puts "  Processing textfile: #{textfile}"
      FileUtils.mkdir_p File.join(@atcsmon_dir, 'Layouts/')
      FileUtils.cp_r textfile, File.join(@atcsmon_dir, 'Layouts/'), :verbose => true, :preserve => true
    end

    # Stage the ini file and readme*.txt file in the root dir.

    @territory_details[:ini_file].each do |inifile|
      puts "  Processing inifile: #{inifile}"
      FileUtils.cp_r inifile, @atcsmon_dir, :verbose => true, :preserve => true
    end

    @territory_details[:readme_file].each do |readmefile|
      puts "  Processing readmefile: #{readmefile}"
      FileUtils.cp_r readmefile, @atcsmon_dir, :verbose => true, :preserve => true
    end

    # Got KMZ?  If so, process:

      @territory_details[:kmz_file].each do |kmzfile|
      puts "  Processing kmzfile: #{kmzfile}"
      FileUtils.mkdir_p File.join(@atcsmon_dir, 'kmz/')
      FileUtils.cp_r kmzfile, File.join(@atcsmon_dir, 'kmz/'), :verbose => true, :preserve => true
    end


  end

end
