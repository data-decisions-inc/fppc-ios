FPPC Gift Tracker
==================
This application helps keep track of gifts for filing a Form 700 Schedule D. 

Building & Running
------------
This project requires
* [XCode 5](https://developer.apple.com/xcode/)

If you install XCode 5, open the project, and click "Run", it should run without hassle.

Preparing for the Apple App Store
------------
[TestFlight](https://testflightapp.com) provides insight into user behavior during testing. If you wish to continue tracking user behavior when this launches on the app store, pull the launch token into a private file and update it for release. If you don't, then remove the TestFlight folder and change "TFLog" to "NSLog".

THANK YOU
------------
This code relies on the following open source software projects:
* [DHxlsIOS of xlslib](http://sourceforge.net/projects/xlslib/files/), for creating excel files
* [DCRoundSwitch](https://github.com/domesticcatsoftware/DCRoundSwitch), for a labeled switch on iOS6

License
-------
TBD
