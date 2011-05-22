**Whoops, Let's Crate seems to be acting up a bit. I'm getting 502 errors whenever I try
to connect with their [API](http://letscrate.com/api). Can someone confirm this for me?
Authentication seems to pass through, but I get the error afterwards.**

**To check if it works for you, use the -t option like this: `letscrate.rb -l username:password -t`. 
It'll tell you if something's wrong.**

LetsCrate
=========

This is an unofficial command line client for [Let's Crate](http://letscrate.com) written in Ruby.

Please let me know what you think! You can reach me at <frcepeda@gmail.com>.

Quick start manual
==================

To use this program, you need to create an account at [Let's Crate](http://letscrate.com) and
to install Typhoeus. You can do that with `gem install typhoeus`.

**Every command needs the "-l" switch**, with the username and password separated by a
colon.

Example: 

    -l username:password  
    -l "username:password"
    
After that, you can select an action from the list below and use the command normally.

You can use multiple files, names or crates in the commands whose descriptions
are in plural.

If you use the --regexp function with the commands marked with an asterisk, every argument
will be treated as a regular expression. The search and the list options use regular expressions
by default.

Usage
=====

    Usage: letscrate.rb <-l username:password> [options] file1 file2 ...
       or: letscrate.rb <-l username:password> [options] name1 name2 ...

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
        --debug                      Internal use only.

Tips
====

Login information
-----------------

To avoid having to type your credentials every time you want to run this command, make an alias
in your .bashrc file with something like this:

`alias letscrate = "/path/to/letscrate.rb -l 'username:password'"`

IDs
---

An ID is a 5 digit identifier used internally by Let's Crate. 
To know the ID of your files, use the "--ids" option to list them with their respective
URLs and IDs when executing any command.

For example, you can list all your crates and files with their IDs by typing
`letscrate.rb -l username:password -a --ids`

Generally, you don't need to know the ID of a file, but if you do, you can use it
instead of the name of the files/crates (it's faster).

**You can also mix names with IDs whenever you want to.**

If for some reason one of your files or crates is named with a 5 digit number, to stop
this program from treating it as an ID, suffix it with a '$' (e.g. "34982$" will be treated as
a name instead of an ID).

String Handling
---------------

You can type only a fragment of a crate or file's name if you know it's unique. Even if you
don't specify the --regexp option, the program internally uses *case insensitive* regular
expressions. For example, you can type only "yell" if one of your crates/files is called
"Yellow.zip" and you know none of the other ones have that exact string in them.

In the off chance that two names collide (e.g. "apple" and "apples with pears"), you can add
a '$' to the end of the shorter one ("apple$").

What is a regular expression?
-------------------------------

You can read about 
[regular expressions in Wikipedia](http://en.wikipedia.org/wiki/Regular_expression).

TO DO
=====

* Use a configuration file to avoid typing the login credentials each time the command is run.

Bugs
====

* None yet, but please open a ticket (or email me) if you find one.

Quirky stuff
============

* Let's Crate just added password verification for files (it was previously Crate only), 
which renders this application useless for downloading them. You can still upload, delete and
list them, but you can't download them unless you use your browser.

License
=======

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