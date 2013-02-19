# Util::Logger


## Abstract

This class allows you to print messages to the screen or into a file. With each
call to its print method you will (besides the actual message) pass a category
name. The categories have a certain order of severity and by adjusting the log
level you can easily control the verbosity of your program without touching your
code.

_Deprecation note_: Please note that I consider this module deprecated.
It is still used by a few of my perl projects but sooner or later no more
code will depend on this library.
It has been a bad idea to write "yet another logging module" in the first place.


## Dependencies

This module has no dependencies.


## Copyright and Licence

Copyright (C) 2005 Joachim Jautz

All rights reserved. This program is free software; you can redistribute it
and/or modify it under the terms of the Artistic License, distributed with
Perl.
