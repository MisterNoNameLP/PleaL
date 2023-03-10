PleaL (PleasandLua) is a customised version of the [lua language](https://lua.org).  

It aims to make coding in lua a more pleasant experience by expalnding the lua syntax, while keeping the original syntax intact. If you can write lua you can write PleaL as well!  
The most comprehensible new syntax possibilities are probably `++`, `--`, `+=` and `-=` (not implemented yet). But there is more as well.  
For more information about the expanded syntax is avaiable in the [wiki](https://github.com/MisterNoNameLP/pleal/wiki/Syntax).

# How it works
It works by converting PleaL code into native lua code, so it can be run in any ordinary lua5.1+ interpreter.  
The PleaL transpiler is written in pure lua and has no need for additional libraries or C bindings. 

# Compatibility
### Lua code compatibility
PleaL is basically compatible with any lua code/library. It is an expansion of the lua syntax and should never ever reduce the possibilities you have.

At the moment only the [variable embedding](https://github.com/MisterNoNameLP/pleal/wiki/Syntax#variable-embedding) could technically break scripts if strings are containing the embedding prefix symbol. But this problem can easly be fixed by changing the [configuration](https://github.com/MisterNoNameLP/pleal/wiki/Configuration) or by escaping the symbol using `\`.

### Pleal script compatility
After the v1 release there will be no compatibility breaking updates unless a new major version gets released.  
Until then new releases will often break the PleaL API, but most likley not the compatibility of PleaL script itself.

# Versioning 
Pleal uses [Semantic Versioning 2.0.0](https://semver.org/).  
With the exception of `-dev` versions, wich are indicating a development versions upon the given version. So `v1.2-dev` > `v1.2`.

# Licensing
PleaL is currently licensed under the MIT license. Altough this can chage to the GPLv3 at some point.

MIT License

PleaL Copyright (c) 2022 MisterNoNameLP

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.