package;
 
/**
 *
 * Sample: Fixed Dragging
 * Author: Luca Deltodesco
 *
 * Demonstrating how one might perform a Nape simulation
 * that uses a fixed-time step for better reproducibility.
 * Also demonstrate how to use a PivotJoint for dragging
 * of Nape physics objects.
 *
 */
 
import js.Browser;
import js.html.Document;
import js.html.Window;
import js.html.Event;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.CanvasElement;
import js.html.BodyElement;
import js.html.CanvasRenderingContext2D;


import haxe.Timer;
import nape.constraint.PivotJoint;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.space.Space;
import nape.util.BitmapDebug;
import nape.util.Debug;
 
class FixedDragging {
    
    static var instance:FixedDragging;

    var i:Int;
    var currentBodyIndex:Int;
    var playerBodyIndex:Int;
    var directed:Bool;
    var log:Int;
    var space:Space;
    var debug:Debug;
    var window:Window;
    var document:Document;
    var body:BodyElement;
    var canvas:CanvasElement;
    var ctx:CanvasRenderingContext2D;
    var debugBodiesPosition:String;

    var handJoint:PivotJoint;
 
    var prevTimeMS:Int;
    var simulationTime:Float;
    var mouseX:Int;
    var mouseY:Int;

    var preserveComma:Bool;
    
    function documentOnload(x):Void{
        // trace(window.document.children[0]);
        // if(window.document.children[0].children[2] != null){
        // window.fd = instance;
        var debugBodiesPositionDiv = window.document.createElement('div');
        debugBodiesPositionDiv.style.display = 'none';
        debugBodiesPositionDiv.id = 'b_position';
        window.document.children[0].children[1].appendChild(debugBodiesPositionDiv);
        window.document.children[0].children[1].appendChild(canvas);
        window.document.onkeydown = keyDownHandler;
        // window.document.children[0].children[1].onmousedown = mouseDownHandler;
        // window.document.children[0].children[1].onmouseup = mouseUpHandler;
        // window.document.children[0].children[1].onmousemove = mouseMoveHandler;
        // trace(window.document.children[0].children[1]);
        // }
    }

    function new() {
        i = 0;
        log = 0;
        currentBodyIndex = 0;
        playerBodyIndex = 70;
        preserveComma = true;
        document = Browser.document;
        // trace(document.children[0].children[1]);
        window = Browser.window;
        // trace(window);
        document.onreadystatechange = documentOnload;
        //body = cast document.createElement('body');
        //document.appendChild(body);
               
        window.requestAnimationFrame(enterFrameHandler);
        canvas = cast document.createElement('canvas');
        canvas.style.display = 'none';
        canvas.width = 1024;
        canvas.height = 700;
        ctx = canvas.getContext('2d');
        
        //body.appendChild(canvas);
        
        // trace(ctx);
        initialise(null);
    }
 
    function initialise(ev:Event):Void {
        // if (ev != null) {
        //     removeEventListener(Event.ADDED_TO_STAGE, initialise);
        // }
 
        // Create a new simulation Space.
        //
        //   Default gravity is (0, 0)
        space = new Space();
 
        // Create a new BitmapDebug screen matching stage dimensions and
        // background colour.
        //
        //   The Debug object itself is not a DisplayObject, we add its
        //   display property to the display list.
        //
        //   We additionally set the flag enabling drawing of constraints
        //   when rendering a Space object to true.
        // debug = new BitmapDebug(stage.stageWidth, stage.stageHeight, stage.color);
        // addChild(debug.display);
        // debug.drawConstraints = true;
 
        setUp();
        
        // stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
    }
 
