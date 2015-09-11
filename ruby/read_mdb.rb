require 'mdb'
require 'optparse'

#===============================================================================
# Main app runner.
#===============================================================================

options = {}
OptionParser.new do |opt|
  opt.on('--mdb_file MDBFILE') { |o| options[:mdb_file] = o }
end.parse!

puts options
puts options[:mdb_file]

database = Mdb.open(File.expand_path(options[:mdb_file]))

puts database.tables

database[:MCP].each do |mcp_entry|
  puts "MCP address #{mcp_entry[:MCPAddress]}:#{mcp_entry[:MCPName]}"
end