haxe -main Main.hx -js app.js && 
haxe -main FixedDragging.hx -js fd.js &&
cp ./fd.js ./zenphoton/html/fd.js && 
cd ./zenphoton/html && bash build.sh && cd ../../