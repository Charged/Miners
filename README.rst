======
Charge
======

Charge game engine, but better know as Charged Miners a Classic Minecraft
Client.

.. image:: https://github.com/Charged/Miners/wiki/shot-1.jpg


Getting started
===============

Dependencies
------------

In order to run Charge you need to install the following libraries: SDL,
OpenAL and OpenGL. A D1 compiler is needed to build Charge but should you have
have downloaded prebuilt binaries this is not needed (see below on which). It
is not needed to install the development version of the libraries (other then
libphobos if you are building Charge of course, but this should come with the
D1 compiler). Note again a D1 compiler is needed, for Ubuntu this package is
called gdc-v1.

Linux
*****

For Ubuntu you can use this command:

::

 $ sudo apt-get install libsdl1.2debian libopenal1

For Fedora you can do this with:

::

 $ sudo yum install SDL openal-soft

Mac
***

On Mac you will need to download and install the SDL framework somewhere
where it will be picked up when you run the application. If you have downloaded
the release app you can just copy the Charge binary into the app folder and it
will use the shipped SDL.framework from within that app. Alternatively you can
use homebrew:

::

  $ brew install sdl


Graphics Drivers
----------------

Make sure you have the latest graphics drivers installed, known bad are:

 * NVIDIA 195.36.31 on debian
 * Mesa 7.9 and below


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

There are no packages of GDC for Mac so DMD should be used. Only DMD 1.069 and
above works as Charge depends on bugfixes in that version to work. To install
it just excract the contents of dmd.1.<version>.zip <somewhere> and set the
DMD enviromental variable to be "<somewhere>/osx/bin/dmd" or put the folder
"<somewhere>/osx/bin" on the path.

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



.. image:: https://github.com/Charged/Miners/wiki/shot-2.jpg

