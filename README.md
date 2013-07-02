# Vulcan

A build server in the cloud.

## Install

    $ gem install vulcan

## Usage

    $ vulcan help
    Tasks:
      vulcan build            # build a piece of software for the heroku cloud using COMMAND as a build command if no COMMAND is...
      vulcan create APP_NAME  # create a build server on Heroku
      vulcan help [TASK]      # Describe available tasks or one specific task
      vulcan update           # update the build server

    $ vulcan help create
    Usage:
      vulcan create APP_NAME

    Options:
      -r, [--region=REGION]  # specify region for this build server to run in

    create a build server on Heroku
    
    $ vulcan help build
    Usage:
      vulcan build

    Options:
      -c, [--command=COMMAND]     # the command to run for compilation
      -n, [--name=NAME]           # the name of the library (defaults to the directory name)
      -o, [--output=OUTPUT]       # output build artifacts to this file
      -p, [--prefix=PREFIX]       # vulcan will look in this path for the compiled artifacts
      -s, [--source=SOURCE]       # the source directory to build from
      -d, [--deps=one two three]  # urls of vulcan compiled libraries to build with
      -v, [--verbose]             # show the full build output

    build a piece of software for the heroku cloud using COMMAND as a build command
    if no COMMAND is specified, a sensible default will be chosen for you

## Examples

### Create a Build Server

You must have a verified Heroku account with your credit card entered to create a build server.
This is required to add the free Cloudant add-on.

    $ vulcan create vulcan-david
    Creating vulcan-david... done, stack is cedar
    http://vulcan-david.herokuapp.com/ | git@heroku.com:vulcan-david.git
    ...

### Build

    $ vulcan build -s ~/Code/memcached -p /tmp/memcached -c "./autogen.sh && ./configure --prefix=/tmp/memcached && make install"
    >> Packaging local directory
    >> Uploading code for build
    >> Building with: ./autogen.sh && ./configure --prefix=/tmp/memcached && make install
    >> Downloading build artifacts to: /tmp/memcached.tgz

    $ tar tvf /tmp/memcached.tgz
    drwx------  0 u24714 24714       0 Sep 21 20:25 bin/
    -rwxr-xr-x  0 u24714 24714  273082 Sep 21 20:25 bin/memcached
    drwx------  0 u24714 24714       0 Sep 21 20:25 include/
    drwx------  0 u24714 24714       0 Sep 21 20:25 include/memcached/
    -rw-r--r--  0 u24714 24714   14855 Sep 21 20:25 include/memcached/protocol_binary.h
    drwx------  0 u24714 24714       0 Sep 21 20:25 share/
    drwx------  0 u24714 24714       0 Sep 21 20:25 share/man/
    drwx------  0 u24714 24714       0 Sep 21 20:25 share/man/man1/
    -rw-r--r--  0 u24714 24714    5304 Sep 21 20:25 share/man/man1/memcached.1

### Keep the Build Server Updated

    $ vulcan update
    Initialized empty Git repository in /private/var/folders/rm/qksq9jk15vx0xcjxkqc8yg5w0000gn/T/d20110921-70016-1iksqwy/.git/
    Counting objects: 176, done.
    Delta compression using up to 8 threads.
    Compressing objects: 100% (156/156), done.
    Writing objects: 100% (176/176), 326.86 KiB, done.
    Total 176 (delta 5), reused 0 (delta 0)

    -----> Heroku receiving push
    -----> Node.js app detected
    -----> Vendoring node 0.4.7
    -----> Installing dependencies with npm 1.0.27

           Dependencies installed
    -----> Discovering process types
           Procfile declares types -> web
    -----> Compiled slug size is 5.5MB
    -----> Launching... done, v5
           http://vulcan-david.herokuapp.com deployed to Heroku

    To git@heroku.com:vulcan-david.git
     + 2e69a42...eddcb91 master -> master (forced update)
