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
require 'digest/sha1'
require 'date'

VERSION = "v1.9.5.1"
APIVERSION = "1"
BaseURL = "https://api.letscrate.com/1/"

$debug = false

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
        if argument == nil
            $stderr.puts red("Error: ")+message
            return
        end
        
        unless $width.nil?
            $stderr.puts red("Error: ")+"#{message}%#{$width-(message.length+7)}s" % "<#{argument}>"
            else
            $stderr.puts red("Error: ")+"#{message}\t<#{argument}>"
        end
    end
    
    def printWarning(message)
        $stderr.puts yellow("Warning: ")+message
    end
    
    def printCrate(name, short_code, id)
        data = @options.printIDs ? "  URL: http://lts.cr/#{short_code}  ID: #{id}" : "  URL: http://lts.cr/#{short_code}"
        name = truncateName(name, $width-data.length) if name.length > ($width-data.length)
        if !($width.nil?)            
            echo "#{name}%#{$width-(name.length)}s\n" % data  # this works by getting the remaining available characters and using %-#s to align to the right.
            else
            echo "* #{name}\t\t#{data}"
        end
    end
    
    def printFile(name, size, short_code, id)
        data = @options.printIDs ? "  #{ByteCount(size, true)}  URL: http://lts.cr/#{short_code}  ID: #{id}" : "  #{ByteCount(size, true)}  URL: http://lts.cr/#{short_code}"
        name = truncateName(name, ($width-data.length)-2) if name.length > ($width-data.length)-2
        if !($width.nil?)            
            echo "* #{name}%#{$width-(name.length+2)}s\n" % data  # this works by getting the remaining available characters and using %-#s to align to the right.
            else
            echo "* #{name}\t\t#{data}"
        end
    end
    
    def truncateName(name, length)
        if length.even?
            return name[0..((length.to_f/2)-2).truncate]+"..."+name[-(((length.to_f/2)-2).truncate)..-1]
        else
            return name[0..((length.to_f/2)-1).truncate]+"..."+name[-(((length.to_f/2)-2).truncate)..-1]
        end
    end
    
    def echo(argument)    #  this behaves exactly like puts, unless quiet is on. Use for all output messages.
        puts argument unless @options.quiet
    end
    
    def info(argument)
        echo blue("Info: ")+argument if @options.verbose
    end
    
end

module Strings   # this module contains almost all the strings used in the program
    
    STR_BANNER = "Usage: #{File.basename(__FILE__)} <-l username:password> [options] file1 file2 ...\n"+ 
    "   or: #{File.basename(__FILE__)} <-l username:password> [options] name1 name2 ..."
    
    STR_VERSION = "LetsCrate v#{VERSION} (API Version #{APIVERSION}) by Freddy Roman <frcepeda@gmail.com>"
    
    STR_TOO_MANY_ACTIONS = "More than one action was selected. Please select only one action."
    
    STR_FILEID_ERROR = "A file ID is a 5 digit number. Use -a to list your files's IDs."
    STR_CRATEID_ERROR = "A crate ID is a 5 digit number. Use -A to list your crates's IDs."
    
    STR_COULDNT_GET_FILES = "Couldn't download file list. Exiting."
    
    STR_RTFM = "Use the -h flag for help, or read the README."
    
    STR_ACCOUNT_NEEDED = "You need to an account to use the LetsCrate API."
    STR_LOGIN_WITH_L_SWITCH = "Use the \"-l\" switch to specify your login credentials"
    STR_CREDENTIALS_ERROR = "Credentials invalid, please input them in the format \"username:password\""
    
    STR_VALID_CREDENTIALS = "The credentials are valid"
    STR_INVALID_CREDENTIALS = "The credentials are invalid"
    
    STR_EMPTY_CRATE = "* Crate is empty."
    
    STR_NO_FILES_FOUND = "No files were found that match that name."
    STR_NO_CRATES_FOUND = "No crates were found that match that name."
    
    STR_TOO_MANY_CRATES = "More than 1 crate matched that name. Please make your query more specific, or use --regexp if you meant this to happen."
    STR_TOO_MANY_FILES = "More than 1 file matched that name. Please make your query more specific, or use --regexp if you meant this to happen."
    
    STR_PASSWORD_PROTECTED = "Is the crate password protected? The API doesn't allow downloading files with passwords. Email hi@letscrate.com to ask for that feature."
    
    STR_DELETED = "%s deleted"
    STR_RENAMED = "Renamed %s to %s"
    
    STR_UPDATED = "\e[#{32}mSUCCESS! LetsCrate has been updated to the latest version!\e[0m" # this makes the text green.
    STR_REENTER_UPDATED = "Please re-enter your latest command to start using the new version."
    STR_NEW_VERSION = "There is a new version available."
    STR_NEW_VERSION_PROMPT = "Would you like to download it now? (y/n) "
    STR_COULDNT_CHECK_VERSION = "Couldn't check for new versions."
    STR_COULDNT_DOWNLOAD_NEW_VERSION = "Couldn't download new version."
    
    STR_TIMEOUT = "The request timed out."
    STR_HTTPERROR = "Connection error. Code: %s"
