package
{
    import flash.display.Sprite;
    import flash.ui.Keyboard;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    //import flash.geom.Matrix3D;
    import org.papervision3d.core.math.Matrix3D;
    import flash.geom.Vector3D;
    import flash.geom.Point;

    import jiglib.cof.JConfig;
    import jiglib.geometry.*;
    import jiglib.math.*;
    import jiglib.physics.*;
    import jiglib.physics.constraint.*;
    import jiglib.plugin.papervision3d.*;
    
    import org.papervision3d.cameras.CameraType;
    import org.papervision3d.core.geom.renderables.Vertex3D;
    import org.papervision3d.core.math.Number3D;
    import org.papervision3d.core.math.Plane3D;
    import org.papervision3d.core.utils.Mouse3D;
    import org.papervision3d.events.*;
    import org.papervision3d.lights.PointLight3D;
    import org.papervision3d.materials.shadematerials.*;
    import org.papervision3d.materials.utils.MaterialsList;
    import org.papervision3d.objects.DisplayObject3D;
    import org.papervision3d.objects.primitives.*;
    import org.papervision3d.render.QuadrantRenderEngine;
    import org.papervision3d.view.BasicView;
    import org.papervision3d.view.layer.ViewportLayer;
    import org.papervision3d.view.layer.util.ViewportLayerSortMode;
    import org.papervision3d.view.stats.StatsView;

    
    [SWF(width="760", height="600", backgroundColor="#ffffff", frameRate="30")]
    public class Flash3DPhysics extends Sprite
    {
        public var view:BasicView;
	public var mdp:Point = new Point(); // mouse down point
	public var dragPoint:Point = new Point();
	public var bgClicked:Boolean = false;
	public var background:Sprite;
	public var shift:Boolean;


	private var mylight:PointLight3D;
	private var mouse3D:Mouse3D;
	private var shadeMateria:FlatShadeMaterial;
	
	private var ground:RigidBody;
	private var ballBody:Vector.<RigidBody>;
	private var boxBody:Vector.<RigidBody>;
	private var capsuleBody:Vector.<RigidBody>;
	
	private var onDraging:Boolean = false;
	
	private var currDragBody:RigidBody;
	private var dragConstraint:JConstraintWorldPoint;
	private var startMousePos:Vector3D;
	private var planeToDragOn:Plane3D;
	
	private var keyRight   :Boolean = false;
	private var keyLeft    :Boolean = false;
	private var keyForward :Boolean = false;
	private var keyReverse :Boolean = false;
	private var keyUp:Boolean = false;
	
	private var physics:Papervision3DPhysics;
	
	public function Flash3DPhysics()
	{
	    background = new Sprite();
	    background.graphics.beginFill(0xddd,1);
	    background.graphics.drawRect(0,0,760,600);
	    background.graphics.endFill();
	    addChild(background);

	    //super(800, 600, true, true, CameraType.TARGET);
	    
	    init3D();
	}

	private function init3D():void
	{
            view = new BasicView(760,600, true, true, CameraType.TARGET);
	    view.camera.z = -100;
	    view.buttonMode = true;
	    //view.renderer = new QuadrantRenderEngine(QuadrantRenderEngine.CORRECT_Z_FILTER);

	    // var rubik:PileUp = new PileUp();
	    // view.scene.addChild(rubik);
	    
	    this.addChild(view);
	    this.addEventListener(Event.ENTER_FRAME, onEventRender3D);
	    stage.addEventListener( KeyboardEvent.KEY_DOWN, keyDownHandler);
	    stage.addEventListener( KeyboardEvent.KEY_UP, keyUpHandler);
	    // stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseRelease);
	    // stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);

	    stage.addEventListener(MouseEvent.MOUSE_DOWN, startRotation);




	    JConfig.numContactIterations = 12;
	    physics = new Papervision3DPhysics(view.scene, 8);
	    
	    Mouse3D.enabled = true;
	    mouse3D = view.viewport.interactiveSceneManager.mouse3D;
	    view.viewport.containerSprite.sortMode = ViewportLayerSortMode.INDEX_SORT;
	    
	    mylight = new PointLight3D(true, true);
	    mylight.y = 300;
	    mylight.z = -400;
	    
	    shadeMateria = new FlatShadeMaterial(mylight, 0x77ee77);
	    var materiaList :MaterialsList = new MaterialsList();
	    materiaList.addMaterial(shadeMateria, "all");
	    
	    ground = physics.createCube(materiaList, 500, 500, 10);
	    ground.movable = false;
	    //ground.friction = 0.9;
	    ground.restitution = 0.8;
	    view.viewport.getChildLayer(physics.getMesh(ground)).layerIndex = 1;

	    var vplObjects:ViewportLayer = new ViewportLayer(view.viewport,null);
	    vplObjects.layerIndex = 2;
	    vplObjects.sortMode = ViewportLayerSortMode.Z_SORT;
	    view.viewport.containerSprite.addLayer(vplObjects);
	    
	    ballBody = new Vector.<RigidBody>();
	    var color:uint;
	    for (var i:int = 0; i < 6; i++)
	    {
		color = (i == 0)?0xff8888:0xeeee00;
		shadeMateria = new FlatShadeMaterial(mylight, color);
		shadeMateria.interactive = true;
		ballBody[i] = physics.createSphere(shadeMateria, 22);
		physics.getMesh(ballBody[i]).addEventListener(InteractiveScene3DEvent.OBJECT_PRESS, handleMousePress);
		ballBody[i].mass = 3;
		ballBody[i].moveTo(new Vector3D( -200, 30 + (50 * i + 50), -100));
		vplObjects.addDisplayObject3D(physics.getMesh(ballBody[i]));
	    }
	    
	    shadeMateria = new FlatShadeMaterial(mylight,0xff0000);
	    shadeMateria.interactive = true;
	    materiaList = new MaterialsList();
	    materiaList.addMaterial(shadeMateria,"all");
	    boxBody=new Vector.<RigidBody>();

	    for (i = 0; i < 6; i++)
	    {
		boxBody[i] = physics.createCube(materiaList, 50, 150, 30);
		physics.getMesh(boxBody[i]).addEventListener(InteractiveScene3DEvent.OBJECT_PRESS, handleMousePress);
		boxBody[i].moveTo(new Vector3D(0, 10 + (40 * i + 40), 0));
		vplObjects.addDisplayObject3D(physics.getMesh(boxBody[i]));
	    }

	    view.camera.y = mylight.y;
	    view.camera.z = mylight.z;
	    
	    var stats:StatsView = new StatsView(view.renderer);
	    addChild(stats);
	    
	    view.startRendering();
	}
	
	private function findSkinBody(skin:DisplayObject3D):int
	{
	    for (var i:String in PhysicsSystem.getInstance().bodies)
	    {
		if (skin == physics.getMesh(PhysicsSystem.getInstance().bodies[i]))
		{
		    return int(i);
		}
	    }
	    return -1;
	}
	
	private function handleMousePress(event:InteractiveScene3DEvent):void
	{
	    onDraging = true;
	    startMousePos = new Vector3D(mouse3D.x, mouse3D.y, mouse3D.z);
	    currDragBody = PhysicsSystem.getInstance().bodies[findSkinBody(event.displayObject3D)];
	    planeToDragOn = new Plane3D(new Number3D(0, 0, -1), new Number3D(0, 0, -startMousePos.z));
	    
	    var bodyPoint:Vector3D = startMousePos.subtract(currDragBody.currentState.position);
	    dragConstraint = new JConstraintWorldPoint(currDragBody, bodyPoint, startMousePos);
	    PhysicsSystem.getInstance().addConstraint(dragConstraint);
	}
	
	private function handleMouseMove(event:MouseEvent):void
	{
	    if (onDraging)
	    {
		var ray:Number3D = view.camera.unproject(view.viewport.containerSprite.mouseX, view.viewport.containerSprite.mouseY);
		ray = Number3D.add(ray, new Number3D(view.camera.x, view.camera.y, view.camera.z));
		
		var cameraVertex3D:Vertex3D = new Vertex3D(view.camera.x, view.camera.y, view.camera.z);
		var rayVertex3D:Vertex3D = new Vertex3D(ray.x, ray.y, ray.z);
		var intersectPoint:Vertex3D = planeToDragOn.getIntersectionLine(cameraVertex3D, rayVertex3D);
		
		dragConstraint.worldPosition = new Vector3D(intersectPoint.x, intersectPoint.y, intersectPoint.z);
	    }
	}

	private function handleMouseRelease(event:MouseEvent):void
	{
	    if (onDraging)
	    {
		onDraging = false;
		PhysicsSystem.getInstance().removeConstraint(dragConstraint);
		currDragBody.setActive();
	    }
	}

	private function keyDownHandler(event:KeyboardEvent):void
	{
	    switch(event.keyCode)
	    {
		case Keyboard.UP:
		keyForward = true;
		keyReverse = false;
		break;

		case Keyboard.DOWN:
		keyReverse = true;
		keyForward = false;
		break;

		case Keyboard.LEFT:
		keyLeft = true;
		keyRight = false;
		break;

		case Keyboard.RIGHT:
		keyRight = true;
		keyLeft = false;
		break;
		case Keyboard.SPACE:
		keyUp = true;
		break;
	    }
	}
	
	private function keyUpHandler(event:KeyboardEvent):void
	{
	    switch(event.keyCode)
	    {
		case Keyboard.UP:
		keyForward = false;
		break;

		case Keyboard.DOWN:
		keyReverse = false;
		break;

		case Keyboard.LEFT:
		keyLeft = false;
		break;

		case Keyboard.RIGHT:
		keyRight = false;
		break;
		case Keyboard.SPACE:
		keyUp=false;
	    }
	}
	
	private function resetBox():void
	{
	    for (var i:int = 0; i < ballBody.length;i++ )
	    {
		if (ballBody[i].currentState.position.y < -200)
		{
		    ballBody[i].moveTo(new Vector3D( 0, 1000 + (60 * i + 60), 0));
		}
	    }
	    
	    for (i = 0; i < boxBody.length;i++ )
	    {
		if (boxBody[i].currentState.position.y < -200)
		{
		    boxBody[i].moveTo(new Vector3D(0, 1000 + (60 * i + 60), 0));
		}
	    }
	}
	
	private function testFreezeObject():void {
	    var _body:RigidBody;
	    for (var i:int = 0; i < ballBody.length; i++ )
	    {
		_body = ballBody[i];
		if (_body.isActive)
		{
		    shadeMateria = (i == 0)? new FlatShadeMaterial(mylight, 0xff8888):new FlatShadeMaterial(mylight, 0xeeee00);
		    shadeMateria.interactive = true;
		    physics.getMesh(_body).material = shadeMateria;
		}
		else
		{
		    shadeMateria = new FlatShadeMaterial(mylight, 0xff7777);
		    shadeMateria.interactive = true;
		    physics.getMesh(_body).material = shadeMateria;
		}
	    }
	    
	    for each (_body in boxBody)
	    {
		if (_body.isActive)
		{
		    shadeMateria = new FlatShadeMaterial(mylight, 0xeeee00);
		    shadeMateria.interactive = true;
		    physics.getMesh(_body).material = shadeMateria;
		}
		else
		{
		    shadeMateria = new FlatShadeMaterial(mylight, 0xff7777);
		    shadeMateria.interactive = true;
		    physics.getMesh(_body).material = shadeMateria;
		}
	    }
	    // for each (_body in capsuleBody)
	    // {
	    // 	if (_body.isActive)
	    // 	{
	    // 		shadeMateria = new FlatShadeMaterial(mylight, 0xeeee00);
	    // 		shadeMateria.interactive = true;
	    // 		physics.getMesh(_body).material = shadeMateria;
	    // 	}
	    // 	else
	    // 	{
	    // 		shadeMateria = new FlatShadeMaterial(mylight, 0xff7777);
	    // 		shadeMateria.interactive = true;
	    // 		physics.getMesh(_body).material = shadeMateria;
	    // 	}
	    // }
	}

        protected var c_pitch:Number = 50;
        protected var c_yam:Number = 100;
	protected function onEventRender3D(event:Event = null):void {
	    if(keyLeft)
	    {
                c_yam += 1;
                // view.cameraAsCamera3D.orbit(c_pitch, c_yam);			
		ballBody[0].addWorldForce(new Vector3D(-60,0,0),ballBody[0].currentState.position);
	    }
	    if(keyRight)
	    {
                c_yam -= 1;
                // view.cameraAsCamera3D.orbit(c_pitch, c_yam);			
		ballBody[0].addWorldForce(new Vector3D(60,0,0),ballBody[0].currentState.position);
	    }
	    if(keyForward)
	    {
                c_pitch += 1;
                // view.cameraAsCamera3D.orbit(c_pitch, c_yam);			
		ballBody[0].addWorldForce(new Vector3D(0,0,60),ballBody[0].currentState.position);
	    }
	    if(keyReverse)
	    {
                c_pitch -= 1;
                // view.cameraAsCamera3D.orbit(c_pitch, c_yam);			
		ballBody[0].addWorldForce(new Vector3D(0,0,-60),ballBody[0].currentState.position);
	    }
	    if(keyUp)
	    {
		ballBody[0].addWorldForce(new Vector3D(0, 60, 0), ballBody[0].currentState.position);
	    }
	    
	    //physics.step();//dynamic timeStep
	    physics.engine.integrate(0.1);//static timeStep
	    resetBox();
	    //testFreezeObject();
            view.singleRender();
	    //super.onRenderTick(event);
	}

        private function startRotation(event:MouseEvent):void
        {
	    bgClicked = event.target == background;
	    
	    stage.addEventListener(MouseEvent.MOUSE_UP, endDrag);
	    stage.addEventListener(Event.MOUSE_LEAVE, endDrag);
	    stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove);
	    
	    mdp.x = mouseX;
	    mdp.y = mouseY;
	    onMove();
        }
        
        public function endDrag(event:Event = null):void
        {
	    stage.removeEventListener(MouseEvent.MOUSE_UP, endDrag);
	    stage.removeEventListener(Event.MOUSE_LEAVE, endDrag);
	    stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
        }
        
        public function onMove(event:Event=null):void
        {
	    if(bgClicked)
	    {
	        var m:Matrix3D;
	        if(!shift)
	        {
		    m = Matrix3D.rotationY((mouseX - mdp.x)/150);
		    m = Matrix3D.multiply(m, Matrix3D.rotationX(-(mouseY - mdp.y)/150));
	        }
	        else
	        {
		    var rot:Number = (mouseX < 233)? (mouseY - mdp.y)/150 : (mdp.y - mouseY)/150;
		    rot += (mouseY > 233)? (mouseX - mdp.x)/150 : (mdp.x - mouseX)/150;
		    m = Matrix3D.rotationZ(rot);
	        }
	        
	        view.camera.transform = Matrix3D.multiply(m, view.camera.transform);
	        mylight.transform = Matrix3D.multiply(m, mylight.transform);
	        
	        mdp.x = mouseX;
	        mdp.y = mouseY;
	    }
	    else
	    {
	        // dragPoint.x = mouseX;
	        // dragPoint.y = mouseY;
	        
	        // if(Point.distance(mdp, dragPoint) > 10)
	        // {
		    //     var n:Number3D = MyUtils.transformNumber(new Number3D(mdp.x - dragPoint.x, dragPoint.y - mdp.y, 0), Matrix3D.inverse(rubik.transform));
		    //     n = Number3D.cross(n, rubik.selSide);
		    
		    //     var axis:String = 'x';
		    //     var largest:Number = Math.abs(n.x);
		    
		    //     if(Math.abs(n.y) > largest)
		    //     {
		        //         largest = Math.abs(n.y);
		        //         axis = 'y';
		        //     }
		    //     if(Math.abs(n.z) > largest)
		    //     {
		        //         largest = Math.abs(n.z);
		        //         axis = 'z';
		        //     }
		    
		    //     rubik.move(axis, Math.round(n[axis]/largest));
		    
		    //     endDrag();
	            // }
	    }
        }
        
        
    }
}

