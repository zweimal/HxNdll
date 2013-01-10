package hxndll;

/**
 * ...
 * @author German Allemand
 */
@:ndll_use(lib="waxe", prefix="wx_frame_", params=[wxHandle])
class WaxeFrame 
{

	public var wxHandle : Dynamic;
	
	public function new(?inParent:Dynamic, ?inID:Int, inTitle:String="",
                  ?inPosition:{x:Int,y:Int},
                   ?inSize:{width:Int,height:Int}, ?inStyle:Int ) 
	{
		wxHandle = create([inParent==null ? null : inParent.wxHandle, inID, inTitle, inPosition, inSize, inStyle]);
	}
	
	@:ndll_import
	static function create(args : Array<Dynamic>) : Dynamic { }
	
	@:ndll_prop(prefix="wx_window_")
	public var shown(default, default):Bool;
	
	public function show(inShow : Bool = true) : Void
	{
		shown = inShow;
	}
}