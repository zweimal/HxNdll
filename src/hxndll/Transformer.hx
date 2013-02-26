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

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;


/**
 * ...
 * @author German Allemand
 */

class Transformer 
{
	// Metadata params
	static inline var LIB : String = "lib";
	static inline var CGEN : String = "cgen";
	static inline var PREFIX : String = "prefix";
	static inline var NAME : String = "name";
	static inline var PARAMS : String = "params";
	
	// Argument types
	static inline function DYNAMIC() : ComplexType return TPath({name: "Dynamic", pack: [], params: []});
	static inline function VOID() : ComplexType return TPath({name: "Void", pack: [], params: []});
	
	// Magic param modifiers
	static inline function WILDCARD() : ExprDef return EConst(CIdent("_"));
	static inline function END() : ExprDef return EConst(CIdent("$"));
	
	// Expr null
	static inline function NULL() : ExprDef return EConst(CIdent("null"));
	
	static var finishedClasses = new Map<ClassType, Array<Field>>();
	
	static var target : String;
	
	static var defaultMetadataParamsProcessors : Map<String, Expr->Dynamic>;
	static var metadataParamsProcessors : Map<String, Expr->Dynamic>;
	
	static function __init__() : Void
	{
		if (Context.defined("cpp")) 
			target = "cpp";
		else if (Context.defined("neko"))
			target = "neko";
		else 
			throw new Error("HxNdll: Target must be 'neko' or 'cpp'", Context.currentPos());
	
		defaultMetadataParamsProcessors = new Map<String, Expr->Dynamic>();
		defaultMetadataParamsProcessors.set(LIB, getStr);
		defaultMetadataParamsProcessors.set(PREFIX, getStr);
		defaultMetadataParamsProcessors.set(PARAMS, getExprs);
		defaultMetadataParamsProcessors.set(CGEN, getBool);
		
		metadataParamsProcessors = new Map<String, Expr->Dynamic>();
		metadataParamsProcessors.set(LIB, getStr);
		metadataParamsProcessors.set(PREFIX, getStr);
		metadataParamsProcessors.set(NAME, getStr);
		metadataParamsProcessors.set(PARAMS, getExprs);
		metadataParamsProcessors.set(CGEN, getBool);
	}
	
	var defaultParams : Null<Map<String, Dynamic>>;
	var classRef : Null<Ref<ClassType>>;
	var classType : ClassType;
	var fields : Array<Field>;
	var result : Array<Field>;
		
	public static macro function build() : Array<Field>
	{
		return new Transformer(Context.getLocalClass(), Context.getBuildFields()).transform();
	}
	
	function new(classRef : Null<Ref<ClassType>>, fields : Array<Field>)
	{
		this.classRef = classRef;
		this.fields = fields;
		this.classType = classRef != null ? classRef.get() : null;   
		this.result = new Array<Field>();
	}
	
	function transform() : Array<Field> 
	{
		if (classRef == null)
		{
			//trace(Context.getLocalType());
			return fields;
		}
		
		
		if (finishedClasses.exists(classType))
		{
			trace("skipping: " + classType.name);
			return finishedClasses.get(classType);
		}
		
		setupDefaultMetadataParams();
	
		if (defaultParams == null)
		{
			trace("skipping(r2): " + classType.name);
			finishedClasses.set(classType, fields);
			return fields;
		}
		trace("Ndll class: " + classType.name);
		
		//trace("defualtLib: " + defaultParams.get(LIB));
		
		for (field in fields)
		{
			switch (getMetadataType(field.meta))
			{
				case MImport(params):
					processImportField(field, mergeMetadataParams(params, defaultParams));
				
				case MForward(params):
					processForwardField(field, mergeMetadataParams(params, defaultParams));
				
				case MProperty(params):
					processPropertyField(field, mergeMetadataParams(params, defaultParams));
				
				case MInfer(params):
					switch (field.kind)
					{
						case FVar(_, _):
							processImportField(field, mergeMetadataParams(params, defaultParams));
							
						case FFun(_):
							processForwardField(field, mergeMetadataParams(params, defaultParams));
						
						case FProp(_, _, _, _):
							processPropertyField(field, mergeMetadataParams(params, defaultParams));
					}
				
				default:
					result.push(field);
			}
		}
		
		finishedClasses.set(classType, result);
		return result;
	}
	
	
	function processImportField(inField : Field, inParams : Map<String, Dynamic>) : Void
	{
		if (!isStatic(inField))
			throw new Error("ndll_import: Function must be static", inField.pos);
		
		var pos : Position = inField.pos;
		var fieldName : String = inField.name;
		var primName : String = getPrimName(inParams, fieldName);
		var fargs : Array<ComplexType>;
		var fret : ComplexType;
		
		//trace("before:" + inField);
		switch (inField.kind)
		{
			case FFun(func):
				assureMetadataParams(inParams, [LIB], pos);
				fargs = getArgTypes(func.args);
				fret = nonNullType(func.ret);
				
			case FVar(TFunction(args, ret), _):
				assureMetadataParams(inParams, [LIB], pos);
				fargs = args;
				fret = ret;
			
			default:
				throw new Error("ndll_import: It must be a function expression", pos);
		}
		
		var prim : Field = createPrim(inParams.get(LIB), fieldName, primName, fargs, fret, pos);
		//trace(primName + ": " + fargs + " ret: " + fret);
		result.push(prim);
	}
	
