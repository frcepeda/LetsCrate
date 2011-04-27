LetsCrate
---------

This is an unofficial command line client for [LetsCrate][] written in Ruby.
Please let me know what you think! You can reach me at frcepeda AT gmail DOT com

[LetsCrate]: http://letscrate.com

Usage
-----

    Usage: LetsCrate.rb <-l username:password> [options] file1 file2 ...
    or: LetsCrate.rb <-l username:password> [options] id1 id2 ...

    -l, --login [username:password]  Login with this username and password
    -u, --upload [Crate ID]          Upload files to crate with ID
    -d, --delete                     Delete files with IDs
    -a, --list                       List all files by crate
    -i, --id                         Show files with IDs
    -s, --search                     Search for file with name
    -n, --new                        Create new crates with names
    -A, --listcrates                 List all crates
    -S, --searchcrates               Search for crate with name
    -r, --rename [Crate ID]          Rename crate to name
    -D, --deletecrate                Delete crates with IDs
    -t, --test                       Only test the credentials
    -q, --quiet                      Do not output anything to the terminal
    -v, --version                    Output version
    -h, --help                       Display this screen

An ID is a 5 digit identifier used internally by LetsCrate.
To know the ID of your files, use the "-a" option to list them with their
respective URLs and IDs.
You can also use regular expressions whenever a name is required (currently only the search option).

TO DO
-----

* Allow using filenames where IDs are required

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