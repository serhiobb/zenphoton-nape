package;
 
/**
 *
 * Sample: Basic Simulation
 * Author: Luca Deltodesco
 *
 * In this sample, I show how to construct the most basic of Nape
 * simulations, together with a debug display.
 *
 */
 
import js.Browser;
import js.html.Document;
import js.html.Window;
import js.html.Event;
import js.html.KeyboardEvent;
import js.html.CanvasElement;
import js.html.BodyElement;
import js.html.CanvasRenderingContext2D;
 
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.space.Space;
// import nape.util.ShapeDebug;
import nape.util.Debug;
 
class Main {
    var i:Int;
    var currentBodyIndex:Int;
    var log:Int;
    var space:Space;
    var debug:Debug;
    var window:Window;
    var document:Document;
	var body:BodyElement;
	var canvas:CanvasElement;
	var ctx:CanvasRenderingContext2D;

    static function main():Void{
        var main = new Main();
        // main.documentOnload();

    }

    function documentOnload(x):Void{
        // trace(x);
        // trace(window.document.children[0]);
        // if(window.document.children[0].children[2] != null){
            window.document.children[0].children[1].appendChild(canvas);
        // }
    }

    function new() {
        i = 0;
        log = 0;
        currentBodyIndex = 0;
        document = Browser.document;
        // trace(document.children[0].children[1]);
        window = Browser.window;
        // trace(window);
        document.onreadystatechange = documentOnload;
        body = cast document.createElement('body');
        //document.appendChild(body);
    	

        
        window.requestAnimationFrame(enterFrameHandler);
    	canvas = cast document.createElement('canvas');
        canvas.width = 1024;
        canvas.height = 600;
        ctx = canvas.getContext('2d');
        
        body.appendChild(canvas);
        
        //document.body.appendChild(canvas);
        // trace(ctx);
        initialise(null);
    }
 
    function initialise(ev:Event):Void {
 
        // Create a new simulation Space.
        //   Weak Vec2 will be automatically sent to object pool.
        //   when used as argument to Space constructor.
        var gravity = Vec2.weak(0, 600);
        space = new Space(gravity);
 
        // Create a new BitmapDebug screen matching stage dimensions and
        // background colour.
        //   The Debug object itself is not a DisplayObject, we add its
        //   display property to the display list.
        // debug = new ShapeDebug(320, 240, '#FFFFFFFF');
        //addChild(debug.display);
 
        setUp();
 
        //stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
        //stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
    }
 
    function setUp() {
        var w = 320;
        var h = 240;
 
        // Create the floor for the simulation.
        //   We use a STATIC type object, and give it a single
        //   Polygon with vertices defined by Polygon.rect utility
        //   whose arguments are (x, y) of top-left corner and the
        //   width and height.
        //
        //   A static object does not rotate, so we don't need to
        //   care that the origin of the Body (0, 0) is not in the
        //   centre of the Body's shapes.
        var floor = new Body(BodyType.STATIC);
        floor.shapes.add(new Polygon(Polygon.rect(50, (h - 50), (w - 100), 1)));
        floor.space = space;
 
        // Create a tower of boxes.
        //   We use a DYNAMIC type object, and give it a single
        //   Polygon with vertices defined by Polygon.box utility
        //   whose arguments are the width and height of box.
        //
        //   Polygon.box(w, h) === Polygon.rect((-w / 2), (-h / 2), w, h)
        //   which means we get a box whose centre is the body origin (0, 0)
        //   and that when this object rotates about its centre it will
        //   act as expected.
        for (i in 0...16) {
            var box = new Body(BodyType.DYNAMIC);
            box.shapes.add(new Polygon(Polygon.box(16, 32)));
            box.position.setxy((w / 2), ((h - 50) - 32 * (i + 0.5)));
            box.space = space;
        }
 
        // Create the rolling ball.
        //   We use a DYNAMIC type object, and give it a single
        //   Circle with radius 50px. Unless specified otherwise
        //   in the second optional argument, the circle is always
        //   centered at the origin.
        //
        //   we give it an angular velocity so when it touched
        //   the floor it will begin rolling towards the tower.
        var ball = new Body(BodyType.DYNAMIC);
        ball.shapes.add(new Circle(50));
        ball.position.setxy(50, h / 2);
        ball.angularVel = 10;
        ball.space = space;
 
        // In each case we have used for adding a Shape to a Body
        //    body.shapes.add(shape);
        // We can also use:
        //    shape.body = body;
        //
        // And for adding the Body to a Space:
        //    body.space = space;
        // We can also use:
        //    space.bodies.add(body);
    }
    
    function renderLine(x1, y1, x2, y2):Void {
        // trace([1,2,3]]);
        ctx.fillStyle = '#000000';
        ctx.lineWidth = 10;
        ctx.beginPath();        
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
        ctx.clip();
    }

    function enterFrameHandler(ev:Float):Void {
        // Step forward in simulation by the required number of seconds.
        space.step(1 / 60);
        i = i +1;
        // trace(i);
        
        if(currentBodyIndex > space.bodies.length){
            currentBodyIndex = 0;
        }
        space.bodies.foreach(function(obj){
            currentBodyIndex = currentBodyIndex + 1;
            // var x = obj.bounds.x;
            // var y = obj.bounds.y;
            // renderLine(obj.bounds.x, obj.bounds.y, obj.bounds.x + 10, obj.bounds.y+10);
            
            ctx.fillStyle = '#000000';
            ctx.lineWidth = 10;
            ctx.beginPath();        
            ctx.moveTo(obj.bounds.x, obj.bounds.y);
            ctx.lineTo(obj.bounds.x + 10, obj.bounds.y + 10);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();
            ctx.clip();

            if(currentBodyIndex == 4){
                   // trace(x); 
            }
            // trace(currentBodyIndex);
            // trace(obj.posx);
            // trace(obj.posy);
        });
        if(log == 0){
            // trace(space);
            space.bodies.foreach(function(obj){
                // trace(obj.velocity);
                // trace(obj.posy);
            });
            log = 1;
        }
        window.requestAnimationFrame(enterFrameHandler);
        //render();
        // Render Space to the debug draw.
        //   We first clear the debug screen,
        //   then draw the entire Space,
        //   and finally flush the draw calls to the screen.
        // debug.clear();
        // debug.draw(space);
        // debug.flush();
    }

    // function render():Void {
    //     window = Browser.window;

    //     window.requestAnimationFrame(render);
    //     return;
    // };
 
    function keyDownHandler(ev:KeyboardEvent):Void {
        if (ev.keyCode == 82) { // 'R'
            // space.clear() removes all bodies (and constraints of
            // which we have none) from the space.
            space.clear();
 
            setUp();
        }
    }
}