	function processForwardField(inField : Field, inParams : Map<String, Dynamic>, ?isSetter : Bool = false) : Void
	{
		var pos = inField.pos;
		
		switch (inField.kind)
		{
			case FFun(func):
				assureMetadataParams(inParams, [LIB], pos);
				
				var primName : String = getPrimName(inParams, inField.name);
				var retType = nonNullType(func.ret);
				var argTypes = new Array<ComplexType>(); 
				var argNames = new Array<Expr>();
				mergeArgs(inParams.get(PARAMS), func.args, pos, argNames, argTypes);
				
				var prim : Field = createPrim(inParams.get(LIB), primName, primName, argTypes, retType, pos);
				result.push(prim);
				
				//trace(primName + ": " + func.expr);
				func.expr = createPrimCall(primName, argNames, retType, pos, isSetter);
				//trace(primName + ": " + func.expr);
				result.push(inField);
			
			default:
				throw new Error("ndll_forward: It must be a function expression", pos);
		}
	}
	
	function processPropertyField(inField : Field, inParams : Map<String, Dynamic>) : Void
	{
		var pos = inField.pos;
		
		switch (inField.kind)
		{
			case FProp(get, set, type, block):
				
				var fieldParams = new Map<String, Dynamic>();
				mergeMetadataParams(fieldParams, inParams);
				var name : Null<String> = fieldParams.get(NAME);
				
				var getter : Null<Field>;
				
				if (!hasField(get))
				{
					getter = createAccessor(get, type, inField, inParams);
					if (getter != null)
					{
						if (name != null)
							fieldParams.set(NAME, "get_" + name);
						
						processForwardField(getter, fieldParams);
					}
				}
				
				var setter : Null<Field>;
				if (!hasField(get))
				{
					setter = createAccessor(set, type, inField, inParams, true);
					if (setter != null)
					{
						if (name != null)
							fieldParams.set(NAME, "set_" + name);
						
						processForwardField(setter, fieldParams, true);
					}
				}
				
				if (getter != null)
					get = getter.name;
				if (setter != null)
					set = setter.name;
					
				inField.kind = FProp(get, set, type, block);
				result.push(inField);
			
			default:
				throw new Error("ndll_prop: It must be a property expression", pos);
		}
	}
	
	function hasField(inName : String) : Bool
	{
		for (field in fields)
		{
			if (field.name == inName)
				return true;
		}
		return false;
	}
	
	static function createAccessor(name : String, type : ComplexType, inField : Field, inParams : Map<String, Dynamic>, isSetter : Bool = false) : Null<Field>
	{
		if (name == "null" || name == "never")
			return null;
		
		var prefix : String = isSetter ? "set_" : "get_";
			
		if (name == "default")
			name = prefix + inField.name;
			
		//trace("accessor: " + name);
		var fargs : Array<FunctionArg> = [];
		if (isSetter)
			fargs.push( { name: "value", type: type, opt: false } );
		
		var field : Field = { 
			name: name, 
			access: [APrivate], 
			kind: FFun( { args: fargs, ret: type, expr: null, params: [] } ), 
			pos: inField.pos 
		};
		
		return field;
	}
	
