class ATCSMonTerritory
  require './read_mdb.rb'

  def extract_territory
    read_mdb(options[:mdb_file])
  end
end
