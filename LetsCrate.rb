#! /usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'typhoeus'
require 'json'

VERSION = "0.1b"

class App
    
    attr_reader :options
    
    def initialize(argList)
        @arguments = argList      # store arguments in local variable
        processArguments
    end
    
    def processArguments
        
        @options = OpenStruct.new    # all the arguments will be parsed into this openstruct
        @options.actionCounter = 0     # this should always end up as 1, or else there's a problem with the script arguments.
        @options.action = nil    # this will be passed as an argument to the LetsCrate class
        
        opts = OptionParser.new
        
        opts.banner = "\nUsage: #{File.basename(__FILE__)} <-l username:password> <-u CrateID> file1 file2 ..."+"\n"+
                        "   or: #{File.basename(__FILE__)} <-l username:password> -d fileID1 fileID2 ..."+"\n\n"
        
        opts.on( '-l [username:password]', '--login [username:password]', 'Login with this username and password' ) { |login|
            
            if login
            credentials = login.split(/:/)   # makes a 2-item array from the input
            else
            puts "You need to supply a set of credentials to use the LetsCrate API"
            exit 1
            end
            
            if credentials.count == 2   # this array musn't have more than 2 items.
            @options.username = credentials[0]
            @options.password = credentials[1]
            else
            puts "Credentials invalid, please input them in the format \"username:password\""
            exit 1
            end
        }
        
        opts.on( '-u [ID]', '--upload [ID]', 'Upload files to crate with ID' ) { |upID|
            if upID      # TO DO - add verification via regex
            @options.crateID = upID
            @options.action = :uploadFile
            @options.actionCounter += 1
            else
            puts "A crate ID is a 5 digit number"
            exit 1
            end
        }
        
        opts.on( '-d', '--delete', 'Delete files with IDs' ) {
            @options.action = :deleteFile
            @options.actionCounter += 1
        }
        
        opts.on( '--version', 'Output version' ) {
            puts "LetsCrate v#{VERSION} by Freddy Roman <frcepeda@gmail.com>"
            exit 0
        }
        
        opts.on( '-h', '--help', 'Display this screen' ) {
            puts opts
            exit 0
        }
        
        opts.parse!(@arguments)
    end
    
    def run
        if @options.actionCounter != 1
        puts "More than one action was selected."
        exit 1
        end
            
        crate = LetsCrate.new(@options, @arguments)
        crate.run
        
    end
    
end

class LetsCrate
    
    def initialize(options, arguments)
        @options = options
        @arguments = arguments
        @responses = []
        @resHashed = []
    end
    
    def run
        if testCredentials
            self.send(@options.action)
        else
            puts "Invalid credentials. Please verify your username and password."
        end
    end
    
    def testCredentials
        true
        # TO DO - Actually implement this.
    end
    
    def uploadFile
        for file in @arguments
            @responses << Typhoeus::Request.post("https://api.letscrate.com/1/files/upload.json",
                                          :params => {
                                            :file => File.open(file ,"r"),
                                            :crate_id => @options.crateID
                                          },
                                          :username => @options.username,
                                          :password => @options.password,
                                          )
        end
        parseResponses
        processFilesUploaded
    end
    
    def deleteFile
        for fileID in @arguments
            @responses << Typhoeus::Request.post("https://api.letscrate.com/1/files/destroy/#{fileID}.json",
                                                :username => @options.username,
                                                :password => @options.password,
                                                )
        end
        parseResponses
        processFilesDeleted
    end
    
    def parseResponses
        for response in @responses
        @resHashed << JSON.parse(response.body)
        end
    end
    
    def processFilesUploaded
        i = 0
        for hash in @resHashed
            puts "Error: #{hash['message']} <#{@arguments[i]}>" if hash.values.include?("failure")
            puts "URL: #{hash['file']['short_url']}, ID: #{hash['file']['id']}      <#{@arguments[i]}>" if hash.values.include?("success")
            i += 1
        end
    end
    
    def processFilesDeleted
        i = 0
        for hash in @resHashed
            puts "Error: #{hash['message']} <#{@arguments[i]}>" if hash.values.include?("failure")
            puts "#{@arguments[i]} deleted" if hash.values.include?("success")
            i += 1
        end
    end
end


# Create and run the application
app = App.new(ARGV)
app.run
exit 0