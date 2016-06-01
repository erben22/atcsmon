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

        @client = Mysql2::Client.new(:host => "localhost", :username => "atcsmon",
            :password => "atcsmon")

        #results = client.query("SELECT * FROM atcsmon.atcsmon WHERE id > 0")

        #results.each do |row|
            # conveniently, row is a hash
            # the keys are the fields, as you'd expect
            # the values are pre-built ruby primitives mapped from their corresponding field types in MySQL
        #    output=row["id"] # row["id"].class == Fixnum
        #    if row["timestamp"]  # non-existant hash entry is nil
        #        output+=row["timestamp"]
        #    end
        #    if row["mnemonic"]  # non-existant hash entry is nil
        #        output+=row["mnemonic"]
        #    end

        #    puts output
        #end
    end

    def insert_record
        puts 'Inserting a record into the database...'

        insert_sql = 'INSERT INTO atcsmon.atcsmon (id, timestamp,mnemonic) VALUES(DEFAULT, "2016/06/01 02:22:20", "6738303238333638373005FB030331F6");'

        @client.query insert_sql
    end

end

###############################################################################
# 
# Main entry point for the app...
# 
###############################################################################
mythdb = MythDB.new
mythdb.connect_database
mythdb.insert_record