	static function createPrim (lib : String, fname : String, prim : String, fargs : Array<ComplexType>, fret : ComplexType, pos : Position) : Field
	{
		function _e(ed : ExprDef) : Expr { return { expr: ed, pos: pos }; }
		function _cs(s : String) : Expr { return _e( EConst(CString(s)) ); }
		
		if (fret == null)
			fret = VOID();
			
		var argLen = fargs.length;
		if (argLen > 5)
			argLen = -1; 
		
		return {
			name: fname,
			access: [AStatic, APrivate],
			pos: pos,
			kind: FVar(
				TFunction(fargs, fret),
				_e(	ECall(
					macro $p{[target, "Lib", "load"]},
					[ _cs(lib), _cs(prim), Context.makeExpr(argLen, pos) ]
				))
			)
		}
	}
	
	static function createPrimCall(fname : String, fargs : Array<Expr>, fret : ComplexType, pos : Position, isSetter : Bool) : Expr
	{
		function _e(ed : ExprDef) : Expr return { expr: ed, pos: pos }; 
		function _eId(s : String) : Expr return _e(EConst(CIdent(s)));
		function _eRet(exp : Expr) : Expr return _e(EReturn(exp));
		
		var primCall : Expr = _e( ECall( _eId(fname), fargs ) );
		//trace(fname + ": " + fret);
		switch (fret)
		{
			case TPath(p):
				if (p.name == "Void")
					return primCall;
			default:
		}
		
		if (isSetter)
			return _e ( EBlock([ primCall, _eRet(_eId("value")) ]) );
		
		return _eRet(primCall);
	}
	
	static function getMetadataParams(meta : MetadataDef, processors : Map<String, Expr->Dynamic>) : Map<String, Dynamic>
	{
		var result = new Map<String, Dynamic>();
		var proc : Expr->Dynamic;
		var key : String;
		var value : Dynamic;
		
		for (e in meta.params)
		{
			switch (e.expr)
			{
				case EBinop(bop, lv, rv):
					
					key = getId(lv);
					if (key != null)
						proc = processors.get(key);
					if (bop == OpAssign && proc != null)
					{
						value = proc(rv);
						result.set(key, value);
					}
					if (value == null)
						throw new Error("Invalid expression.", meta.pos);
				default:
			}
		}
		
		return result;
	}
		
	static function mergeMetadataParams(params : Map<String, Dynamic>, defaultParams : Map<String, Dynamic>) : Map<String, Dynamic>
	{
		for (key in defaultParams.keys())
		{
			if (!params.exists(key))
				params.set(key, defaultParams.get(key));
		}
		
		return params;
	}
	
	static function assureMetadataParams(params : Map<String, Dynamic>, keys : Array<String>, pos : Position) : Void
	{
		for (key in keys)
		{
			if (!params.exists(key))
				throw new Error("NdllForward: You must specify a valid '" + key + "' value", pos);
		}
	}
	
