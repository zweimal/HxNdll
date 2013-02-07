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
 * The base class for most hxndll objects
 * @author German Allemand
 */
class ObjectBase implements Importer
{
	private function new() 
	{
	}
	
	inline public function isActive() : Bool
	{
		return __cObj != null;
	}
	
	inline public function isInactive() : Bool
	{
		return __cObj == null;
	}
	
	private var __cObj : Dynamic;
}

