#! /usr/bin/env ruby

# LetsCrate CLI by Freddy Roman

# ------

# Copyright (c) 2011 Freddy Roman
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#    
#     The above copyright notice and this permission notice shall be included in
#     all copies or substantial portions of the Software.
#     
#     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#     THE SOFTWARE.

# ------

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'typhoeus'
require 'json'

VERSION = "1.1"
APIVERSION = "1"

# here start the modules

module Colors      # this allows using colors with ANSI escape codes
    
    def colorize(text, color_code)
        "\e[#{color_code}m#{text}\e[0m"
    end
    
    def red(text); colorize(text, 31); end
    def green(text); colorize(text, 32); end
    def yellow(text); colorize(text, 33); end
    def blue(text); colorize(text, 34); end
    def magenta(text); colorize(text, 35); end
    def cyan(text); colorize(text, 36); end
    def white(text); colorize(text, 37); end
end

module Output
    
    def detect_terminal_size
        return `tput cols`.to_i    # returns terminal width in characters
    end
    
    def printError(message, argument)
        if !(@options.width.nil?)
            $stderr.puts red("Error:")+" #{message}%#{@options.width-(message.length+7)}s" % "<#{argument}>"
            else
            $stderr.puts red("Error:")+" #{message}\t<#{argument}>"
        end
    end
    
    def printInfo(name, short_code, id)
        name = truncateName(name, @options.width-35) if name.length > @options.width-35
        if !(@options.width.nil?)
            puts "#{name}%#{@options.width-(name.length)}s\n" % "URL: http://lts.cr/#{short_code}  ID: #{id}"   # this works by getting the remaining available characters and using %#s to align to the right.
            else
            puts "#{name}\t\tURL: http://lts.cr/#{short_code}\tID: #{id}"  # in case that the terminal width couldn't be obtained.
        end
    end
    
    def printFile(name, short_code, id)
        name = truncateName(name, @options.width-37) if name.length > @options.width-37
        if !(@options.width.nil?)
            puts "* #{name}%#{@options.width-(name.length+2)}s\n" % "URL: http://lts.cr/#{short_code}  ID: #{id}"
            else
            puts "* #{name}\t\tURL: http://lts.cr/#{short_code}\tID: #{id}"
        end
    end
    
    def truncateName(name, length)
        return name[0..((length/2)-2).to_i]+"..."+name[-(((length/2)-1).to_i)..-1]
    end
    
end

module IntegrityChecks
    
    def IDvalid?(id)
        if !(id[/^\d{5}$/].nil?)  # regex checks for 5 continuous digits surrounded by start and end of string.
            return true
        else
            return false
        end
    end
    
end

module Strings   # this module contains almost all the strings used in the program
    
    STR_BANNER = "Usage: #{File.basename(__FILE__)} <-l username:password> [options] file1 file2 ...\n"+ 
    "   or: #{File.basename(__FILE__)} <-l username:password> [options] id1 id2 ...\n"+"\n"
    
    STR_VERSION = "LetsCrate v#{VERSION} (API Version #{APIVERSION}) by Freddy Roman <frcepeda@gmail.com>"
    
    STR_TOO_MANY_ACTIONS = "More than one action was selected. Please select only one action."
    
    STR_FILEID_ERROR = "A file ID is a 5 digit number. Use -a to list your files's IDs."
    STR_CRATEID_ERROR = "A crate ID is a 5 digit number. Use -A to list your crates's IDs."
    
    STR_RTFM = "Use the -h flag for help, or read the README."
    
    STR_ACCOUNT_NEEDED = "You need to an account to use the LetsCrate API."
    STR_LOGIN_WITH_L_SWITCH = "Use the \"-l\" switch to specify your login credentials"
    STR_CREDENTIALS_ERROR = "Credentials invalid, please input them in the format \"username:password\""
    
    STR_VALID_CREDENTIALS = "The credentials are valid"
    STR_INVALID_CREDENTIALS = "The credentials are invalid"
    
    STR_EMPTY_CRATE = "* Crate is empty."
    
end

module Everything    # I got tired of manually adding all modules.
    include Colors
    include Output
    include IntegrityChecks
    include Strings
end

#  here end the modules

