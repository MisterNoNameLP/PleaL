PleaL (PleasandLua) is a customised version of the [lua language](https://lua.org).  

It aims to make coding in lua a more pleasant experience by expanding the lua syntax, while keeping the original syntax intact. If you can write lua you can write PleaL as well!  
More information about the expanded syntax is avaiable in the [wiki](https://github.com/MisterNoNameLP/pleal/wiki/Syntax).

# How it works
It works by converting PleaL code into native lua code, so it can be run in any ordinary lua interpreter.  
The PleaL transpiler is written in pure lua and has no need for additional libraries or C bindings.  

# Usage
The easyest way to use PleaL is to execute the [PleaL runner](https://github.com/MisterNoNameLP/PleaL/blob/main/src/plealRunner.lua) from the command line, givin the path do an PleaL script as first argument. This not only transpiles the PleaL code, but also expands the `require`, `dofile` and `loadfile` functions to be able to use PleaL files. So PleaL libraries can be required just like normal lua libraries for instance.


There is also an [transpiler API](https://github.com/MisterNoNameLP/PleaL/blob/main/src/plealTranspilerAPI.lua) that can be used inside of scripts to transpile PleaL code. But this API does not set an propper PleaL environment like the [runner](https://github.com/MisterNoNameLP/PleaL/blob/main/src/plealRunner.lua) does. So functions like `require` behave as normal and are not be able to handle PleaL code per default.

# Building
There is a script putting the [PleaL runner](https://github.com/MisterNoNameLP/PleaL/blob/main/src/plealRunner.lua) and its dependencies into a single script. This script then can be executet by any lua5.2+/LuaJIT interpreter to run PleaL scripts.

# Compatibility
### Lua 
The PleaL transpiler itself is lua5.1+ and LuaJIT compatible. But due to missing functionalities in lua5.1, the PleaL runner only works at lua5.2+ as well as LuaJIT.  

### Lua code
PleaL is basically compatible with any lua code. It is an expansion of the lua syntax and should never ever reduce the possibilities the developers have. So lua libraries can be used inside of PleaL script just as usual.

At the moment only the [variable embedding](https://github.com/MisterNoNameLP/pleal/wiki/Syntax#variable-embedding) could technically break scripts if strings are containing the embedding prefix symbol. But this problem can easly be fixed by changing the [configuration](https://github.com/MisterNoNameLP/pleal/wiki/Configuration) or by escaping the symbol using `\`.

# Installation
### Linux
At first the desired lua version have to be installed. How this is done it depending from the distribution used.  

To work with PleaL, the [all in one PleaL runner script](https://github.com/MisterNoNameLP/PleaL/blob/main/building/release/pleal) have to be put in an folder included in your $PATH. PleaL scripts then can be executet by calling `pleal SCRIPT.pleal`.

# Versioning 
Pleal uses [Semantic Versioning 2.0.0](https://semver.org/).  
With the exception of `-dev` / `-d` versions, wich are indicating a development versions upon the given version. So `v1.2-dev` > `v1.2`.

# Licensing
PleaL is licensed under the GPLv3 license.

Copyright (C) 2023  MisterNoNameLP

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.