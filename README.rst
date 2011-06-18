======
Charge
======

Charge game engine, but better know as Charge Miners a Minecraft Viewer.

.. image:: https://github.com/Wallbraker/Charged-Miners/wiki/shot-1.jpg


Getting started
===============

Dependencies
------------

In order to run Charge you need to install the following libraries: SDL,
OpenAL and OpenGL. A D compiler is needed to build Charge but should you have
have downloaded prebuilt binaries this is not needed (see below on which). It
is not needed to install the development version of the libraries (other then
libphobos if you are building Charge of course, but this should come with the
D compiler).

For Ubuntu you can use this command:

::

 $ sudo apt-get install libsdl1.2debian libopenal1

For Fedora you can do this with:

::

 $ sudo yum install SDL openal-soft

On Mac you will need to download and install the SDL framework into
/Library/Frameworks, both for compiling and running. Hopefully in the future
this will not be needed for running.


D Compiler
----------

Both GDC and DMD can compile Charge. Since LDC does not support Phobos which
Charge uses (minimally, tangobos might be able to support it, any patches
that improves tangobos support is sought).

Linux
*****

For Linux's with GDC packaged (like Ubuntu) it is the recommended compiler.
To get GDC on Ubuntu do this:

::

  $ sudo apt-get install gdc

For DMD known working are DMD 1.062 and above, please note that as of DMD 1.064
you need to remove the -L--export-dynamic flag from dmd.conf or you will get
crashes inside of C libraries (this will be fixed in Charge instead soon). To
setup DMD just follow the Mac instructions.

Mac
***

There are no packages of GDC for Mac so DMD should be used. DMD 1.062, 1.064 &
1.068 and above is known to be working. To install it just excract the contents
of dmd.1.<version>.zip <somewhere> and set the DMD enviromental variable to be
"<somewhere>/osx/bin/dmd" or put the folder "<somewhere>/osx/bin" on the path.

Other
*****

For other platforms you need probably need to compile it you can get the
latest version from here https://bitbucket.org/goshawk/gdc/wiki/Home
Cross compiling on Linux to Windows is confirmed working.


Building
--------

Now you just need to build Charge, to do so type:

::

  $ make

Thats it, but before running Charge for the first run this command:

::

  $ make res

This will download the necessary resources files from the web. After that


Running
-------

::

  $ make run


Contributing
============

Please feel free to contribute. Contributing is easy! Just send us your code.
Diffs are appreciated, in git format; Github pull requests are excellent. The
worst thing that can happen is that we will ignore you.

Things to consider:

 * While Charge has a engine part and a per game part its not strict where
   things go. There is a time for over engineering and a time to get stuff
   working. If its to mess put in a branch and we can hack on it till its
   all good. Nothing is perfect from the start.
 * Charge is GPLv2. Your contributions will be under that same license. If
   this isn't acceptable, then your code cannot be merged. This is really the
   only hard condition.
 * Patches that you want to be committed to the main repository will need to
   have your signoff (just commit with --signoff and git will add it for you).
 * Have fun and there will be cake! That is all!



.. image:: https://github.com/Wallbraker/Charged-Miners/wiki/shot-2.jpg

