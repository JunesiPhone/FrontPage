FrontPage
----

Applies a WKWebview to the homescreen. Along with the webview, it calls code within the html to supply iOS info such as battery, music, apps, switcher, signal, wifi, notifications, and other info.

Note: FrontPage's source code is provided for reference purposes only. Modification and redistribution are *not* permitted.

iOS to WebView Calls
----

Calls are sent via stringByEvaluatingJavaScriptFromString this does of course require the widget has specific functions to gather and parse such info. One main function FPIInfo handles the parsing. Each call sent to FPIInfo is followed by another function that says that info is loaded. For example if we call FPI and push battery info after it is done it will call updateBattery() this provides a fast way for the webview to get the info and to know when the info is sent without the need of timers.

A compiled version can be found on my Cydia repo <a href="http://junesiphone.com/supersecret/">here</a>.

WebView to iOS Calls
----

Calls sent from the html to the tweak is handle by setting window.location = 'frontpage:something' the tweak will check if the string contains frontpage and then will try to forward it to any method inside.

Full API <a href="http://junesiphone.com/frontpage/">here</a>.


Credits
----

Andrew Wiik <a href="https://twitter.com/Andywiik">@Andywiik</a> for his implementation of getting weather condition strings from the weather framework. Makes life so much easier for iWidget developers.

Matt Clark <a href="https://twitter.com/_Matchstic">@_Matchstic</a> for his amazing work on <a href="https://github.com/Matchstic/InfoStats2">InfoStats2</a> the roadmap I followed to create FrontPage which has also lead to WidgetInfo.

Images
----

Images from Nyx a theme for iOS that utilizes this code.

![img_0989](https://user-images.githubusercontent.com/9951373/29907437-fc100cb2-8de0-11e7-9b6e-27e1026fedf3.PNG)
![img_0990](https://user-images.githubusercontent.com/9951373/29907436-fc0f7338-8de0-11e7-88df-731a15b1241c.PNG)
![img_0991](https://user-images.githubusercontent.com/9951373/29907438-fc1050b4-8de0-11e7-989a-d61d2acbb6ff.PNG)
![img_0992](https://user-images.githubusercontent.com/9951373/29907439-fc116b20-8de0-11e7-9751-a7aa315f7fbf.PNG)
![img_0993](https://user-images.githubusercontent.com/9951373/29907440-fc124342-8de0-11e7-9179-4ebe2ec9e860.PNG)
![img_0994](https://user-images.githubusercontent.com/9951373/29907441-fc12d500-8de0-11e7-89cc-ffd1f749bf96.PNG)
![img_0995](https://user-images.githubusercontent.com/9951373/29907442-fc1d1150-8de0-11e7-8b44-d51ffc49de04.PNG)
![img_0996](https://user-images.githubusercontent.com/9951373/29907443-fc229a62-8de0-11e7-9132-b94aeb504217.PNG)
![img_0997](https://user-images.githubusercontent.com/9951373/29907444-fc2dd2f6-8de0-11e7-8912-f928877acd31.PNG)

