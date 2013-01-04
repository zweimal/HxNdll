package ndll;
import haxe.unit.TestCase;

/**
 * ...
 * @author German Allemand
 */

class NdllTest extends TestCase
{
	private var frame : WaxeFrame;
	
	public function testBoot()
	{
		WaxeApp.boot(function()
		{
			try 
			{
				frame = new WaxeFrame(null, null, "NdllTest", null, { width: 450, height: 300 } );
				
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