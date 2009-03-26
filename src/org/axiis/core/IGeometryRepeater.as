package org.axiis.core
{
	import com.degrafa.geometry.Geometry;
	
	public interface IGeometryRepeater
	{
		function get geometry():Geometry;
		function set geometry(value:Geometry):void;
		
		function get modifiers():Array;
		function set modifiers(value:Array):void;

		function get dataProvider():Array; 
		function set dataProvider(value:Array):void;
		
		function get currentIteration():int;
		
		function get cachedValues():Array;
		
		function repeat(preIterationCallback:Function = null, postIterationCallBack:Function=null):void;
		
		function applyIteration(iteration:int, values:Array=null):void;
	}
}