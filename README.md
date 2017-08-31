FrontPage
----

Applies a WKWebview to the homescreen. Along with the webview, it calls code within the html to supply iOS info such as battery, music, apps, switcher, signal, wifi, notifications, and other info.

iOS to WebView Calls
----

Calls are sent via stringByEvaluatingJavaScriptFromString this does of course require the widget has specific functions to gather and parse such info. One main function FPIInfo handles the parsing. Each call sent to FPIInfo is followed by another function that says that info is loaded. For example if we call FPI and push battery info after it is done it will call updateBattery() this provides a fast way for the webview to get the info and to know when the info is sent without the need of timers.

A compiled version can be found on my Cydia repo <a href="http://junesiphone.com/supersecret/">here</a>.

WebView to iOS Calls
----

Calls sent from the html to the tweak is handle by setting window.location = 'frontpage:something' the tweak will check if the string contains frontpage and then will try to forward it to any method inside. 


window.location = 'frontpage:opennc';
window.location = 'frontpage:opencc';
window.location = 'frontpage:disablewifi';
window.location = 'frontpage:enablewifi';
window.location = 'frontpage:respring';
window.location = 'frontpage:sleep';
window.location = 'frontpage:uninstallApp:APPBUNDLE';
window.location = 'frontpage:openApp:APPBUNDLE';
window.location = 'frontpage:loadSettings:var/mobile/Documents/FrontPage.plist';
window.location = "frontpage:showMenu";
window.location = 'frontpage:vibrate';

Manual Updates
window.location = 'frontpage:updateMemory';
window.location = 'frontpage:refreshWeather';

Nyx special
window.location = 'frontpage:isntInTerminal';
window.location = 'frontpage:isInTerminal';

Music
window.location = 'frontpage:prevtrack';
window.location = 'frontpage:nexttrack';
window.location = 'frontpage:playmusic';

Credits
----

Andrew Wiik <a href="https://twitter.com/Andywiik">@Andywiik</a> for his implementation of getting weather condition strings from the weather framework. Makes life so much easier for iWidget developers.

Matt Clark <a href="https://twitter.com/_Matchstic">@_Matchstic</a> for his amazing work on <a href="https://github.com/Matchstic/InfoStats2">InfoStats2</a> the roadmap I followed to create FrontPage which has also lead to WidgetInfo.

