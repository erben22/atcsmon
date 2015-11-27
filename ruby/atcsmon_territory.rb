class TerritoryDetailData
  attr_accessor :key_name, :file_pattern, :extract_subdir

  def initialize(key_name, file_pattern, extract_subdir)
    @key_name = key_name
    @file_pattern = file_pattern
    @extract_subdir = extract_subdir
  end

end

class ATCSMonTerritory
  require './read_mdb.rb'
  require 'fileutils'
  require 'zip'
  require 'pathname'

  attr_accessor :territory_path # Needed?

  def initialize(territory_path, atcsmon_dir)
    @territory_path = territory_path
    @extract_dir = ''
    @territory_details = {}
    @atcsmon_dir = atcsmon_dir

    @territory_data = [
        TerritoryDetailData.new(:mdb_file, '*.mdb', 'MCPs/'),
        TerritoryDetailData.new(:mcp_file, '*.mcp', 'MCPs/'),
        TerritoryDetailData.new(:layout_file, '*.lay', 'Layouts/'),
        TerritoryDetailData.new(:text_file, '{[!readme]}*.txt', 'Layouts/'),
        TerritoryDetailData.new(:ini_file, '*.ini', ''),
        TerritoryDetailData.new(:readme_file, 'readme*.txt', ''),
        TerritoryDetailData.new(:kmz_file, '*.kmz', 'kmz/'),
        TerritoryDetailData.new(:doc_file, '*.doc', 'doc/'),
        TerritoryDetailData.new(:pdf_file, '*.pdf', 'pdf/'),
        TerritoryDetailData.new(:rtf, '*.rtf', 'rtf/'),
        TerritoryDetailData.new(:spreadsheet_file, '*.xls', 'xls/'),
        TerritoryDetailData.new(:fonts, '*.ttf', 'Fonts/'),
        TerritoryDetailData.new(:sound, '*.wav', 'wav/'),
    ]
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

    @territory_data.each do |territorydata|
      @territory_details[territorydata.key_name] = 
        Dir.glob(File.join(@extract_dir, territorydata.file_pattern))
    end

    @territory_details
  end

  def stage_territory()

    puts @territory_details

    return unless File.exists?(@atcsmon_dir)

    @territory_data.each do |territorydata|

      @territory_details[territorydata.key_name].each do |details_data|
        puts "  Processing details_data: #{details_data}"
        FileUtils.mkdir_p File.join(@atcsmon_dir, territorydata.extract_subdir)
        FileUtils.cp_r details_data, 
          File.join(@atcsmon_dir, territorydata.extract_subdir), 
            :verbose => true, :preserve => true
      end
    end

  end

end