end

module IntegrityChecks
    
    include Strings
    
    def IDvalid?(id)
        info "Testing ID: #{id}"
        test = id.to_s
        if test[/^\d{5}$/].nil?  # regex checks for 5 continuous digits surrounded by start and end of string.
            info "#{id} isn't a valid ID."
            return false
        else
            info "#{id} is a valid ID."
            return true
        end
    end
    
    def IDsvalid?(ids)
        info "Testing IDs: #{ids}."
        results = []
        
        for id in ids
            results << IDvalid?(id)
        end
        
        unless results.include?(false)
            info "All IDs are valid."
            return true
        else
            info "At least one ID isn't valid."
            return false
        end
    end
    
    def requestSuccess?(response) # This checks if the request was successful or prints error messages if it went wrong.
        if response.success?
            return true
        elsif response.timed_out?
            printError(STR_TIMEOUT, "TimeOut")
        elsif response.code == 0
            # Could not get an http response, something's wrong.
            printError(response.curl_error_message, "HTTPError")
        else
            # Received a non-successful http response.
            printError(STR_HTTPERROR % response.code.to_s, "HTTPError")
        end
        return false
    end
    
end

module Conversions
    def ByteCount(bytes, si)
        #return nil if bytes.nil?
        #bytes = bytes.to_int
        #unit = si ? 1000 : 1024
        #return bytes.to_s+" B" if (bytes < unit)
        #exp = (Math.log(bytes) / Math.log(unit)).to_int
        #pre = (si ? ["k", "M", "G", "T", "P", "E"] : ["K", "M", "G", "T", "P", "E"]).slice(exp-1)+(si ? "" : "i")
        #return "%.1f %sB" % [bytes.to_f / (unit ** exp), pre]   # this is the original code, but I always use base 10.
        
        return nil if bytes.nil?
        bytes = bytes.to_int
        unit = 1000
        return bytes.to_s+" B" if (bytes < unit)
        exp = (Math.log(bytes) / Math.log(unit)).to_int
        pre = ["k", "M", "G", "T", "P", "E"].slice(exp-1)
        return "%.1f %sB" % [bytes.to_f / (unit ** exp), pre]
    end
end

