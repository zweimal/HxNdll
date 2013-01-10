import haxe.unit.TestRunner;
import hxndll.HxNdllTest;

/**
 * @author German Allemand
 */
class TestMain
{
	static function main()
	{
        var r = new TestRunner();
        
		r.add(new HxNdllTest());

        r.run();
    }
}
