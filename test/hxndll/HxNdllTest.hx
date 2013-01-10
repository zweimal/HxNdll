package hxndll;
import haxe.unit.TestCase;

/**
 * ...
 * @author German Allemand
 */

class HxNdllTest extends TestCase
{
	private var frame : WaxeFrame;
	
	public function testBoot()
	{
		WaxeApp.boot(function()
		{
			try 
			{
				frame = new WaxeFrame(null, null, "HxNdllTest", null, { width: 450, height: 300 } );
				
				WaxeApp.setTopWindow(frame);
				frame.shown = true;
			}
			catch (e : Dynamic)
			{
				trace(e);
			}
		});
		
		assertTrue(frame.wxHandle != null);
	}
}