import org.papervision3d.core.math.Matrix3D;
import org.papervision3d.core.math.Number3D;
import org.papervision3d.materials.ColorMaterial;
import org.papervision3d.materials.MovieMaterial;
import org.papervision3d.materials.utils.MaterialsList;
import org.papervision3d.objects.DisplayObject3D;
import org.papervision3d.objects.primitives.Cube;

class PileUp extends DisplayObject3D
{
    private var miniCubes:Vector.<MiniCube> = new Vector.<MiniCube>();

    public function PileUp()
    {
        createCube();
    }

    public function createCube():void
    {
        var cube:MiniCube;
	for(var i:int = 0; i<7; i++)
	{
	    for(var j:int = 0; j<3; j++)
	    {
		for(var k:int = 0; k<3; k++)
		{
		    cube = new MiniCube(k,j,i);
		    //cube.addEventListener(MouseEvent.MOUSE_DOWN, onCubeSelected);
		    
		    miniCubes.push(cube);
		    addChild(cube);
		}
	    }
	}
	name = "rubik";
    }

}

class MiniCube extends DisplayObject3D
{
    public var cube:Cube;
    private var width:Number = 50;
    private var height:Number = 36;
    public function MiniCube(level:int, sn:int, t:int)
    {
	var matList:Object;
        if (t == 0) matList = {all: new ColorMaterial(0xD80505, 1, true)};
        if (t == 1) matList = {all: new ColorMaterial(0xFF9900, 1, true)};
        if (t == 2) matList = {all: new ColorMaterial(0x000000, 1, true)};
	
        if (level % 2 == 0 ) 
        {
            cube = new Cube(new MaterialsList(matList), width * 3, width, height);
            cube.x = (width) * sn + 1;
            cube.z = 0;
        }
        else 
        {
            cube = new Cube(new MaterialsList(matList), width, width * 3, height);
            cube.x = 0;
            cube.z = (width) * sn + 1;
        }
	addChild(cube);
	
	name = "MC" + level + sn;
	cube.y = (level) * height + 1;
    }
}
