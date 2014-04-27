var page = require('webpage').create();

var fs = require('fs'),
    system = require('system');

var content = '',
    f = null,
    lines = null,
    eol = system.os.name == 'windows' ? "\r\n" : "\n";

try {
    f = fs.open("isbnlist.txt", "r");
    content = f.read();
} catch (e) {
    console.log(e);
}

if (f) {
    f.close();
}

var isbns = [];

if (content) {
    isbns = content.split(eol);
}



page.settings.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36";
page.settings.loadImages = false;

page.onConsoleMessage = function(msg){
  if (msg.match(/insecure content/))
    return;
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
//    console.log("'waitFor()' entered");
    if ( ( (new Date().getTime() - start) < maxtimeOutMillis) && !condition ) {
      // If not time-out yet and condition not yet fulfilled
      condition = (typeof(testFx) === "string" ? eval(testFx) : testFx()); //< defensive code
//	    console.log(condition);
    } else {
      if(!condition) {
        // If condition still not fulfilled (timeout but condition is 'false')
//        console.log("'waitFor()' timeout -- going ahead and running onReady anyway");
        typeof(onReady) === "string" ? eval(onReady) : onReady(); //< Do what it's supposed to do once the condition is fulfilled
        clearInterval(interval); //< Stop this interval
        // phantom.exit(1);
      } else {
        // Condition fulfilled (timeout and/or condition is 'true')
//        console.log("'waitFor()' finished in " + (new Date().getTime() - start) + "ms.");
        typeof(onReady) === "string" ? eval(onReady) : onReady(); //< Do what it's supposed to do once the condition is fulfilled
        clearInterval(interval); //< Stop this interval
      }
    }
  }, 2000); // < repeat check interval
};




function performOneQuery() {
  if (isbns.length == 0)
    phantom.exit();

  var isbn = isbns.shift();

  console.log("* " + isbn);

  var btn = page.evaluate(function(isbn) {
    $('#ctl00_PlaceHolderMasterPageHeader_ucSearchBox_SearchPhraseTextBox').val(isbn);
    $('#ctl00_PlaceHolderMasterPageHeader_ucSearchBox_SearchPhraseTextBox_wrapper').val(isbn);
    $('#ctl00_PlaceHolderMasterPageHeader_ucSearchBox_SearchPhraseTextBox_text').val(isbn);

    $('#ctl00_QSHeaderPlaceHolder_ucSearchBox_SearchPhraseTextBox').val(isbn);
    $('#ctl00_QSHeaderPlaceHolder_ucSearchBox_SearchPhraseTextBox_wrapper').val(isbn);
    $('#ctl00_QSHeaderPlaceHolder_ucSearchBox_SearchPhraseTextBox_text').val(isbn);

//	  console.log("Submitting the form via a simulated ENTER key...");
    SearchBox.Search();
  }, isbn);

//  console.log("Waiting for response to click event");
  waitFor("false", 
          function(){
            console.log("Emitting for ISBN" + isbn);
            var minedContent = 
              page.evaluate(function() {
                var strEmit = "ZTITLE:" + $('#ctl00_BrowseBodyInner_ProductDetailsUserControl_lblTitle').html() + "\n";
                strEmit += ("ZAUTHOR:" + $('#ctl00_BrowseBodyInner_ProductDetailsUserControl_authors').html() + "\n");
                strEmit += ("ZPRODINF:" + $('#divProductionInformation').html() + "\n");
                strEmit += ("ZPHYS:" + $('#divPhysical').html() + "\n");
                strEmit += ("ZLOINF:" + $('#divDetailLocation').html() + "\n");
		strEmit += ("ZBTINF:" + $('#divBTSpecificData').html() + "\n");
                strEmit += ("ZDETAILS:" + $('#ctl00_BrowseBodyInner_ProductDetailsUserControl_bookInfoPanel').html() + "\n");
                return strEmit;
              });
//            page.render("exports/"+isbn+".png");
            fs.write("exports/"+isbn+".data", minedContent);
//            console.log("ABOUT TO CALL pOQ-1 (deferred)");
            setTimeout(function(){performOneQuery();}, 1000);
          },
          10000);
};


var poq2triggered = false;
page.open('https://ts360.baker-taylor.com/Pages/default.aspx', function(){
  if (!poq2triggered) {
    poq2triggered = true;
//    console.log("ABOUT TO CALL pOQ-2");
    performOneQuery();
  }
});

