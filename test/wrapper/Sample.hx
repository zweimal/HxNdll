package wrapper;

/**
 * ...
 * @author German Allemand
 */
@:ndll(lib="Simple")
class Sample extends hxndll.ObjectBase
{
	public function new() { super(); }

	@:ndll public static function sum( a : Int, b : Int ) : Int { }
	@:ndll public static var sum2 : Int -> Int -> Int;
	
	@:ndll public function sum7( a1 : Float, a2 : Int, a3 : Int, a4 : Int, a5 : Int, a6 : Int , a7 : Int ) : Int { }
	
	@:ndll(params=[this])
	public function voidFunc( f : Float ) { }
}