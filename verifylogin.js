var page = require('webpage').create();
var fs = require('fs');

page.settings.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36";

page.onConsoleMessage = function(msg){
    console.log("LOG MESSAGE COMING FROM INTRA-BROWSER JS: " + msg);
};


/**
 * Wait until the test condition is true or a timeout occurs. Useful for waiting
 * on a server response or for a ui change (fadeIn, etc.) to occur.
 *
 * @param testFx javascript condition that evaluates to a boolean,
 * it can be passed in as a string (e.g.: "1 == 1" or "$('#bar').is(':visible')" or
 * as a callback function.
 * @param onReady what to do when testFx condition is fulfilled,
 * it can be passed in as a string (e.g.: "1 == 1" or "$('#bar').is(':visible')" or
 * as a callback function.
 * @param timeOutMillis the max amount of time to wait. If not specified, 3 sec is used.
 */
function waitFor(testFx, onReady, timeOutMillis) {
  var maxtimeOutMillis = timeOutMillis ? timeOutMillis : 6000, //< Default Max Timout is 6s
  start = new Date().getTime(),
  condition = false,
  interval = setInterval(function() {
    console.log("'waitFor()' entered");
    if ( ( (new Date().getTime() - start) < maxtimeOutMillis) && !condition ) {
      // If not time-out yet and condition not yet fulfilled
      condition = (typeof(testFx) === "string" ? eval(testFx) : testFx()); //< defensive code
	    console.log(condition);
    } else {
      if(!condition) {
                // If condition still not fulfilled (timeout but condition is 'false')
                console.log("'waitFor()' timeout -- going ahead and running onReady anyway");
                typeof(onReady) === "string" ? eval(onReady) : onReady(); //< Do what it's supposed to do once the condition is fulfilled
                clearInterval(interval); //< Stop this interval
                // phantom.exit(1);
            } else {
                // Condition fulfilled (timeout and/or condition is 'true')
                console.log("'waitFor()' finished in " + (new Date().getTime() - start) + "ms.");
                typeof(onReady) === "string" ? eval(onReady) : onReady(); //< Do what it's supposed to do once the condition is fulfilled
                clearInterval(interval); //< Stop this interval
            }
        }
    }, 2000); // < repeat check interval
};

var isbn = '9780451413888';

page.open('https://ts360.baker-taylor.com/Pages/default.aspx', function() {
    console.log("JQ has been loaded.");
    console.log("Waiting to take picture");
    waitFor("false", 
            function(){
              console.log("Emitting PNG and captured DOM");
              page.render("./verify_login.png");
              phantom.exit();
            },
           15000);
});
