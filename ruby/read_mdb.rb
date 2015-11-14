def read_mdb(mdb_file)
  require 'mdb'

  database = Mdb.open(File.expand_path(mdb_file))

  puts database.tables

  database[:MCP].each do |mcp_entry|
    puts "MCP address #{mcp_entry[:MCPAddress]}:#{mcp_entry[:MCPName]}"
  end
end