    function setUp():Void {
        var w = 1024;
        var h = 700;
 
        // Create a static border around stage.
        var border = new Body(BodyType.STATIC);
        border.shapes.add(new Polygon(Polygon.rect(0, 0, w, -1)));
        border.shapes.add(new Polygon(Polygon.rect(0, h, w, 1)));
        border.shapes.add(new Polygon(Polygon.rect(0, 0, -1, h)));
        border.shapes.add(new Polygon(Polygon.rect(w, 0, 1, h)));
        border.space = space;
 
        // Generate some random objects!
        for (i in 0...64) {
            var body = new Body();
 
            // Add random one of either a Circle, Box or Pentagon.
            if (Math.random() < 0.33) {
                body.shapes.add(new Circle(20));
            }
            else if (Math.random() < 0.5) {
                body.shapes.add(new Polygon(Polygon.box(40, 40)));
            }
            else {
                body.shapes.add(new Polygon(Polygon.regular(20, 20, 5)));
            }
 
            // Set to random position on stage and add to Space.
            body.position.setxy(Math.random() * w, Math.random() * h);
            body.space = space;
        }
 
        // Set up a PivotJoint constraint for dragging objects.
        //
        //   A PivotJoint constraint has as parameters a pair
        //   of anchor points defined in the local coordinate
        //   system of the respective Bodys which it strives
        //   to lock together, permitting the Bodys to rotate
        //   relative to eachother.
        //
        //   We create a PivotJoint with the first body given
        //   as 'space.world' which is a pre-defined static
        //   body in the Space having no shapes or velocities.
        //   Perfect for dragging objects or pinning things
        //   to the stage.
        //
        //   We do not yet set the second body as this is done
        //   in the mouseDownHandler, so we add to the Space
        //   but set it as inactive.
        handJoint = new PivotJoint(space.world, null, Vec2.weak(), Vec2.weak());
        handJoint.space = space;
        handJoint.active = false;
 
        // We also define this joint to be 'elastic' by setting
        // its 'stiff' property to false.
        //
        //   We could further configure elastic behaviour of this
        //   constraint through the 'frequency' and 'damping'
        //   properties.
        handJoint.stiff = false;
 
        // Set up fixed time step logic.
        prevTimeMS = Std.int(Timer.stamp() * 1000);
        window.requestAnimationFrame(enterFrameHandler);
        simulationTime = 0.0;
    }
 
    function enterFrameHandler(ev:Float):Void {
        var positionDiv = window.document.getElementById('b_position');
        debugBodiesPosition = '{ "bodies" : [';
        
        // var curTimeMS = Std.int(Timer.stamp() * 1000);
        
        // if (curTimeMS == prevTimeMS) {
            // No time has passed!
            // return;
        // }
 
        // Amount of time we need to try and simulate (in seconds).
        // var deltaTime = (curTimeMS - prevTimeMS) / 1000;
        // // We cap this value so that if execution is paused we do
        // // not end up trying to simulate 10 minutes at once.
        // if (deltaTime > 0.05) {
        //     deltaTime = 0.05;
        // }
        // prevTimeMS = curTimeMS;
        // simulationTime += deltaTime;
 
        // If the hand joint is active, then set its first anchor to be
        // at the mouse coordinates so that we drag bodies that have
        // have been set as the hand joint's body2.
        if (handJoint.active) {
            handJoint.anchor1.setxy(mouseX, mouseY);
        }
 
        // Keep on stepping forward by fixed time step until amount of time
        // needed has been simulated.
        // while (space.elapsedTime < simulationTime) {
        space.step(1 / 10);
        // }
        
        i = i + 1;
        // trace(i);
        
        var _ctx = ctx;

        ctx.fillStyle = '#FFFFFF';
        ctx.lineWidth = 10;
        ctx.beginPath();        
        ctx.fillRect(0, 0, 1024, 700);
        ctx.closePath();
        ctx.stroke();

        currentBodyIndex = 0;
        space.bodies.foreach(function renderObj(obj){
            currentBodyIndex = currentBodyIndex + 1;
            if(currentBodyIndex > space.bodies.length){
                currentBodyIndex = 0;
            }
            preserveComma = true;
            if(currentBodyIndex == space.bodies.length){
                preserveComma = false;
            }
            var comma = '';
            if (preserveComma) {
                comma = ' , ';
            }
            debugBodiesPosition = debugBodiesPosition  + ' [ ' + obj.bounds.x + ' , '+ obj.bounds.y + ' , ' + obj.bounds.width + ' , ' + obj.bounds.height + ' ] ' + comma + '';
                    // renderLine(obj.bounds.x, obj.bounds.y, obj.bounds.x + 10, obj.bounds.y+10);
            
            // trace(ctx);
            // trace(obj.type.toString());
            if(obj.type.toString() == 'DYNAMIC'){
                    ctx.fillStyle = '#000000';
                    if(currentBodyIndex == playerBodyIndex){
                        ctx.fillStyle = '#0000FF';    
                    }
                    ctx.lineWidth = 10;
                    ctx.beginPath();
                    // ctx.moveTo(obj.bounds.x, obj.bounds.y);        
                    ctx.fillRect(obj.bounds.x, obj.bounds.y, obj.bounds.width, obj.bounds.height);
                    ctx.closePath();
                    ctx.stroke();
                    // ctx.fillPath();
            }
            // trace(currentBodyIndex);
        });
        if(log == 0){
            // trace(space);
            space.bodies.foreach(function(obj){
                // trace(obj.velocity);
                // trace(obj.posy);
            });
            log = 1;
        }

        positionDiv.textContent = debugBodiesPosition + ']}';
        window.requestAnimationFrame(enterFrameHandler);
        // Render Space to the debug draw.
        //   We first clear the debug screen,
        //   then draw the entire Space,
        //   and finally flush the draw calls to the screen.
        // debug.clear();
        // debug.draw(space);
        // debug.flush();
    }
 
