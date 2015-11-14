#===============================================================================
# Main app runner.
#===============================================================================
require 'optparse'

options = {}
OptionParser.new do |opt|
  opt.on('--mdb_file MDBFILE') { |o| options[:mdb_file] = o }
  opt.on('--territory territory.zip') { |o| options[:territory] = o }
end.parse!

puts options
puts options[:mdb_file]

require './read_mdb.rb'

read_mdb(options[:mdb_file])
