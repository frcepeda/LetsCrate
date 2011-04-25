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

VERSION = "1.0.2"

class App
    
    def initialize(argList)
        @arguments = argList      # store arguments in local variable
        processArguments
    end
    
    def processArguments
        
        @options = OpenStruct.new    # all the arguments will be parsed into this openstruct
        @options.actionCounter = 0     # this should always end up as 1, or else there's a problem with the script arguments.
        @options.action = nil    # this will be performed by the LetsCrate class
        @options.verbose = true    # if false, nothing will be printed to the screen.
        
        opts = OptionParser.new
        
        opts.banner = "Usage: #{File.basename(__FILE__)} <-l username:password> [options] file1 file2 ...\n"+ 
                      "   or: #{File.basename(__FILE__)} <-l username:password> [options] id1 id2 ...\n"+"\n"
        
        opts.on( '-l', '--login [username:password]', 'Login with this username and password' ) { |login|
            
            credentials = login.split(/:/)   # makes a 2-item array from the input
            
            if credentials.count == 2   # this array musn't have more than 2 items because it's username + password.
                @options.username = credentials[0]
                @options.password = credentials[1]
                @options.login = 1
            else
                puts "Credentials invalid, please input them in the format \"username:password\""
                exit 1
            end
        }
        
        opts.on( '-u', '--upload [Crate ID]', 'Upload files to crate with ID' ) { |upID|
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
            puts "LetsCrate v#{VERSION} by Freddy Roman <frcepeda@gmail.com>"
            exit 0
        }
        
        opts.on( '-h', '--help', 'Display this screen' ) {
            puts opts   # displays help screen
            exit 0
        }
        
        opts.parse!(@arguments)
        
        # Errors:
        
        if @options.actionCounter > 1
            puts "More than one action was selected. Please select only one action."
            puts opts   # displays help screen
            exit 1
        end
        
        if (@options.username == nil || @options.password == nil) && @options.actionCounter != 0
            puts "You need to supply a set of credentials to use the LetsCrate API."
            puts opts   # displays help screen
            exit 1
        end
        
        if @options.actionCounter == 0      # nothing was selected
            puts opts   # displays help screen
            exit 0
        end
    end
    
    def run
        
        crate = LetsCrate.new(@options, @arguments)
        crate.run
        
    end
    
end

class LetsCrate
    
    # this allows using colors with ANSI escape codes
    
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
    
    # here ends the color codes
    
    def initialize(options, arguments)
        @options = options
        @arguments = arguments
        @argCounter = 0
    end
    
    def run
        @width = self.detect_terminal_size  # get terminal width
        
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
        response = Typhoeus::Request.post("https://api.letscrate.com/1/users/authenticate.json",
                                          :username => @options.username,
                                          :password => @options.password,
                                          )
        
        return parseResponse(response)
    end
    
    def uploadFile(file)
        response = Typhoeus::Request.post("https://api.letscrate.com/1/files/upload.json",
                                          :params => {
                                            :file => File.open(file ,"r"),
                                            :crate_id => @options.crateID
                                          },
                                          :username => @options.username,
                                          :password => @options.password,
                                          )
        
        return parseResponse(response)
    end
    
    def deleteFile(fileID)
        response = Typhoeus::Request.post("https://api.letscrate.com/1/files/destroy/#{fileID}.json",
                                                :username => @options.username,
                                                :password => @options.password,
                                                )
            
        return parseResponse(response)
    end
    
    def listFiles
        response = Typhoeus::Request.post("https://api.letscrate.com/1/files/list.json",
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
        
        return parseResponse(response)
    end
    
    def listFileID(fileID)
        response = Typhoeus::Request.post("https://api.letscrate.com/1/files/show/#{fileID}.json",
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
        
        return parseResponse(response)
    end
    
    def createCrate(name)
        response = Typhoeus::Request.post("https://api.letscrate.com/1/crates/add.json",
                                                 :params => {
                                                 :name => name
                                                 },
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
       
        return parseResponse(response)
    end
    
    def listCrates
        response = Typhoeus::Request.post("https://api.letscrate.com/1/crates/list.json",
                                             :username => @options.username,
                                             :password => @options.password,
                                             )
        
        return parseResponse(response)
    end
    
    def renameCrate(name)
        response = Typhoeus::Request.post("https://api.letscrate.com/1/crates/rename/#{@options.crateID}.json", # the crateID isn't an argument, the name is.
                                                 :params => {
                                                 :name => name
                                                 },
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
        
        return parseResponse(response)
    end
    
    def deleteCrate(crateID)
        response = Typhoeus::Request.post("https://api.letscrate.com/1/crates/destroy/#{crateID}.json",
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
      
        return parseResponse(response)
    end
    
    # ------
    
    def parseResponse(response)
        return JSON.parse(response.body)
    end
    
    # ------
    
    def PRINTtestCredentials(hash)
        if hash.values.include?("success")
            puts "The credentials are valid"
            else
            printError("The credentials are invalid", "User:#{@options.username} Pass:#{@options.password}")
        end
    end
    
    def PRINTuploadFile(hash)
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            printInfo(File.basename(@arguments[@argCounter]), hash['file']['short_code'], hash['file']['id'])
        end
        @argCounter += 1
    end
    
    def PRINTdeleteFile(hash)
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            puts "#{@arguments[@argCounter]} deleted"
        end
        @argCounter += 1
    end
    
    def PRINTlistFiles(hash)
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
                    puts "* Crate is empty."
                end
                puts "\n"
            end
        end
        @argCounter += 1
    end
    
    def PRINTlistFileID(hash)
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            printInfo(hash['item']['name'], hash['item']['short_code'], hash['item']['id'])
        end
        @argCounter += 1
    end
    
    def PRINTcreateCrate(hash)
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            printInfo(hash['crate']['name'], hash['crate']['short_code'], hash['crate']['id'])
        end
        @argCounter += 1
    end
    
    def PRINTlistCrates(hash)
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            crates = hash['crates']
            for crate in crates
                printInfo(crate['name'], crate['short_code'], crate['id'])
            end
        end
        @argCounter += 1
    end
    
    def PRINTrenameCrate(hash)
       if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            puts "renamed "+hash['crate']['id']+" to "+hash['crate']['name']
        end
        @argCounter += 1
    end
    
    def PRINTdeleteCrate(hash)
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            puts "#{@arguments[@argCounter]} deleted"
        end
        @argCounter += 1
    end
    
    # ------
    
    def printInfo(name, short_code, id)
        if !(@width.nil?)
            puts "#{name}%#{@width-(name.length)}s\n" % "URL: http://lts.cr/#{short_code}  ID: #{id}"   # this works by getting the remaining available characters and using %#s to align to the right.
        else
            puts "#{name}\t\tURL: http://lts.cr/#{short_code}\tID: #{id}"  # in case that the terminal width couldn't be obtained.
        end
    end
    
    def printFile(name, short_code, id)
        if !(@width.nil?)
            puts "* #{name}%#{@width-(name.length+2)}s\n" % "URL: http://lts.cr/#{short_code}  ID: #{id}"
            else
            puts "* #{name}\t\tURL: http://lts.cr/#{short_code}\tID: #{id}"
        end
    end
    
    def printError(message, argument)
        if !(@width.nil?)
            puts "Error: #{message}%#{@width-(message.length+7)}s" % "<#{argument}>"
        else
            puts "Error: #{message}\t<#{argument}>"
        end
    end
    
    # ------
    
    def detect_terminal_size
        return `tput cols`.to_i    # returns terminal width in characters
    end
end

# Create and run the application
app = App.new(ARGV)
app.run
exit 0