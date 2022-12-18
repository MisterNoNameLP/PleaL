Pleal (PleasandLua) is a customised version of the [lua language](https://lua.org).  

It aims to make coding in lua a more pleasant experience by expalnding the lua syntax, while keeping the original syntax intact. If you can write lua you can write pleal!  
The most comprehensible new syntax possibilities are probably `++`, `--`, `+=` and `-=` (not implemented yet). But there is more as well.  
For more information about the expanded syntax please visit the [wiki](WIKI_LINK).

# How it works
Pleal works by converting pleal code into native lua code, so it can be run in any ordinary lua interpreter.  
It is written in pure lua and has no need for additional libraries or C bindings.

# Compatibility
### Lua code compatibility
Pleal is basically compatible with any lua code/library. It is an expansion of the lua syntax and should never ever reduce the possibilities you have.

At the moment only the [variable embedding](https://github.com/MisterNoNameLP/pleal/wiki/Syntax#variable-embedding) could technically break scripts if strings are containing the replacement prefix symbol. But this problem can easly be fixed by changing the [configuration](https://github.com/MisterNoNameLP/pleal/wiki/Configuration) or by escaping the symbol using `\`.

### Pleal script compatility
After the v1 release there will be no compatibility breaking updates unless a new major version gets released.  
Until then new releases will often break the pleal API, but most likley not the compatibility of pleal script itself.

# Versioning 
Pleal uses [Semantic Versioning 2.0.0](https://semver.org/).  