    function mouseDownHandler(ev:MouseEvent):Void {
        // Allocate a Vec2 from object pool.
        var mousePoint = new Vec2(ev.screenX, ev.screenY);
        // Determine the set of Body's which are intersecting mouse point.
        // And search for any 'dynamic' type Body to begin dragging.
        for (body in space.bodiesUnderPoint(mousePoint)) {
            if (!body.isDynamic()) {
                continue;
            }
 
            // Configure hand joint to drag this body.
            //   We initialise the anchor point on this body so that
            //   constraint is satisfied.
            //
            //   The second argument of worldPointToLocal means we get back
            //   a 'weak' Vec2 which will be automatically sent back to object
            //   pool when setting the handJoint's anchor2 property.
            handJoint.body2 = body;
            handJoint.anchor2.set(body.worldPointToLocal(mousePoint, true));
 
            // Enable hand joint!
            handJoint.active = true;
 
            break;
        }
 
        // Release Vec2 back to object pool.
        mousePoint.dispose();
    }

    function mouseMoveHandler(ev:MouseEvent):Void {
        mouseX = ev.screenX;
        mouseY = ev.screenY;
    }
 
    function mouseUpHandler(ev:MouseEvent):Void {
        // Disable hand joint (if not already disabled).
        handJoint.active = false;
        trace('mouse up');
    }
 
    function keyDownHandler(ev:KeyboardEvent):Void {

        directed = true;
        trace('keyDown');
        if(ev.key == 'ArrowDown'){
            space.bodies.at(5).velocity = new Vec2(0,15);
            // trace(space.bodies.at(5).position.toString());
        }
        if(ev.key == 'ArrowUp'){
            space.bodies.at(5).velocity = new Vec2(0,-15);
            // trace(space.bodies.at(5).position.toString());
        }
        if(ev.key == 'ArrowRight'){
            space.bodies.at(5).velocity = new Vec2(15,0);
            // space.bodies.at(5).velocity.y = -5;
            // trace(space.bodies.at(5).position.toString());
        }
        if(ev.key == 'ArrowLeft'){
            space.bodies.at(5).velocity = new Vec2(-15,0);
            // space.bodies.at(5).velocity.x = 5;
            // trace(space.bodies.at(5).position.toString());
        }
    }
 
    static function main() {
        var _FixedDragging = new FixedDragging();
        instance = _FixedDragging;
    }
}