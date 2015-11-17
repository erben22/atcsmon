# Program to import ATCSMon territories and install them to
# the specified program directory.
#
# Author::  R. Cody Erben (mailto:erben22@mtnaircomputer.net)

# Parse command line options.
def parse_options()
  require 'optparse'

  options = {}
  OptionParser.new do |opt|
    opt.on('--mdb_file MDBFILE') { |o| options[:mdb_file] = o }
    opt.on('--territoryDir ./directory') { |o| options[:territoryDir] = o }
  end.parse!

  options
end

# Find all the territories in the specified directory.
def find_territories(root_territory_dir)

  files = {}

  if File.directory?("#{root_territory_dir}") && File.exist?(root_territory_dir)
    files = Dir.glob("#{root_territory_dir}/*.zip")
  else
    puts "Invalid directory: #{root_territory_dir}"
  end

  files
end

# Main app runner.

require './atcsmon_territory.rb'

cmdline_options = parse_options()
puts cmdline_options

territory_files = find_territories(cmdline_options[:territoryDir])
puts territory_files

territory_files.each do |territory_path|
  territory = ATCSMonTerritory.new(territory_path)
  territory.extract_territory()
end