module Everything    # I got tired of manually adding all modules.
    include Colors
    include Output
    include IntegrityChecks
    include Strings
    include Conversions
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
        @options.verbose = false
        @options.quiet = false    # if true, nothing will be printed to the screen. (aside from errors)
        $width = detect_terminal_size   # determine terminal's width
        @options.usesFilesIDs = false    # this triggers ID checks on the arguments if set to true
        @options.usesCratesIDs = false   # same as above but with crates
        @options.regex = false    # if set to true, all names are treated as regular expressions
        @options.printIDs = false  # if true, all output will have IDs instead of names.
        
        opts = OptionParser.new
        
        opts.banner = STR_BANNER
        
        opts.separator ""
        opts.separator "Mandatory arguments:"
        
        opts.on( '-l', '--login [username:password]', 'Login with this username and password' ) { |login|
            
            credentials = login.split(/:/)   # makes a 2-item array from the input
            
            if credentials.count == 2   # this array musn't have more than 2 items because it's username + password.
                @options.username = credentials[0]
                @options.password = credentials[1]
                @options.login = 1
                info "Logging in with username: #{credentials[0]}and password:#{credentials[1]}."
            else
                printError(STR_CREDENTIALS_ERROR, login.to_s)
                exit 1
            end
        }
        
        opts.separator ""
        opts.separator "File functions:"
        
        opts.on( '-u', '--upload [Crate name]', 'Upload files to crate' ) { |upID|
            @options.crateID = upID
            @options.action = :uploadFile
            @options.actionCounter += 1
        }
        
        opts.on( '-r', '--delete', 'Delete files with names *' ) {
            @options.action = :deleteFile
            @options.usesFilesIDs = true
            @options.actionCounter += 1
        }
        
        opts.on( '-a', '--list', 'List all files' ) {
            @options.action = :listFiles
            @options.actionCounter += 1
        }
        
        opts.on( '-d', '--download', 'Download files with names *' ) {
            @options.action = :downloadFiles
            @options.usesFilesIDs = true
            @options.actionCounter += 1
        }
        
        opts.on( '-s', '--search', 'Search for files with names' ) {
            @options.action = :searchFile
            @options.actionCounter += 1
        }
        
        opts.on( '-i', '--id', 'Show files with IDs' ) {
            @options.action = :listFileID
            #this should have a @options.usesFilesIDs = true, but the command is meaningless without an ID
            @options.actionCounter += 1
        }
        
        opts.separator ""
        opts.separator "Crate functions:"
        
        opts.on( '-N', '--newcrate', 'Create new crates with names' ) {
            @options.action = :createCrate
            @options.actionCounter += 1
        }
        
        opts.on( '-A', '--listcrates', 'List all crates (or files in crates, if names are passed)' ) {
            @options.action = :listCrates
            @options.actionCounter += 1
        }
        
        opts.on( '-D', '--downloadcrates', 'Download crates with names *' ) {
            @options.action = :downloadCrates
            @options.usesCratesIDs = true
            @options.actionCounter += 1
        }
        
        opts.on( '-S', '--searchcrates', 'Search for crates with names' ) {
            @options.action = :searchCrate
            @options.actionCounter += 1
        }
        
        opts.on(       '--renamecrate [Crate name]', 'Rename crate to name' ) { |crateID|
            @options.crateID = crateID
            @options.action = :renameCrate
            @options.actionCounter += 1
        }
        
        opts.on( '-R', '--deletecrate', 'Delete crates with names *' ) {
            @options.action = :deleteCrate
            @options.usesCratesIDs = true
            @options.actionCounter += 1
        }
        
        opts.separator ""
        opts.separator "Misc. options:"
        
        opts.on(       '--downloadall', 'Downloads everything in your Let\'s Crate account.' ) {
            @options.action = :downloadAll
            @options.actionCounter += 1
        }
        
        opts.on(       '--regexp', 'Treat names as regular expressions' ) {
            @options.regex = true
        }
        
        opts.on( '-t', '--test', 'Only test the credentials' ) {
            @options.action = :testCredentials
            @options.actionCounter += 1
        }
        
        opts.on(       '--ids', 'Print IDs when listing files/crates.' ) {
            @options.printIDs = true
        }
        
        opts.on( '-v', '--verbose', 'Output extra info to the terminal' ) {
            @options.verbose = true
            info "Verbose mode on."
        }
        
        opts.on( '-q', '--quiet', 'Do not output anything to the terminal' ) {
            @options.quiet = true
        }
        
        opts.on(       '--version', 'Output version' ) {
            puts STR_VERSION
            exit 0
        }
        
        opts.on( '-h', '--help', 'Display this screen' ) {
            puts opts   # displays help screen
            exit 0
        }
        
        opts.on(       '--debug', 'Internal use only.' ) {
            info "Debug mode on."
            $debug = true
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
    
    def latestversion?
        info "Checking for new versions."
        response = Typhoeus::Request.get("https://github.com/frcepeda/LetsCrate/raw/master/.current")
        
        if requestSuccess?(response)
            data = response.body.split
            
            local = VERSION.split(".").join[1..-1].to_i
            current = data[0].to_s.split(".").join[1..-1].to_i
            
            while Math.log(local).floor + 1 < Math.log(current).floor + 1 # performs some padding so numbers have the same amount of digits
                local = local * 10
            end
            
            while Math.log(current).floor + 1 < Math.log(local).floor + 1
                current = current * 10
            end
            
            info "Server has version #{data[0][1..-1]}."
            
            if local < current
                info "New version detected. #{data[0]}"
                return false
            end
            
            if local > current
                printWarning "Using newer version than server."
            end
            
            return true
        else
            printWarning(STR_COULDNT_CHECK_VERSION)
        end
    end
    
    def autoUpdate
        puts STR_NEW_VERSION
        printf STR_NEW_VERSION_PROMPT
        answer = gets
        if answer.downcase == "y\n" # The \n is needed because there's a newline at the end.
            update!
        end
    end
    
    def update!
        response = Typhoeus::Request.get("https://github.com/frcepeda/LetsCrate/raw/master/letscrate.rb")
        if requestSuccess?(response)
            file = File.new("#{__FILE__}", "w+")
            file.write(response.body)
            file.close
            puts STR_UPDATED
            puts STR_REENTER_UPDATED
            exit 0
        else
            printError(STR_COULDNT_DOWNLOAD_NEW_VERSION, nil)
        end
    end
    
    def run
        
        unless latestversion?
            autoUpdate
        end
        
        crate = LetsCrate.new(@options, @arguments)
        crate.run
        
    end
    
end

##
## --- Ends definition of App class.
##

class LetsCrate
    
    include Everything
    
    def initialize(options, arguments)
        @options = options
        @arguments = arguments
        @argCounter = -1    # argument index is raised first thing on every method, and it needs to be 0 the first time it's used.
        @prevNames = []   # used when renaming or deleting stuff.
    end
    
    def run
        
        if !(@options.crateID.nil?)    #  Check if crateID is used in this process.
            if IDvalid?(@options.crateID)
                info "Crate ID valid."
                # YAY! Do nothing.
            else
                info "Crate ID invalid. Mapping name to crate."
                @options.crateID = getIDForCrate(@options.crateID)
            end
        end
        
        if @options.usesCratesIDs
            info "This command uses Crate IDs."
            @arguments = mapCrateIDs(@arguments)
        end
        
        if @options.usesFilesIDs
            info "This command uses File IDs."
            @arguments = mapFileIDs(@arguments) 
        end
        
        if @arguments.count > 0     # check if command requires extra arguments
            
            for argument in @arguments
                @argCounter += 1
                response = self.send(@options.action, argument)    # response is a parsed hash or an array of hashes.
                self.send("PRINT"+@options.action.to_s, response)
            end
        else
            response = self.send(@options.action)    # response is a parsed hash or an array of hashes.
            self.send("PRINT"+@options.action.to_s, response)
        end
    end
    
    # -----   API documentation is at http://letscrate.com/api
    
    def testCredentials
        info "Testing Credentials. Username: #{@options.username}, Password: #{@options.password}"
        response = Typhoeus::Request.get("#{BaseURL}users/authenticate.json",
                                          :username => @options.username,
                                          :password => @options.password,
                                          )
        
        if response.success? # This checks if the request was successful or prints error messages if it went wrong.
            info "Got response from server."
            return parseResponse(response) # return native Ruby hash instead of JSON.
        elsif response.timed_out?
            printError(STR_TIMEOUT, "TimeOut")
        elsif response.code == 0
            # Could not get an http response, something's wrong.
            printError(response.curl_error_message, "HTTPError")
        else
            # Received a non-successful http response.
            printError(STR_HTTPERROR % response.code.to_s, "HTTPError")
        end
    end
    
    def uploadFile(file)
        if IDvalid?(@options.crateID)
            info "Uploading file #{file}."
            response = Typhoeus::Request.post("#{BaseURL}files/upload.json",
                                          :params => {
                                            :file => File.open(file ,"r"),
                                            :crate_id => @options.crateID
                                          },
                                          :username => @options.username,
                                          :password => @options.password,
                                          )
        
            unless response.success?
                printError(STR_STD_HTTP_ERROR, response.code.to_s)
                return nil
            end
            
            if response.success? # This checks if the request was successful or prints error messages if it went wrong.
                info "Got response from server."
                return parseResponse(response) # return native Ruby hash instead of JSON.
            elsif response.timed_out?
                printError(STR_TIMEOUT, "TimeOut")
            elsif response.code == 0
                # Could not get an http response, something's wrong.
                printError(response.curl_error_message, "HTTPError")
            else
                # Received a non-successful http response.
                printError(STR_HTTPERROR % response.code.to_s, "HTTPError")
            end
            return nil
        else
            printError(STR_CRATEID_ERROR, @options.crateID)
            exit 1
        end
    end
    
    def deleteFile(fileID)
        if IDvalid?(fileID)
            info "Getting file #{fileID}'s name."
            @prevNames << getFileName(fileID)
            info "Deleting file #{fileID}."
            response = Typhoeus::Request.post("#{BaseURL}files/destroy/#{fileID}.json",
                                                :username => @options.username,
                                                :password => @options.password,
                                                )
            
            if response.success? # This checks if the request was successful or prints error messages if it went wrong.
                info "Got response from server."
                return parseResponse(response) # return native Ruby hash instead of JSON.
            elsif response.timed_out?
                printError(STR_TIMEOUT, "TimeOut")
            elsif response.code == 0
                # Could not get an http response, something's wrong.
                printError(response.curl_error_message, "HTTPError")
            else
                # Received a non-successful http response.
                printError(STR_HTTPERROR % response.code.to_s, "HTTPError")
            end
            return nil
        else
            printError(STR_FILEID_ERROR, fileID)
        end
    end
    
    def listFiles
        info "Downloading file list."
        response = Typhoeus::Request.get("#{BaseURL}files/list.json",
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
        
        if response.success? # This checks if the request was successful or prints error messages if it went wrong.
            info "Got response from server."
            return parseResponse(response) # return native Ruby hash instead of JSON.
        elsif response.timed_out?
            printError(STR_TIMEOUT, "TimeOut")
        elsif response.code == 0
            # Could not get an http response, something's wrong.
            printError(response.curl_error_message, "HTTPError")
        else
            # Received a non-successful http response.
            printError(STR_HTTPERROR % response.code.to_s, "HTTPError")
        end
        printError(STR_COULDNT_GET_FILES, nil)
        exit 1 # I can't do anything without the file list, so I'd better quit now.
    end
    
    def listFileID(fileID)
        if IDvalid?(fileID)
            info "Getting file #{fileID} info."
            response = Typhoeus::Request.get("#{BaseURL}files/show/#{fileID}.json",
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
            
            if response.success? # This checks if the request was successful or prints error messages if it went wrong.
                info "Got response from server."
                return parseResponse(response) # return native Ruby hash instead of JSON.
            elsif response.timed_out?
                printError(STR_TIMEOUT, "TimeOut")
            elsif response.code == 0
                # Could not get an http response, something's wrong.
                printError(response.curl_error_message, "HTTPError")
            else
                # Received a non-successful http response.
                printError(STR_HTTPERROR % response.code.to_s, "HTTPError")
            end
            return nil
        else
            printError(STR_FILEID_ERROR, fileID)
        end
            
    end
    
    def downloadFiles(fileID, *dir)
        if IDvalid?(fileID)
            info "Downloading file #{fileID}."
            longURL = getFileLongURL(fileID)
            name = getFileName(fileID)
            if File.exists?(dir.nil? ? "#{name}" : "#{dir[0]}#{name}") # was I passed the name of a directory to save the files in?
                printWarning("\"#{name}\" already exists. Skipping.") # whoops, the file already exists in the folder.
            else
                info "Downloading #{longURL}."
                file = File.new(dir.nil? ? "#{name}" : "#{dir[0]}#{name}", "w")
                response = Typhoeus::Request.get("#{longURL}")
                
                if response.success?
                    info "Successfuly downloaded file."
                    file.write(response.body)
                    return name # return the new file's name
                elsif response.timed_out?
                    printError("The request timed out.", "TimeOut")
                elsif response.code == 0
                    # Could not get an http response, something's wrong.
                    # Maybe the file is password protected?
                    printError(response.curl_error_message, "HTTPError")
                    $stderr.puts STR_PASSWORD_PROTECTED
                else
                    # Received a non-successful http response.
                    printError("HTTP Error code: "+response.code.to_s, "HTTPError")
                end
                file.close
                return nil
            end
            return nil
        else
            printError(STR_FILEID_ERROR, fileID)
        end
    end
    
    def searchFile(name)
        regex = Regexp.new(name, Regexp::IGNORECASE)   # make regex class with every argument
        matchedFiles = []
        @files = listFiles if @files.nil?   # do not query the server each time a search is made.
        info "Searching for files with name: #{name}."
        allCrates = @files['crates']
        for crate in allCrates
            if crate['files']      # test if crate is empty
                for file in crate['files']
                    matchedFiles << file if regex.match(file['name']) != nil
                end
            end
        end
        return matchedFiles
    end
    
    def searchCrate(name)
        regex = Regexp.new(name, Regexp::IGNORECASE)   # make regex class with every argument
        matchedCrates = []
        @files = listFiles if @files.nil?   # do not query the server each time a search is made.
        info "Searching for crates with name: #{name}."
        allCrates = @files['crates']
        for crate in allCrates
            matchedCrates << crate if regex.match(crate['name']) != nil
        end
        return matchedCrates
    end
    
    def createCrate(name)
        info "Creating crate with name: #{name}."
        response = Typhoeus::Request.post("#{BaseURL}crates/add.json",
                                                 :params => {
                                                 :name => name
                                                 },
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
       
        if response.success? # This checks if the request was successful or prints error messages if it went wrong.
            info "Got response from server."
            return parseResponse(response) # return native Ruby hash instead of JSON.
        elsif response.timed_out?
            printError(STR_TIMEOUT, "TimeOut")
        elsif response.code == 0
            # Could not get an http response, something's wrong.
            printError(response.curl_error_message, "HTTPError")
        else
            # Received a non-successful http response.
            printError(STR_HTTPERROR % response.code.to_s, "HTTPError")
        end
        return nil
    end
    
    def listCrates(*name)
        if name.count == 0  # was I passed a name?
            info "Downloading crate list."
            response = Typhoeus::Request.get("#{BaseURL}crates/list.json",
                                             :username => @options.username,
                                             :password => @options.password,
                                             )
            info "Listing all crates."
            
            if response.success? # This checks if the request was successful or prints error messages if it went wrong.
                info "Got response from server."
                return parseResponse(response) # return native Ruby hash instead of JSON.
            elsif response.timed_out?
                printError(STR_TIMEOUT, "TimeOut")
            elsif response.code == 0
                # Could not get an http response, something's wrong.
                printError(response.curl_error_message, "HTTPError")
            else
                # Received a non-successful http response.
                printError(STR_HTTPERROR % response.code.to_s, "HTTPError")
            end
            return nil
        else  # that means i have to parse it.
            if IDvalid?(name[0]) # I need to pass the name like that because Ruby groups all variable number arguments into an array.
                crate = getCrateWithID(name[0])
                crates = [crate] # The printing method expects an array.
            else
                info "Listing crates with name: #{name[0]}."
                crates = searchCrate(name[0])
            end
            return crates
        end
    end
    
    def downloadCrates(crateID)
        if IDvalid?(crateID)
            info "Downloading crate #{crateID}."
            files = getFilesInCrateID(crateID)
            crateName = getCrateName(crateID)
            unless files.nil?
                begin
                    Dir.mkdir(crateName)
                    echo "Created folder \"#{crateName}\""
                rescue SystemCallError => ex
                    printWarning("The folder \"#{crateName}\" already exists. Files will be downloaded there.")
                end
                for file in files
                    fileName = downloadFiles(file, crateName+"/")
                    PRINTdownloadFiles(fileName)
                end
            else
                printWarning("The crate \"#{crateName}\" is empty. Skipping.")
            end
            return nil   # this method always returns nil, because it prints everything on the fly.
        else
            printError(STR_FILEID_ERROR, fileID)
        end
    end
    
    def renameCrate(name)
        if IDvalid?(@options.crateID)
            info "Getting previous crate name."
            @prevNames << getCrateName(@options.crateID)
            info "Renaming crate #{@options.crateID} to #{name}."
            response = Typhoeus::Request.post("#{BaseURL}crates/rename/#{@options.crateID}.json", # the crateID isn't an argument, the name is.
                                                 :params => {
                                                 :name => name
                                                 },
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
        
            if response.success? # This checks if the request was successful or prints error messages if it went wrong.
                info "Got response from server."
                return parseResponse(response) # return native Ruby hash instead of JSON.
            elsif response.timed_out?
                printError(STR_TIMEOUT, "TimeOut")
            elsif response.code == 0
                # Could not get an http response, something's wrong.
                printError(response.curl_error_message, "HTTPError")
            else
                # Received a non-successful http response.
                printError(STR_HTTPERROR % response.code.to_s, "HTTPError")
            end
            return nil
        else
            printError(STR_CRATEID_ERROR, @options.crateID)
            exit 1
        end
    end
    
    def deleteCrate(crateID)
        if IDvalid?(crateID)
            info "Getting previous crate name."
            @prevNames << getCrateName(crateID)
            info "Deleting crate #{crateID}."
            response = Typhoeus::Request.post("#{BaseURL}crates/destroy/#{crateID}.json",
                                                 :username => @options.username,
                                                 :password => @options.password,
                                                 )
      
            if response.success? # This checks if the request was successful or prints error messages if it went wrong.
                info "Got response from server."
                return parseResponse(response) # return native Ruby hash instead of JSON.
            elsif response.timed_out?
                printError(STR_TIMEOUT, "TimeOut")
            elsif response.code == 0
                # Could not get an http response, something's wrong.
                printError(response.curl_error_message, "HTTPError")
            else
                # Received a non-successful http response.
                printError(STR_HTTPERROR % response.code.to_s, "HTTPError")
            end
            return nil
        else
            printError(STR_CRATEID_ERROR, crateID)
        end
    end
    
    def downloadAll
        @files = listFiles if @files.nil?   # do not query the server each time a search is made.
        crates = @files['crates']
        for crate in crates
            downloadCrates(crate['id'])
        end
    end
    
    # ------
    
    def parseResponse(response)
        parsed = JSON.parse(response.body)
        puts parsed if $debug
        return parsed
    end
    
    # ------
    
    def PRINTtestCredentials(hash)
        return nil if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("success")
            echo STR_VALID_CREDENTIALS
            else
            printError(STR_INVALID_CREDENTIALS, "User:#{@options.username} Pass:#{@options.password}")
        end
    end
    
    def PRINTuploadFile(hash)
        return nil if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            printFile(File.basename(@arguments[@argCounter]), nil, hash['file']['short_code'], hash['file']['id'])
        end
    end
    
    def PRINTdeleteFile(hash)
        return nil if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            echo STR_DELETED % [@prevNames[@argCounter]]
        end
    end
    
    def PRINTlistFiles(hash)
        return nil if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
                printError(hash['message'], @arguments[@argCounter])
        else
            crates = hash['crates']
            for crate in crates
                echo "\n"
                printCrate(crate['name'], crate['short_code'], crate['id'])
                if crate['files']      # test if crate is empty
                    for file in crate['files']
                        printFile(file['name'], file['size'], file['short_code'], file['id'])
                    end
                else
                    echo STR_EMPTY_CRATE
                end
            end
        end
    end
    
    def PRINTdownloadFiles(name)
        return 0 if name.nil?    # skip the output if name doesn't exist.
        name = truncateName(name, $width-12) if name.length > $width-12
        echo "#{name} downloaded."
    end
        
    def PRINTsearchFile(array)
        if array.empty?
            printError(STR_NO_FILES_FOUND, @arguments[@argCounter])
        else
            echo "\n"
            echo green(@arguments[@argCounter]+":")  # print header for matched files
            for file in array
                printFile(file['name'], file['size'], file['short_code'], file['id'])
            end
        end
    end
    
    def PRINTsearchCrate(array)
        if array.empty?
            printError(STR_NO_CRATES_FOUND, @arguments[@argCounter])
        else
            echo "\n"
            echo green(@arguments[@argCounter]+":")   # print header for matched files
            for crate in array
                printCrate(crate['name'], crate['short_code'], crate['id'])
            end
        end
    end
    
    def PRINTlistFileID(hash)
        return nil if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            printFile(hash['item']['name'], hash['item']['size'], hash['item']['short_code'], hash['item']['id'])
        end
    end
    
    def PRINTcreateCrate(hash)
        return nil if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            printCrate(hash['crate']['name'], hash['crate']['short_code'], hash['crate']['id'])
        end
    end
    
    def PRINTlistCrates(hash)
        return nil if hash.nil?    # skip the output if hash doesn't exist.
        if hash.class == Hash
            if hash.values.include?("failure")
                printError(hash['message'], @arguments[@argCounter])
            end
            crates = hash['crates']
            for crate in crates
                printCrate(crate['name'], crate['short_code'], crate['id'])
            end
        else
            for crate in hash # it's not actually a hash (it's an array), but it made more sense to have it named like that.
                echo "\n"
                printCrate(crate['name'], crate['short_code'], crate['id'])
                if crate['files']      # test if crate is empty
                    for file in crate['files']
                        printFile(file['name'], file['size'], file['short_code'], file['id'])
                    end
                    else
                    echo STR_EMPTY_CRATE
                end
            end
        end
    end
    
    def PRINTdownloadCrates(nothing)
        # do nothing. I already printed everything on the fly.
    end
    
    def PRINTrenameCrate(hash)
        return nil if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            echo STR_RENAMED % [@prevNames[0], hash['crate']['name']]   # using 0 as magic number because this always uses only one argument.
        end
    end
    
    def PRINTdeleteCrate(hash)
        return nil if hash.nil?    # skip the output if hash doesn't exist.
        if hash.values.include?("failure")
            printError(hash['message'], @arguments[@argCounter])
        else
            echo STR_DELETED % [@prevNames[@argCounter]]
        end
    end
    
    def PRINTdownloadAll
        # do nothing. I already printed everything on the fly.
    end
    
    # Map names to IDs
    
    def getIDsForCrates(array)
        info "Getting IDs for crate names: #{array}"
        ids = []
        for name in array
            if IDvalid?(name)
                ids << name
                next
            end
            crates = searchCrate(name) if @crates.nil?
            for crate in crates
                ids << crate['id'].to_s
            end
        end
        
        if ids.count == array.count
            info "Got IDs: #{ids}"
            return ids
        elsif ids.count == 0
            printError(STR_NO_CRATES_FOUND, name)
            exit 1
        elsif ids.count > array.count
            info "There are more IDs than names. This should only happen when using regular expressions."
            printError(STR_TOO_MANY_CRATES, name)
            exit 1
        end
    end
    
    def getIDsForFiles(array)
        info "Getting IDs for filenames: #{array}"
        ids = []
        for name in array
            if IDvalid?(name)
                ids << name
                next
            end
            files = searchFile(name)
            for file in files
                ids << file['id'].to_s
            end
        end
        
        if ids.count == array.count
            info "Got IDs: #{ids}"
            return ids
        elsif ids.count == 0
            printError(STR_NO_FILES_FOUND, name)
            exit 1
        elsif ids.count > array.count
            info "There are more IDs than names. This should only happen when using regular expressions."
            printError(STR_TOO_MANY_FILES, name)
            exit 1
        end
    end
    
    def getIDsForCrates!(array)  # these methods return ALL the matches for all the IDs. Used with --regexp
        info "Getting IDs for crate names: #{array}"
        ids = []
        for name in array
            if IDvalid?(name)
                ids << name
                next
            end
            crates = searchCrate(name) if @crates.nil?
            for crate in crates
                ids << crate['id'].to_s
            end
        end
        info "Got IDs: #{ids}"
        return ids
    end
    
    def getIDsForFiles!(array)  # these methods return ALL the matches for all the IDs. Used with --regexp
        info "Getting IDs for filenames: #{array}"
        ids = []
        for name in array
            if IDvalid?(name)
                ids << name
                next
            end
            files = searchFile(name)
            for file in files
                ids << file['id'].to_s
            end
        end
        info "Got IDs: #{ids}"
        return ids
    end
    
    def getIDForCrate(name)
        info "Getting crate ID for name: #{name}"
        id = getIDsForCrates([name])
        if id.count == 1
            info "Got crate ID: #{id[0]}"
            return id[0]
        elsif id.count == 0
            printError(STR_NO_CRATES_FOUND, name)
            exit 1
        elsif id.count > 1
            printError(STR_TOO_MANY_CRATES, name)
            exit 1
        end
    end
    
    def getIDForFile(name)
        info "Getting file ID for name: #{name}"
        id = getIDsForFiles([name])
        if id.count == 1
            info "Got file ID: #{id[0]}"
            return id[0]
        elsif id.count == 0
            printError(STR_NO_FILES_FOUND, name)
            exit 1
        elsif id.count > 1
            printError(STR_TOO_MANY_FILES, name)
            exit 1
        end
    end
    
    # map IDs to names.
    
    def getCrateName(id)
        info "Getting crate name for ID: #{id.to_s}"
        @files = listFiles if @files.nil?   # do not query the server each time a search is made.
        regex = Regexp.new(id.to_s, Regexp::IGNORECASE)
        allCrates = @files['crates']
        for crate in allCrates
            match = crate if regex.match(crate['id'].to_s) != nil
        end
        info "Got crate name: #{match['name']}"
        return match['name']
    end
    
    def getFileName(id)
        info "Getting filename for ID: #{id.to_s}"
        @files = listFiles if @files.nil?   # do not query the server each time a search is made.
        regex = Regexp.new(id.to_s, Regexp::IGNORECASE)
        allCrates = @files['crates']
        for crate in allCrates
            if crate['files']      # test if crate is empty
                for file in crate['files']
                    match = file if regex.match(file['id'].to_s) != nil
                end
            end
        end
        info "Got filename: #{match['name']}"
        return match['name']
    end
    
    # Get the URLs to download a file/crate
    
    def getFileLongURL(id)
        info "Getting long URL for file ID: #{id}"
        shortURL = getFileShortCode(id)
        info "Got short code: #{shortURL}"
        response = Typhoeus::Request.get("http://letscrate.com/#{shortURL}")  # Contacts the server to "download", and gets instead a 302 HTTP code with a redirection URL.
        longURL = response.headers[/(Location: )(\S*)/, 2]  # Regex that searches for "Location: URL" and returns only the URL. Magic.
        info "Got long URL: #{longURL}"
        return longURL
    end
    
    def getFileShortCode(id)
        info "Getting short code for file ID: #{id}"
        ids = []
        @files = listFiles if @files.nil?   # do not query the server each time a search is made.
        allCrates = @files['crates']
        for crate in allCrates
            if crate['files']      # test if crate is empty
                for file in crate['files']
                    return "#{file['short_code']}" if file['id'] == id.to_i
                end
            end
        end
        return nil
    end
    
    # Get fileID of files inside a crate.
    
    def getFilesInCrateID(crateID)
        info "Getting files in crate with ID: #{crateID}."
        ids = []
        @files = listFiles if @files.nil?   # do not query the server each time a search is made.
        allCrates = @files['crates']
        for crate in allCrates
            if crate['id'] == crateID.to_i
                matchedCrate = crate
                break
            end
        end
        for file in matchedCrate['files']
            ids << file['id']
        end if matchedCrate['files'] # empty crate protection
        if ids.count > 0
            info "Got files: #{ids}"
            return ids
        else
            return nil
        end
    end
    
    # Initial checks on IDs.
    
    def mapCrateIDs(array)
        if @options.regex
            info "Mapping names to Crate IDs. Regexp is on."
            array = getIDsForCrates!(array)
            else
            info "Mapping names to Crate IDs."
            array = getIDsForCrates(array)
        end
        
        return array
    end
    
    def mapFileIDs(array)
        if @options.regex
            info "Mapping names to file IDs. Regexp is on."
            array = getIDsForFiles!(array)
            else
            info "Mapping names to file IDs."
            array = getIDsForFiles(array)
        end
        
        return array
    end
    
    # Get crates with ID.
    
    def getCrateWithID(id)
        info "Getting crate with ID: #{id}."
        @files = listFiles if @files.nil?   # do not query the server each time a search is made.
        allCrates = @files['crates']
        for crate in allCrates
            if crate['id'] == id.to_i
                return crate
            end
        end
    end
end

# Create and run the application
app = App.new(ARGV)
app.run
exit 0