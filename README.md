# rainbow

The rainbow project is a mobile scavenger hunt application developed for Apple phones. It is built to showcase visual recognition and machine learning in a fun way.

This project repository consists of an iOS app and a backend server. Both components are written in the Swift programming language.


###### To develop the iOS app

Install Carthage - a dependency management solution for iOS development

Download the latest release of Carthage from the list [here](https://github.com/Carthage/Carthage/releases). Select the most recent build, then under Downloads select Carthage.pkg.

Double-click Carthage.pkg to run the installer. Click Continue, select a location to install to, click Continue again, and finally click Install.

When Carthage is installed, navigate to the iOS folder on your terminal, and type:

```carthage update --platform iOS```

Create a folder called 'Frameworks' in the iOS folder. Find the Lumina.framework and VisualRecognitionV3.framework from the Carthage Build folder, and move them to the Frameworks folder.

Open the rainbow.xcodeproj in XCode. Select the rainbow target, choose the General tab at the top, and scroll down to the Linked Frameworks and Libraries section at the bottom.

Drag and drop the Frameworks folder to the rainbow project - click 'add groups' instead of add folder references. Navigate to the 'embedded binaries' section of the rainbow project general information, and add the two frameworks as embedded binaries.

TODO: Install customized version of Lumina framework

###### To develop the server

?
