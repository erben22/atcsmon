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

        mcp_data = "6738303238333638373005FB030331F6"
        decoded_mcp = [mcp_data].pack('H*')
        insert_sql = 'INSERT INTO atcsmon.atcsmon (id, timestamp,mnemonic) VALUES(DEFAULT, "2016/06/01 02:22:20", "'+ decoded_mcp + '");'

        #LAYOUT:
        #Comand Byte        $FC
        #Station Number     $01-$FF
        #Control Byte No    $00-$FF
        #Control Byte       $00-$FF
        #(repeat as required)
        #CRC Low Byte       $00-$FF
        #CRC High Byte      $00-$FF
        #Terminator         $F6

        #6738303238333638373005FB030331F6
        #67 = g (protocol - g - genesis)
        #383032 = 802 (RR id - 802 - UPRR)
        #38 33 36 38 37 = 83687
        #30 - Zip Suffix - 0
        #05 - Message Type? - 05 - UP Outbound ACK / Poll (3) (Frame 5)
        #FB - Command Byte - 251 - to Wayside Device (251)
        #03 - Station Number - 003
        #03 - Control Byte Number -  bytes
        #31 - Control Byte - 31
        #F6 - Terminator (always F6)

        #6738303238333638373005FB058333F6
        #67 = g (protocol - g - genesis)
        #383032 = 802 (RR id - 802 - UPRR)
        #38 33 36 38 37 = 83687
        #30 - Zip Suffix - 0
        #05 - Message Type? - 05 - UP Outbound ACK / Poll (3) (Frame 5)
        #FB - Command Byte - 251 - to Wayside Device (251)
        #05 - Station Number - 005
        #83 - Control Byte Number - 83
        #33 - Control Byte - 33
        #F6 - Terminator
        
        #67383032383336383730 C332F6
        #67 = g (protocol - g - genesis)
        #383032 = 802 (RR id - 802 - UPRR)
        #38 33 36 38 37 = 83687
        #30 - Zip Suffix - 0
        #05 - Message Type - 5 - UP Outbound ACK / Poll (3) (Frame 5)
        #FB - Command Byte - 251 - to Wayside Device (251)
        #06 - Station Number - 006
        #C3 - Control Byte Number - C3
        #32 - Control Byte
        #F6 - Terminator

        #67383032383336383730 05 FB 02C2F1F6
        #67 = g (protocol - g - genesis)
        #383032 = 802 (RR id - 802 - UPRR)
        #38 33 36 38 37 = 83687
        #30 - Zip Suffix - 0
        #05 - Message Type - 5 - UP Outbound ACK / Poll (3) (Frame 5)
        #FB - Command Byte - 251 - to Wayside Device (251)
        #02 - Station Number - 002
        #C2 - Control Byte Number - C3
        #F1 - Control Byte
        #F6 - Terminator


        #67383032383336383730 07FC05 0006A053F6
        #67 = g (protocol - g - genesis)
        #383032 = 802 (RR id - 802 - UPRR)
        #38 33 36 38 37 = 83687
        #30 - Zip Suffix - 0
        #07 - Message Type - 07 - UP Datagram (1) (Frame 7)
        #FC - Command Byte - 252 - to Wayside Device (252)
        #05 - Station Numer - 005
        #00 - Control Byte Number - 00
        #06 - Control Bytes - Mnemonics - 06 - 0110
        #A0 - CRC Low Byte
        #53 - CRC High Byte
        #F6 - Terminator

        #Number=0.0.252 Genisys_Control_Message
        #Mnemonics=C13,C12
        #00 06   
        #0000 0000 0000 0110
        #               C14 C13 C12 C11 
        #0000 0000 0000  0   1   1   0




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
