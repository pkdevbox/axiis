package org.axiis.core
{
	import com.degrafa.geometry.Geometry;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import mx.core.FlexSprite;
	import mx.events.PropertyChangeEvent;
	
	import org.axiis.states.State;

	public class AxiisSprite extends FlexSprite
	{
		public function AxiisSprite()
		{
			super();
		}
		
		private var eventListeners:Array = [];
	
		private var watchingForModifications:Boolean = false;
	
		public var revertingModifications:Array = [];
		
		private var activeStates:Array = [];
		
		public var data:Object;
		
		public var layout:ILayout;
		
		public var bounds:Rectangle;
		
		public var geometries:Array = [];
		
		public var scaleFill:Boolean = true;
		
		public function get layoutSprites():Array
		{
			return _layoutSprites;
		}
		private var _layoutSprites:Array= [];
		
		public function get drawingSprites():Array
		{
			return _drawingSprites;
		}
		private var _drawingSprites:Array= [];
		
		public function set states(value:Array):void
		{
			if(value != _states)
			{
				_states = value;
				
				// Add listeners for all the state changing events
				for each(var state:State in states)
				{
					if(state.enterStateEvent != null)
						addEventListener(state.enterStateEvent,handleStateTriggeringEvent);
					if(state.exitStateEvent != null)
						addEventListener(state.exitStateEvent,handleStateTriggeringEvent);
				}
			}
		}
		public function get states():Array
		{
			return _states;
		}
		private var _states:Array = [];
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void {
			var obj:Object=new Object();
			obj.type=type;
			obj.listener=listener;
			obj.useCapture=useCapture;
			
			super.addEventListener(type,listener,useCapture,priority,useWeakReference);
		}
		
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void {
			for (var i:int=0;i<eventListeners.length;i++) {
				if (eventListeners[i].type==type && eventListeners.listener==listener) {
					eventListeners.splice(i,1);
					i=eventListeners.length;
				}
			}
			super.removeEventListener(type,listener,useCapture);
		}
		
		public function addLayoutSprite(aSprite:AxiisSprite):void {
			if (!this.contains(aSprite)) {
				_layoutSprites.push(aSprite);
				addChild(aSprite);
			}
		}
		
		public function addDrawingSprite(aSprite:AxiisSprite):void {
			if (!this.contains(aSprite)) {
				_drawingSprites.push(aSprite);
				addChild(aSprite);
			}
		}
		
		override public function removeChild(child:DisplayObject):DisplayObject {
			for (var i:int=0;i<_layoutSprites.length;i++) {
				if (child==_layoutSprites[i]) {
					_layoutSprites.splice(i,1);
					continue;
				}
			}
			for (var j:int=0;j<_drawingSprites.length;j++) {
				if (child==_drawingSprites[j]) {
					_drawingSprites.splice(j,1);
					continue;
				}
			}
			if (child)
				super.removeChild(child);
			return child;
		}
		
		public function clearModifications():void
		{
			revertingModifications = [];
		}
	
		
		protected function handleStateTriggeringEvent(event:Event):void
		{
			if(event.target != this)
				return;	
			
			activeStates = findStatesForEventType(event.type);
			setActiveStatesForAncestors(activeStates);
			render();
			setActiveStatesForDescendents(activeStates);
		}
		
		protected function findStatesForEventType(eventType:String):Array
		{
			var toReturn:Array = [];
			for each(var state:State in states)
			{
				if(state.enterStateEvent == eventType)
					toReturn.push(state);
			}
			return toReturn;
		}
		
		protected function setActiveStatesForAncestors(states:Array):void
		{
			if(parent is AxiisSprite)
			{
				AxiisSprite(parent).activeStates = states;
				AxiisSprite(parent).setActiveStatesForAncestors(states);
				AxiisSprite(parent).render();
			}
		}
		
		protected function setActiveStatesForDescendents(states:Array):void
		{	
			for(var a:int = 0; a < numChildren; a++)
			{
				var currChild:DisplayObject = getChildAt(a);
				if(currChild is AxiisSprite)
				{
					AxiisSprite(currChild).activeStates = states;
					AxiisSprite(currChild).setActiveStatesForDescendents(states);
					AxiisSprite(currChild).render();
				}
			}
		}
		
		public function render():void
		{
			//if(revertingModifications.length > 0)
			//	trace();
			

			for each(var modification:PropertySetter in revertingModifications)
			{
				modification.apply();
			}
		
			
			for each(var activeState:State in activeStates)
			{
				activeState.apply();
			}
			
			graphics.clear();
			for each(var geometry:Geometry in geometries)
			{
				geometry.preDraw();
				var drawingBounds:Rectangle = scaleFill
						? new Rectangle(bounds.x+geometry.x, bounds.y+geometry.y,bounds.width,bounds.height)
						: geometry.commandStack.bounds;
				geometry.draw(graphics,drawingBounds);
			}
			
			for each(activeState in activeStates)
			{
				activeState.remove();
			}
		}
		
		public function dispose():void
		{
			graphics.clear();
			
			while (numChildren > 0)
			{
				var s:AxiisSprite= getChildAt(0) as AxiisSprite;
				s.dispose();
				s.graphics.clear();
				removeChild(s);
			}
			
			for each (var obj:Object in eventListeners)
			{
				super.removeEventListener(obj.type, obj.listener,obj.useCapture);
			}
			states = null;
			revertingModifications = null;
		}
	}
}
