###############################################################################
# 
# 
# 
# 
# 
###############################################################################
#require_relative './mythdb'

class MCPData
    require 'digest/crc32'
    
    PROTOCOL_START_POSITION = 0
    PROTOCOL_SIZE = 2
    
    RAILROAD_START_POSITION = PROTOCOL_START_POSITION + PROTOCOL_SIZE
    RAILROAD_SIZE = 6
    
    ZIP_START_POSITION = RAILROAD_START_POSITION + RAILROAD_SIZE
    ZIP_SIZE = 10
    
    ZIP_SUFFIX_START_POSITION = ZIP_START_POSITION + ZIP_SIZE
    ZIP_SUFFIX_SIZE = 2

    MESSAGE_TYPE_START_POSITION = ZIP_SUFFIX_START_POSITION + ZIP_SUFFIX_SIZE
    MESSAGE_TYPE_SIZE = 2

    COMMAND_TYPE_START_POSITION = MESSAGE_TYPE_START_POSITION + MESSAGE_TYPE_SIZE
    COMMAND_TYPE_SIZE = 2

    STATION_ID_POSITION = COMMAND_TYPE_START_POSITION + COMMAND_TYPE_SIZE
    STATION_ID_SIZE = 2

    def get_protocol
        @protocol = @mcp_data[PROTOCOL_START_POSITION..(PROTOCOL_START_POSITION + PROTOCOL_SIZE-1)]
    end

    def get_railroad
        @railroad = [@mcp_data[RAILROAD_START_POSITION..(RAILROAD_START_POSITION + RAILROAD_SIZE-1)]].pack('H*')
    end

    def get_zip
        @zip = [@mcp_data[ZIP_START_POSITION..(ZIP_START_POSITION + ZIP_SIZE-1)]].pack('H*')
    end

    def get_zip_suffix
        @zip_suffix = [@mcp_data[ZIP_SUFFIX_START_POSITION..(ZIP_SUFFIX_START_POSITION + ZIP_SUFFIX_SIZE-1)]].pack('H*')
    end

    def get_message_type
        @message_type = @mcp_data[MESSAGE_TYPE_START_POSITION..(MESSAGE_TYPE_START_POSITION + MESSAGE_TYPE_SIZE-1)]
    end

    def get_command_type
        @command_type = @mcp_data[COMMAND_TYPE_START_POSITION..(COMMAND_TYPE_START_POSITION + COMMAND_TYPE_SIZE-1)]
    end

    def get_station_id
        @station_id = @mcp_data[STATION_ID_POSITION..(STATION_ID_POSITION + STATION_ID_SIZE-1)]
    end

    def initialize(mcp_data)
        @mcp_data = mcp_data
        
        get_protocol
        get_railroad
        get_zip
        get_zip_suffix
        get_message_type
        get_command_type
        get_station_id

        parse_mcp
    end

    def parse_mcp
        if @mcp_data.empty?
            # Sadly, our mcp_data is bogus, goodbye.
            puts "ERROR: mcp_data is invalid."
            return
        end
        
        puts "Protocol is #{@protocol}"
        puts "Railroad is #{@railroad}"
        puts "Zip is #{@zip}"
        puts "Zip Suffix is #{@zip_suffix}"
        puts "Message type is #{@message_type}"
        puts "Command type is #{@command_type}"
        puts "Station ID is #{@station_id}"
         
    end

    def test_init
        decoded_mcp = [@mcp_data].pack('H*')
        data = "FC050006"
        decoded_data = [data].pack('H*')
        
        puts "CRC-16 of #{data} is " + Digest::CRC16.hexdigest(decoded_data)

        #LAYOUT:
        #Comand Byte        $FC
        #Station Number     $01-$FF
        #Control Byte No    $00-$FF
        #Control Byte       $00-$FF
        #(repeat as required)

        # CRC is a CRC-16 of the Command Byte, Station Number, and each control byte.  
        # It excludes the CRC-16 and terminator, as well as anything before the command
        # byte.
        
        #CRC (16) Low Byte       $00-$FF
        #CRC (16) High Byte      $00-$FF
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
        #05 - Message Type - 5 - UP Outbound ACK / Poll (3) (Frame 5) (0000 0000 0000 0101)
        #FB - Command Byte - 251 - to Wayside Device (251)
        #02 - Station Number - 002
        #C2 - Control Byte Number - C2
        #F1 - Control Byte
        #F6 - Terminator
    

        #67383032383336383730 07 FC050006 A053F6
        #67 = g (protocol - g - genesis)
        #383032 = 802 (RR id - 802 - UPRR)
        #38 33 36 38 37 = 83687
        #30 - Zip Suffix - 0
        #07 - Message Type - 07 - UP Datagram (1) (Frame 7)  (0000 0000 0000 0111)
        #FC - Command Byte - 252 - to Wayside Device (252)
        #05 - Station Numer - 005
        #00 - Control Byte Number - 00
        #06 - Control Byte - 06 - 0110
        #A0 - CRC Low Byte
        #53 - CRC High Byte
        #F6 - Terminator

        #Frame=7 GFI=0 Group=0 SSeq=0 Rseq=0 Beacon=0 Vital=0 UsrData=2
        #From Dispatch: 2802836870000
        #Number=0.0.252 Genisys_Control_Message
        #Mnemonics=C13,C12
        #00 06   
        #0000 0000 0000 0110
        #               C14 C13 C12 C11 
        #0000 0000 0000  0   1   1   0

        #67383032383336383730 09 FC 0500030100 29AC F6
        #67 = g (protocol - g - genesis)
        #383032 = 802 (RR id - 802 - UPRR)
        #38 33 36 38 37 = 83687
        #30 - Zip Suffix - 0
        #09 - Message Type - 09 - UP Datagram (1) (Frame 9) (0000 0000 0000 1001)
        #FC - Command Byte - 252 - to Wayside Device (252)
        #05 - Station Numer - 005
        #00 - Control Byte Number - 00
        #03 - Control Byte - 03 - 0011
        #01 - Control Byte - 01 - 0001
        #00 - Control Byte - 00 - 0000
        #29 - CRC Low Byte
        #AC - CRC High Byte
        #F6 - Terminator

        #UP Datagram (1) to Wayside Device (252)
        #Frame=9 GFI=0 Group=0 SSeq=0 Rseq=0 Beacon=0 Vital=0 UsrData=4
        #From Dispatch: 2802836870000
        #Number=0.0.252 Genisys_Control_Message
        #Mnemonics=C12, C11
        #00 03 01 00  (the 01 00 is not part of the mnemonic)


        #67383032383336383730 07 FC 050043 61A0 F6
        #67 = g (protocol - g - genesis)
        #383032 = 802 (RR id - 802 - UPRR)
        #38 33 36 38 37 = 83687
        #30 - Zip Suffix - 0
        #07 - Message Type - 07 - UP Datagram (1) (Frame 7)  (0000 0000 0000 0111)
        #FC - Command Byte - 252 - to Wayside Device (252)
        #05 - Station Numer - 005
        #00 - Control Byte Number - 00
        #43 - Control Byte - 43 (0100 0011)
        #61 - CRC Low Byte
        #A0 - CRC High Byte
        #F6 - Terminator

        #UP Datagram (1) to Wayside Device (252)
        #Frame=7 GFI=0 Group=0 SSeq=0 Rseq=0 Beacon=0 Vital=0 UsrData=2
        #From Dispatch: 2802836870000
        #Number=0.0.252 Genisys_Control_Message
        #Mnemonics=C17,C12,C11
        #00 43



        # *** This is one that does not follow my current algorithm...grrr...

        #67383032383336383730 07 FC 070041 41A1 F6
        #67 = g (protocol - g - genesis)
        #383032 = 802 (RR id - 802 - UPRR)
        #38 33 36 38 37 = 83687
        #30 - Zip Suffix - 0
        #07 - Message Type - 07 - UP Datagram (1) (Frame 7)  (0000 0000 0000 0111)
        #FC - Command Byte - 252 - to Wayside Device (252)
        #07 - Station Numer - 007
        #00 - Control Byte Number - 00
        #41 - Control Byte - 41 (0100 0001) -- Hex to ASCII is 0x41 -> 0A; 0000 1010
        #41 - CRC Low Byte
        #A1 - CRC High Byte
        #F6 - Terminator

        #UP Datagram (1) to Wayside Device (252)
        #Frame=7 GFI=0 Group=0 SSeq=0 Rseq=0 Beacon=0 Vital=0 UsrData=2
        #From Dispatch: 2802836870000
        #Number=0.0.252 Genisys_Control_Message
        #Mnemonics=C17,C11,C24,C22
        #00 41  
    end
