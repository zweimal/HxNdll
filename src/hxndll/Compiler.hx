/*
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
 * 
 * This file is part of HxNdll
 * 
 * Copyright (C) 2013 German Allemand
 * 
 * HxNdll is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 * 
 * HxNdll is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 * 
 * You should have received a copy of the GNU Library General Public
 * License along with this library; If not, see <http://www.gnu.org/licenses/>.
 */

package hxndll;

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
					haxe.macro.Compiler.addMetadata("@:build(hxndll.Transformer.build())", cl);
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