	static function getStr(expr : Expr) : Null<String>
	{
		if (expr == null)
			return null;
		
		return switch (expr.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CString(s):
						s;
					default:
						null;
				}
			default:
				null;
		}
	}
	
	static function getInt(expr : Expr) : Null<Int>
	{
		if (expr == null)
			return null;
		
		return switch (expr.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CInt(i):
						Std.parseInt(i);
					default:
						null;
				}
			default:
				null;
		}
	}
	
	static function getId(expr : Expr) : Null<String>
	{
		if (expr == null)
			return null;
		
		return switch (expr.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CIdent(s):
						s;
					default:
						null;
				}
			default:
				null;
		}
	}
	
	static function getBool(expr : Expr) : Null<Bool>
	{
		if (expr == null)
			return null;
		
		return switch (expr.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CIdent(s):
						s == "true";
					default:
						null;
				}
			default:
				null;
		}
	}
	
	static function getExprs(expr : Expr) : Array<Expr>
	{
		return switch (expr.expr)
		{
			case EArrayDecl(a):
				a;
			default:
				[];
		}
		
	}
	
	static function getIds(expr : Expr) : Array<String>
	{
		var result = new Array<String>();
		
		switch (expr.expr)
		{
			case EArrayDecl(arr):
				for (e in arr) switch (e.expr)
				{
					case EConst(c):
						switch(c)
						{
							case CIdent(s):
								result.push(s);
							default:
								throw new Error("Ndll: Parameter must be an identifier", e.pos);
						}
					default:
				}
			default:
		}
		
		return result;
	}
	
	function getPrimName(inParams : Map<String, Dynamic>, inFieldName : String) : String
	{
		var prefix : String = inParams.get(PREFIX);
		if (prefix == "")
		{
			var clazz : ClassType = classRef.get();
			prefix = clazz.pack.join("_") + camel2underScore(clazz.name) + "_";
			trace("using prefix: " + prefix);
		}
		var name : String = inParams.get(NAME);
		if (name == null)
			name = camel2underScore(inFieldName);
		
		//trace("prim: " + prefix + name);
		return prefix + name;
	}
	
	static function camel2underScore(inStr : String) : String
	{
		var buf = new StringBuf();
		var cur : String;
		var char : String;
		for (i in 0...inStr.length)
		{
			cur = inStr.charAt(i);
			char = cur.toLowerCase();
			if (char != cur)
				buf.add("_");
			buf.add(char);
		}
		return buf.toString();
	}
	
	static function getArgTypes(fargs : Array<FunctionArg>) : Array<ComplexType>
	{
		var result : Array<ComplexType> = new Array<ComplexType>();
		
		for (a in fargs)
			result.push(a.type);
		
		return result;
	}
	
	static function nonNullType(?type : ComplexType) : ComplexType
	{
		return if (type != null) type else VOID();
	}
	
	static function mergeArgs(params : Array<Expr>, fargs : Array<FunctionArg>, pos : Position, outArgNames : Array<Expr>, outArgTypes : Array<ComplexType>) : Void
	{
		var ended = false;
		var it = fargs.iterator();
		for (e in params)
		{
			if (TypeTool.enumEq( e.expr, WILDCARD() ))
			{
				splitFunctionArg(it, pos, outArgNames, outArgTypes);
			}
			else if (TypeTool.enumEq( e.expr, END() ))
			{
				ended = true;
				break;
			}
			else 
			{
				outArgNames.push(e);
				outArgTypes.push(DYNAMIC());
			}
		}
		
		if (!ended)
		{
			while (it.hasNext())
			{
				splitFunctionArg(it, pos, outArgNames, outArgTypes);
			}
		}
	}
	
	static function splitFunctionArg(it : Iterator<FunctionArg>, pos : Position, outArgNames : Array<Expr>, outArgTypes : Array<ComplexType>) : Void
	{
		if (it.hasNext())
		{
			var a : FunctionArg = it.next();
			outArgNames.push( { expr: EConst(CIdent(a.name)), pos: pos } );
			outArgTypes.push( a.type );
		}
		else
		{
			outArgNames.push( { expr: NULL(), pos: pos } );
			outArgTypes.push( DYNAMIC() );
		}
	}
	
	function setupDefaultMetadataParams() : Void
	{
		for (m in classType.meta.get())
		{
			switch(m.name)
			{
				case ":ndll_use", ":ndll":
					defaultParams = getMetadataParams(m, defaultMetadataParamsProcessors);
					if (!defaultParams.exists(PREFIX)) defaultParams.set(PREFIX, ""); 
					if (!defaultParams.exists(PARAMS)) defaultParams.set(PARAMS, []);
					return;
			}
		}
	}
	
	static function getMetadataType(meta : Metadata) : MetadataType
	{
		for (m in meta)
		{
			switch(m.name)
			{
				case ":ndll":
					return MInfer(getMetadataParams(m, metadataParamsProcessors));
				case ":ndll_import":
					return MImport(getMetadataParams(m, metadataParamsProcessors));
				case ":ndll_forward":
					return MForward(getMetadataParams(m, metadataParamsProcessors));
				case ":ndll_prop":
					return MProperty(getMetadataParams(m, metadataParamsProcessors));
			}
		}
		return MNull;
	}
	
	static function isStatic(field : Field) : Bool
	{
		for (a in field.access)
		{
			switch (a)
			{
				case AStatic:
					return true;
				default:
			}
		}
		return false;
	}
}

typedef MetadataDef = { pos : Position, params : Array<Expr>, name : String };
typedef ClassRef = { t : Ref<ClassType>, params : Array<Type> };

enum MetadataType {
	MImport(params : Map<String, Dynamic>);
	MForward(params : Map<String, Dynamic>);
	MProperty(params : Map<String, Dynamic>);
	MInfer(params : Map<String, Dynamic>);
	MNull;
}

#end