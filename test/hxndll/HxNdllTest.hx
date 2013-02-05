package hxndll;
import haxe.unit.TestCase;
import wrapper.Sample;

/**
 * ...
 * @author German Allemand
 */

class HxNdllTest extends TestCase
{
	private var sample : Sample;
	
	public function testPrimitives()
	{
		var result : Int = Sample.sum(2, 3);
		trace("result=" + result);
		assertTrue(result == 5);
		
		sample = new Sample();
		result = sample.sum7(1, 2, 3, 4, 5, 6, 7);
		trace("result=" + result);
		assertTrue(result == 28);
		
		sample.voidFunc(3.1416);
	}
}