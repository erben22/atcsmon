#===============================================================================
# Main app runner.
#===============================================================================
require 'optparse'

options = {}
OptionParser.new do |opt|
  opt.on('--mdb_file MDBFILE') { |o| options[:mdb_file] = o }
  opt.on('--territoryDir ./directory') { |o| options[:territoryDir] = o }
end.parse!

puts options
puts options[:mdb_file]
puts options[:territoryDir]

if File.directory?("#{options[:territoryDir]}") && File.exist?(options[:territoryDir])
  #files = Dir.glob("#{:territoryDir}/*.zip")
  #puts files[]
  puts "test"
end