class App
    
    include Everything
    
    def initialize(argList)
        @arguments = argList      # store arguments in local variable
        processArguments
    end
    
    def processArguments
        
        @options = OpenStruct.new    # all the arguments will be parsed into this openstruct
        @options.actionCounter = 0     # this should always end up as 1, or else there's a problem with the script arguments.
        @options.action = nil    # this will be performed by the LetsCrate class
        @options.verbose = true    # if false, nothing will be printed to the screen.
        @options.width = detect_terminal_size   # determine terminal's width
        
        opts = OptionParser.new
        
        opts.banner = STR_BANNER
        
        opts.on( '-l', '--login [username:password]', 'Login with this username and password' ) { |login|
            
            credentials = login.split(/:/)   # makes a 2-item array from the input
            
            if credentials.count == 2   # this array musn't have more than 2 items because it's username + password.
                @options.username = credentials[0]
                @options.password = credentials[1]
                @options.login = 1
            else
                printError(STR_CREDENTIALS_ERROR, login.to_s)
                exit 1
            end
        }
        
        opts.on( '-u', '--upload [Crate ID]', 'Upload files to crate with ID' ) { |upID|
            if IDvalid?(upID)
                @options.crateID = upID
                @options.action = :uploadFile
                @options.actionCounter += 1
            else
                printError(STR_CRATEID_ERROR, upID)
                exit 1
            end
        }
        
        opts.on( '-d', '--delete', 'Delete files with IDs' ) {
            @options.action = :deleteFile
            @options.actionCounter += 1
        }
        
        opts.on( '-a', '--list', 'List all files by crate' ) {
            @options.action = :listFiles
            @options.actionCounter += 1
        }
        
        opts.on( '-i', '--id', 'Show files with IDs' ) {
            @options.action = :listFileID
            @options.actionCounter += 1
        }
        
        opts.on( '-n', '--new', 'Create new crates with names' ) {
            @options.action = :createCrate
            @options.actionCounter += 1
        }
        
        opts.on( '-A', '--listcrates', 'List all crates' ) {
            @options.action = :listCrates
            @options.actionCounter += 1
        }
        
        opts.on( '-r', '--rename [Crate ID]', 'Rename crate to name' ) { |crateID|
            @options.crateID = crateID
            @options.action = :renameCrate
            @options.actionCounter += 1
        }
        
        opts.on( '-D', '--deletecrate', 'Delete crates with IDs' ) {
            @options.action = :deleteCrate
            @options.actionCounter += 1
        }
        
        opts.on( '-t', '--test', 'Only test the credentials' ) {
            @options.action = :testCredentials
            @options.actionCounter += 1
        }
        
        opts.on( '-q', '--quiet', 'Do not output anything to the terminal' ) {
            @options.verbose = false
        }
        
        opts.on( '-v', '--version', 'Output version' ) {
            puts STR_VERSION
            exit 0
        }
        
        opts.on( '-h', '--help', 'Display this screen' ) {
            puts opts   # displays help screen
            exit 0
        }
        
        opts.parse!(@arguments)
        
        # Errors:
        
        if @options.actionCounter > 1
            printError(STR_TOO_MANY_ACTIONS, "#{@options.actionCounter}")
            $stderr.puts STR_RTFM
            exit 1
        end
        
        if (@options.username == nil || @options.password == nil) && @options.actionCounter != 0
            printError(STR_ACCOUNT_NEEDED, "NoLoginError")
            $stderr.puts STR_LOGIN_WITH_L_SWITCH
            exit 1
        end
        
        if @options.actionCounter == 0      # nothing was selected
            puts opts
            exit 0
        end
    end
    
    def run
        
        crate = LetsCrate.new(@options, @arguments)
        crate.run
        
    end
    
end

