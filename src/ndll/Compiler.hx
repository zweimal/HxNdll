package ndll;

/**
 * ...
 * @author German Allemand
 */

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class Compiler 
{
	static public function process(paths:Array<String>)
	{
		for (path in paths)
			traverse(path, "");
	}

	static function traverse(cp:String, pack:String)
	{
		for (file in neko.FileSystem.readDirectory(cp))
		{
			if (StringTools.endsWith(file, ".hx"))
			{
				var cl = (pack == "" ? "" : pack + ".") + file.substr(0, file.length - 3);
				try	{			
					haxe.macro.Compiler.addMetadata("@:build(ndll.Transformer.build())", cl);
				} 
				catch (e:Dynamic) {
					trace("traverse fail with class " + cl);
				}
			}
			else if(neko.FileSystem.isDirectory(cp + "/" + file))
				traverse(cp + "/" + file, pack == "" ? file : pack + "." +file);
		}
	}
}

#end