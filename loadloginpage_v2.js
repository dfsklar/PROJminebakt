var page = require('webpage').create();

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
  var maxtimeOutMillis = timeOutMillis ? timeOutMillis : 12000, //< Default Max Timout
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
  }, 1000); // < repeat interval
};

page.open('https://ts360.baker-taylor.com/_layouts/CommerceServer/CommerceLoginPage.aspx?sss=1', function() {
  console.log("JQ has been loaded.");
  console.log(JSON.stringify(phantom.cookies));
  var btn = page.evaluate(function() {

	  $('#ctl00_BodyContainer_PlaceHolderMain_SPNextGenLoginWebPart_ctl00_txtLoginID_text').val("dfsklar@gmail.com");
	  $('#ctl00_BodyContainer_PlaceHolderMain_SPNextGenLoginWebPart_ctl00_txtLoginID').val("dfsklar@gmail.com");
	  $('#ctl00$BodyContainer$PlaceHolderMain$SPNextGenLoginWebPart$ctl00$txtLoginID').val("dfsklar@gmail.com");

	  $('#ctl00_BodyContainer_PlaceHolderMain_SPNextGenLoginWebPart_ctl00_txtPassword_text').val("hema2maIACT");
	  $('#ctl00_BodyContainer_PlaceHolderMain_SPNextGenLoginWebPart_ctl00_txtPassword').val("hema2maIACT");
	  $('#ctl00$BodyContainer$PlaceHolderMain$SPNextGenLoginWebPart$ctl00$txtPassword').val("hema2maIACT");

	  var e = jQuery.Event("keypress");
	  e.which = 13; //choose the one you want
	  e.keyCode = 13;
	  $('#ctl00_BodyContainer_PlaceHolderMain_SPNextGenLoginWebPart_ctl00_chkRememberMe').trigger(e);
	  console.log("Submitting the form via a simulated ENTER key");
  });

  console.log("Waiting for response to click event");
  waitFor("false", 
          function(){
            console.log("Emitting PNG");
            page.render("./login_result.png");
            phantom.exit();
          });
});