class LetsCrate
    
    include Everything
    
    def initialize(options, arguments)
        @options = options
        @arguments = arguments
        @argCounter = -1    # argument index is raised first thing on every method, and it needs to be 0 the first time it's used.
        @BaseURL = https://api.letscrate.com/1/
    end
    
    def run
        if @arguments.count > 0     # check if command requires extra arguments
            for argument in @arguments
                response = self.send(@options.action, argument)    # response is aleady a parsed hash.
                self.send("PRINT"+@options.action.to_s, response) if @options.verbose
            end
        else
            response = self.send(@options.action)    # response is aleady a parsed hash.
            self.send("PRINT"+@options.action.to_s, response) if @options.verbose
        end
    end
    
    # -----   API documentation is at http://letscrate.com/api
    
    def testCredentials
        response = Typhoeus::Request.post("#{BaseURL}users/authenticate.json",
                                          :username => @options.username,
                                          :password => @options.password,
                                          )
        
        return parseResponse(response)
    end
    
    def uploadFile(file)
        if IDvalid?(@options.crateID)
            response = Typhoeus::Request.post("#{BaseURL}files/upload.json",
                                          :params => {
                                            :file => File.open(file ,"r"),
                                            :crate_id => @options.crateID
                                          },
                                          :username => @options.username,
                                          :password => @options.password,
                                          )
        
            return parseResponse(response)
        else
            printError(STR_CRATEID_ERROR, @options.crateID)
            exit 1
        end
    end
    
    def deleteFile(fileID)
        if IDvalid?(fileID)
            response = Typhoeus::Request.post("#{BaseURL}files/destroy/#{fileID}.json",
                                                :username => @options.username,
                                                :password => @options.password,
                                                )
            
            return parseResponse(response)
        else
            printError(STR_FILEID_ERROR, fileID)
        end
    end
    
    def listFiles
        response = Typhoeus::Request.post("#{BaseURL}files/list.json",
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
        
        return parseResponse(response)
    end
    
    def listFileID(fileID)
        if IDvalid?(fileID)
            response = Typhoeus::Request.post("#{BaseURL}files/show/#{fileID}.json",
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
        
            return parseResponse(response)
        else
            printError(STR_FILEID_ERROR, fileID)
        end
            
    end
    
    def createCrate(name)
        response = Typhoeus::Request.post("#{BaseURL}crates/add.json",
                                                 :params => {
                                                 :name => name
                                                 },
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
       
        return parseResponse(response)
    end
    
    def listCrates
        response = Typhoeus::Request.post("#{BaseURL}crates/list.json",
                                             :username => @options.username,
                                             :password => @options.password,
                                             )
        
        return parseResponse(response)
    end
    
    def renameCrate(name)
        if IDvalid?(@options.crateID)
            response = Typhoeus::Request.post("#{BaseURL}crates/rename/#{@options.crateID}.json", # the crateID isn't an argument, the name is.
                                                 :params => {
                                                 :name => name
                                                 },
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
        
            return parseResponse(response)
        else
            printError(STR_CRATEID_ERROR, @options.crateID)
            exit 1
        end
    end
    
    def deleteCrate(crateID)
        if IDvalid?(crateID)
            response = Typhoeus::Request.post("#{BaseURL}crates/destroy/#{crateID}.json",
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
      
            return parseResponse(response)
        else
            printError(STR_CRATEID_ERROR, crateID)
        end
    end
    
    # ------
    
    def parseResponse(response)
        return JSON.parse(response.body)
    end
    
    # ------
    
    def PRINTtestCredentials(hash)
        return 0 if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("success")
            puts STR_VALID_CREDENTIALS
            else
            printError(STR_INVALID_CREDENTIALS, "User:#{@options.username} Pass:#{@options.password}")
        end
    end
    
    def PRINTuploadFile(hash)
        @argCounter += 1
        return 0 if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            printInfo(File.basename(@arguments[@argCounter]), hash['file']['short_code'], hash['file']['id'])
        end
    end
    
    def PRINTdeleteFile(hash)
        @argCounter += 1
        return 0 if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            puts "#{@arguments[@argCounter]} deleted"
        end
    end
    
    def PRINTlistFiles(hash)
        @argCounter += 1
        return 0 if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
                printError(hash['message'], @arguments[@argCounter])
        else
            crates = hash['crates']
            for crate in crates
                printInfo(crate['name'], crate['short_code'], crate['id'])
                if crate['files']      # test if crate is empty
                    for file in crate['files']
                        printFile(file['name'], file['short_code'], file['id'])
                    end
                else
                    puts STR_EMPTY_CRATE
                end
                puts "\n"
            end
        end
    end
    
    def PRINTlistFileID(hash)
        @argCounter += 1
        return 0 if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            printInfo(hash['item']['name'], hash['item']['short_code'], hash['item']['id'])
        end
    end
    
    def PRINTcreateCrate(hash)
        @argCounter += 1
        return 0 if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            printInfo(hash['crate']['name'], hash['crate']['short_code'], hash['crate']['id'])
        end
    end
    
    def PRINTlistCrates(hash)
        @argCounter += 1
        return 0 if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            crates = hash['crates']
            for crate in crates
                printInfo(crate['name'], crate['short_code'], crate['id'])
            end
        end
    end
    
    def PRINTrenameCrate(hash)
        @argCounter += 1
        return 0 if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            puts "renamed "+hash['crate']['id']+" to "+hash['crate']['name']
        end
    end
    
    def PRINTdeleteCrate(hash)
        @argCounter += 1
        return 0 if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            puts "#{@arguments[@argCounter]} deleted"
        end
    end
end

# Create and run the application
app = App.new(ARGV)
app.run
exit 0