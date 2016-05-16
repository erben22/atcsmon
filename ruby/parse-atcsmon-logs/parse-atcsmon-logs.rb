###############################################################################
# 
# 
# 
# 
# 
###############################################################################
#require_relative './mythdb'

class MythDB
    require 'mysql2'

    def connect_database
        puts 'connecting to the database...'

        client = Mysql2::Client.new(:host => "192.168.2.66", :username => "mythtv",
            :password => "RRw0VDia")

        program_name = "Silicon Valley"
        subtitle = ""

        results = client.query("SELECT chanid,starttime,endtime,originalairdate,basename,title,subtitle FROM mythconverg.recorded WHERE title LIKE \'#{program_name}\'")

        results.each do |row|
            # conveniently, row is a hash
            # the keys are the fields, as you'd expect
            # the values are pre-built ruby primitives mapped from their corresponding field types in MySQL
            puts row["chanid"] # row["id"].class == Fixnum
            if row["originalairdate"]  # non-existant hash entry is nil
                puts row["originalairdate"]
            end
        end
    end

end

###############################################################################
# 
# Main entry point for the app...
# 
###############################################################################
mythdb = MythDB.new
mythdb.connect_database

