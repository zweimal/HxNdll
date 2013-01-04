import haxe.unit.TestRunner;
import ndll.NdllTest;

/**
 * @author German Allemand
 */
class TestMain
{
	static function main()
	{
        var r = new TestRunner();
        
		r.add(new NdllTest());

        r.run();
    }
}
