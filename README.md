Haxe-ndll: a NDLL creation utility
=====================

If you have ever tried to write a Haxe/ndll binding, you know it so much repetitive; create every Haxe wrapper class with all theirs fields with primitive calls static variables for load primitives and code 
the primitives with C/C++.
This util will help on do it easier and faster.

Example
-------

Before:
Haxe side:
<pre>
package wrapper;

#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#end

class WrapSum
{
	static var sum = Lib.load( "Simple", 'sum', 2 );

	public static function doSum( a : Int, b : Int )
	{
		return sum( a, b );
	}
}
</pre>

C++ side:
<pre>
#define IMPLEMENT_API
#include &lt;hx/CFFI.h&gt;

value sum(value a, value b)
{
    if( !val_is_int(a) || !val_is_int(b) ) return val_null;
        return alloc_int(val_int(a) + val_int(b));
}
DEFINE_PRIM( sum, 2 );
</pre>

After:
<pre>
package wrapper;

@:ndll(lib="Simple")
class WrapSum
{
	@:ndll public static function sum( a : Int, b : Int ) : Int { }
}
</pre>

C++ side:
<pre>
#define IMPLEMENT_API
#include "hxndll.h"

inline int wrapper_sample_sum(int a, int b)
{
    return a + b;
}
HXNDLL_DEFINE_PRIM( wrapper_sample_sum, 2 );
</pre>

Installation
------------
To install Haxe-ndll, in command prompt run this:  
<pre>haxelib install hxndll</pre>
And that's all. Ready to use.

Usage
-----

First, you have to setup your project and there are at least 3 way to do that

1. In you `project.hxml` add:  
	`--macro hxndll.Compiler.process(['<path/to/src>', <path/to/another/src>, ...])`

2. Implementing `hxndll.Importer` each class you want to process.  
	It uses `@:autoBuild` metatdata, see http://haxe.org/manual/macros/build#autobuild for more information.

3. At each class you want to process add metadata:  
	`@:build(hxndll.Transformer.build())`

Personally I prefer method 1 or 3, because they leave no footprints at final code.

Finally, you must add `@:ndll` or `@:ndll_use` metadata to your class in order to proccess it. Further on you will find complete info about it <a href="#get-shorter-user-defined-defaults">here</a>.

__*!!Tip:*__ You only can use __Haxe Ndll__ with __classes__.  

Let's get down to work on Haxe classes:

###First reduction: `@:ndll_import`###
><pre>FFun(static, empty) -> FVar(static, w/ prim load)</pre>  
><pre>FVar(static, empty) -> FVar(static, w/ prim load)</pre>

It is the easiest and simplest reduction and it is used to load a primitive.
i.e.:
<pre>
@:ndll_import(lib="waxe")
static function wx_window_create( args : Array<Dynamic> ) : Dynamic { }
</pre>
or
<pre>
@:ndll(lib="waxe")
static var wx_window_create : Array<Dynamic> -> Dynamic;
</pre>
They are equivalent and produce this field:
<pre>
static var wx_window_create : Array<Dynamic> -> Dynamic = cpp.Lib.load("waxe", "wx_window_create", 1);
</pre>

__HxNdll__ helps to forget the porting tricks, you don't need to worry about them. So forget to import `cpp.Lib` or `neko.Lib`, __HxNdll__ will do it for you depending on target.

__*!!Tip:*__ `@:ndll_import` can be use with __static *functions*__ or __static *variables*__.  

__*!!Tip:*__ Only with __static *variables*__, mere `@:ndll` means `@:ndll_import`

####`@:ndll_import` parameter list####
- `lib`: type `String`, default is user defined otherwise throws an error.  
	Its value is some library file name (without extension ".ndll") i.e.: `lib="waxe"`
- `prefix`: type `String`, default is user defined otherwise `""` (empty string).  
	Its value is first part of primitive name. i.e.: `prefix="wx_window_"`.
- `name`: type `String`, default is field name.  
	Its value is last part of primitive name and it will be transformed to underscore case. i.e.: "getSize" will become to "get_size". 

So, previous example becames:
<pre>
@:ndll_import(lib="waxe", prefix="wx_window_")
static function create( args : Array<Dynamic> ) : Dynamic { }
</pre>

###Get shorter: User-defined defaults###
The main goal of __HxNdll__ is to write more with less. When you code a wrapper class usually all its methods have a pattern, I mean, they have the `@:ndll` metadata with almost the same parameters.
Here is when `@:ndll_use` class metadata appears.

__*!!Tip:*__ class metadatas `@:ndll_use` and `@:ndll` are the same thing, although the first is verbose.

####`@:ndll_use` default parameter list####
- `lib`: type `String`. Its value is some library file name
- `prefix`: type `String`, default is `""` (empty string).  
	Its value is first part of primitive name.
- `params`: type `Array<Expr>`, default is `[]` (empty array).  
	Its value is an ordered list of arguments which will be merged with field arguments. See <a href="#parameters-merging">Paramaters Merging</a> section.

###Second reduction: `@:ndll_forward`###
> <pre>
>              /-> FFun(w/ prim call)
> FFun(empty) -|
>              \-> FVar(static, w/ prim load)
> </pre>

`@:ndll_forward` generates primitive load and fills function block with primitive call.

###Third reduction: `@:ndll_prop`###
> <pre>
>                             /-> FProp(w/ setter or getter) 
>                             |-> nil or setter /-> FFun(w/ prim call)
> FProp(w/ setter or getter) -|                 \-> FVar(static, w/ prim load)
>                             \-> nil or getter /-> FFun(w/ prim call)
>                                               \-> FVar(static, w/ prim load) 
> </pre> 
