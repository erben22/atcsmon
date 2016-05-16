class ATCSDB
  require 'mdb'

  def initialize(mdb_file)
    @mdb_file = mdb_file
  end

  def read_mdb()
    puts "Database #{@mdb_file} does not exist" unless File.exists?(@mdb_file)
    return unless File.exists?(@mdb_file)

    database = Mdb.open(File.expand_path(@mdb_file))

    puts "Tables: #{database.tables}"
    puts "MCP Table Columns: #{database.columns('MCP')}"

    database[:MCP].each do |mcp_entry|
      puts "MCP address #{mcp_entry[:MCPAddress]}:#{mcp_entry[:MCPName]}"
    end
  end

end