end

class MythDB
    require 'mysql2'

    def connect_database
        puts 'connecting to the database...'

        @client = Mysql2::Client.new(:host => "localhost", :username => "atcsmon",
            :password => "atcsmon")
    end

    def insert_record
        mcp_data = "6738303238333638373005FB030331F6"
        decoded_mcp = [mcp_data].pack('H*')

        puts "mcp_data: #{mcp_data}"
        puts "decoded_mcp: #{decoded_mcp}"

        puts 'Inserting a record into the database...'
        insert_sql = 'INSERT INTO atcsmon.atcsmon (id, timestamp,mnemonic) VALUES(DEFAULT, "2016/06/01 02:22:20", "' + decoded_mcp + '");'

        @client.query insert_sql
    end

    def query_database
        results = client.query("SELECT * FROM atcsmon.atcsmon WHERE id > 0")

        results.each do |row|
            # conveniently, row is a hash
            # the keys are the fields, as you'd expect
            # the values are pre-built ruby primitives mapped from their corresponding field types in MySQL
            output=row["id"] # row["id"].class == Fixnum
            if row["timestamp"]  # non-existant hash entry is nil
                output+=row["timestamp"]
            end
            if row["mnemonic"]  # non-existant hash entry is nil
                output+=row["mnemonic"]
            end

            puts output
        end
    end
end

###############################################################################
# 
# Main entry point for the app...
# 
###############################################################################
mcpData = MCPData.new("6738303238333638373005FB030331F6")
#mcpData.test_tnit

mythdb = MythDB.new
mythdb.connect_database
mythdb.insert_record
