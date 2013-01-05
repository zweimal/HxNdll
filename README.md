Haxe NDLL import util
=====================

If you have ever tried to write a Haxe/ndll binding, you know it so much repetitive; create every Haxe 
wrapper class with all theirs fields with primitive calls static variables for load primitives and code 
the primitives with c/c++.    
This util will help on do it easier and faster.

Examples
-----

Before:
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

After:
<pre>
package wrapper;

@ndll
class WrapSum
{
	@ndll(lib="Simple", name="sum")
	public static function doSum( a : Int, b : Int ) : Int { }
}
</pre>
