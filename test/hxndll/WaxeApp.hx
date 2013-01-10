package hxndll;

/**
 * ...
 * @author German Allemand
 */
@:ndll(lib="waxe", prefix="wx_")
class WaxeApp 
{
	public static function boot(inOnInit:Void -> Void)
	{
		#if neko
		var init = neko.Lib.load("waxe", "neko_init",5);
		if (init!=null)
		{
			init(function(s) return new String(s),
				function(len:Int) { var r=[]; if (len>0) r[len-1]=null; return r; },
				null, true, false );
		}
		else
			throw("Could not find NekoAPI interface.");
		#end

		wx_boot(inOnInit);
	}


	@:ndll
	public static function quit() { }

	@:ndll(params=[inWindow.wxHandle,$])
	public static function setTopWindow(inWindow:WaxeFrame) { }
	
	@:ndll(prefix="")
	static var wx_boot : (Void -> Void) -> Void;

}