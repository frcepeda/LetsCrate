LetsCrate
---------

This is an unofficial command line client for [Let's Crate](http://letscrate.com) written in Ruby.

Please let me know what you think! You can reach me at frcepeda AT gmail DOT com

Quick start manual
------------------

To use this program, you need to create an account at [Let's Crate](http://letscrate.com).

Every command needs the "-l" switch, with the username and password separated by a
colon.

Example: 

    -l username:password  
    -l "username:password"
    
After that, you can select an action from the list below and use the command normally.

You can use multiple files, names or crates in the commands whose explanations
are in plural.

If you use the --regexp function with the commands marked with an asterisk, every argument
will be treated as a regular expression. The search option uses regular expressions
by default.

An ID is a 5 digit identifier used internally by Let's Crate. 
To know the ID of your files, use the "-a" option to list them with their respective URLs and IDs.  
Generally, you don't need to know the ID of a file, but if you do, you can use it
instead of the name of the files/crates (it's faster).

Usage
-----

    Usage: LetsCrate.rb <-l username:password> [options] file1 file2 ...
       or: LetsCrate.rb <-l username:password> [options] name1 name2 ...

	Mandatory arguments:
    -l, --login [username:password]  Login with this username and password

	File functions:
    -u, --upload [Crate name]        Upload files to crate
    -r, --delete                     Delete files with names *
    -a, --list                       List all files
    -d, --download                   Download files with names *
    -s, --search                     Search for files with names
    -i, --id                         Show files with IDs

	Crate functions:
    -N, --newcrate                   Create new crates with names
    -A, --listcrates                 List all crates (or files in crates, if names are passed)
    -D, --downloadcrates             Download crates with names *
    -S, --searchcrates               Search for crates with names
        --renamecrate [Crate name]   Rename crate to name
    -R, --deletecrate                Delete crates with names *

	Misc. options:
        --regexp                     Treat names as regular expressions
    -t, --test                       Only test the credentials
        --ids                        Print IDs when listing files/crates.
    -v, --verbose                    Output extra info to the terminal
    -q, --quiet                      Do not output anything to the terminal
        --version                    Output version
    -h, --help                       Display this screen

Tips
----

To avoid having to type your credentials every time you want to run this command, make an alias
in your .bashrc file with something like this:

`alias letscrate = "/path/to/script/LetsCrate.rb -l 'username:password'"`

TO DO
-----

* Use a configuration file to avoid typing the login credentials each time the command is run.

BUGS
----

* None yet, but please open a ticket (or email me) if you find one.

License
-------

Copyright (C) 2011 by Freddy Román

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.