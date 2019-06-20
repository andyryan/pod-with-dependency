//
//  KMA_SpringStreams.h
//  KMA_SpringStreams
//
//  Created by Frank Kammann on 26.08.11.
//  Copyright 2017 Kantar Media. All rights reserved.
//
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@class KMA_SpringStreams, KMA_Stream;


/** The notification name for the debugging purpose, register this notification into the notification center by following API or similar:
 *(void)addObserver:(id)observer selector:(SEL)aSelector name:KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION object:(nullable id)anObject;
 *Also, you would need to implement the selecotor method to consume the debug info.
 *The debug info is attached in the notification as a NSDictionary, with keys "Request" and "Statuscode". The info can be fetched by The API: [NSNotification object]
 */

extern NSString *const KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION;

/**
 * The meta object has to be delivered by a KMA_StreamAdapter and
 * contains meta information about the system.
 */
@interface KMA_Player_Meta : NSObject<NSCoding, NSCopying> {
}
/**
 * Returns the player name
 *
 * @return the string "iOS Player"
 */
@property (retain,readwrite) NSString *playername;


/**
 * Returns the player version.
 * The itselfs has no version so the system version is delivered.
 *
 * @see http://developer.apple.com/library/ios/#documentation/uikit/reference/UIDevice_Class/Reference/UIDevice.html
 *
 * @return The version my calling [UIDevice currentDevice].systemVersion
 */
@property (retain,readwrite) NSString *playerversion;

/**
 * Returns the screen width my calling the method
 * [[UIScreen mainScreen] bounds].screenRect.size.width
 *
 * @see http://developer.apple.com/library/ios/#documentation/uikit/reference/UIScreen_Class/Reference/UIScreen.html
 *
 * @return the width
 */
@property (assign,readwrite) int screenwidth;

/**
 * Returns the screen width my calling the method
 * [[UIScreen mainScreen] bounds].screenRect.size.height
 *
 * @see http://developer.apple.com/library/ios/#documentation/uikit/reference/UIScreen_Class/Reference/UIScreen.html
 *
 * @return the height
 */
@property (assign,readwrite) int screenheight;

@end


/**
 * Implement this protocol to measure a streaming content.
 */
@protocol KMA_StreamAdapter
@required
/**
 * Returns the information about the player.
 */
-(KMA_Player_Meta*) getMeta;
/**
 * Returns a positive position on the stream in seconds.
 */
-(int) getPosition;
/**
 * Returns the duration of the stream in seconds.
 * If a live stream is playing, in most cases it's not possible to deliver a valid stream length.
 * In this case, the value 0 must be delivered. <b>Internally the duration will be set once if it is
 * greater than 0</b>.
 */
-(int) getDuration;
/**
 * Returns the width of the video.
 * If the content is not a movie the value 0 is to be delivered.
 */
-(int) getWidth;
/**
 * Returns the height of the video.
 * If the content is not a movie the value 0 is to be delivered.
 */
-(int) getHeight;
@end

/**
 * The sensor which exists exactly one time in an application and manage
 * all streaming measurement issues.
 * When the application starts the sensor has to be instantiated one time
 * with the method `getInstance:site:app`.
 * The next calls must be transmtted by the method `getInstance`.
 * @see getInstance:a b
 * @see getInstance:a
 * @see getInstance
 */
@interface KMA_SpringStreams : NSObject {
}
/** Enable or disable usage tracking. (default: true) */
@property (readwrite) BOOL tracking;
/**
 * When set to true (default:false) the library logs the internal actions.
 * Each error is logged without checking this property.
 */
@property (readwrite,nonatomic) BOOL debug;
/**
 * Internally it sends http requests to the measurement system.
 * This property sets a timeout for that purpose.
 */
@property(assign) NSTimeInterval timeout;

/** Enable or disable offline mode. It will be configured in the release process. Please refer to Main page for more Info*/
@property (readwrite) BOOL offlineMode;

/**
 * Returns the instance of the sensor which is initialized with
 * a site name and an application name.
 * @warning
 *   The site name and the application name will be predefined
 *   by the measurement system operator.
 *
 * This method has to be called the first time when the application is starting.
 *
 * @see getInstance
 * @throws An exception is thrown when this method is called for a second time.
 */
+ (KMA_SpringStreams*) getInstance:(NSString*)site a:(NSString*)app;

/**
 * Returns the instance of the sensor which is initialized with
 * a site name and an application name.
 * This method enables user to stop the ad tracking by using boolean parameter AIEnabled.

 * This method has to be called the first time when the application is starting.
 * @see getInstance: a
 * @see getInstance
 * @throws An exception is thrown when this method is called for a second time.
 */
+ (KMA_SpringStreams*) getInstance:(NSString*)site a:(NSString*)app b:(BOOL)AIEnabled;

/**
 * Returns the instance of the sensor.
 *
 * @see getInstance:a
 * @throws An exception is thrown when this method is called with
 *         a previous call of the method `getInstance:a`.
 */
+ (KMA_SpringStreams*) getInstance;

/**
 * Call this method to start a tracking of a streaming content.
 * The sensor gets access to the KMA_Stream through the given adapter.
 * The variable *name* is mandatory in the attributes object.
 *
 * @see KMA_StreamAdapter
 * @see KMA_Stream
 *
 * @param stream The KMA_StreamAdapter which handles the access to
 *        the underlying streaming content
 * @param atts A map which contains information about the streaming content.
 *
 * @throws An exception if parameter *KMA_Stream* or *atts* is null.
 * @throws An exception if the mandatory name attributes are not found.
 *
 * @return A instance of KMA_Stream which handles the tracking.
 */
- (KMA_Stream*) track:(NSObject<KMA_StreamAdapter> *)stream atts:(NSDictionary *)atts;
#ifndef DOXYGEN_SHOULD_SKIP_THIS
/**
 * @internal New Track Method for BARB which takes additional parameter handle(UID retrieved using getNextUID())
 */
-(KMA_Stream*) track:(NSObject<KMA_StreamAdapter> *)stream atts:(NSDictionary *)atts handle:(NSString*) handle;
/**
 * @internal
 * Call this method to getNextUID before starting measurment
 */

-(NSString *) getNextUID;
#endif /* DOXYGEN_SHOULD_SKIP_THIS */

/**
 * When the method is called all internal tracking processes will be terminated.
 * Call this method when the application is closing.
 */
- (void) unload;

/**
 * Returns the encrypted (md5) and truncated mobile identifiers.
 * The MAC ID is stored with the key 'mid'
 * The advertising ID is stored with the key 'ai'
 * The Vendor ID is stored with the key 'ifv'
 */
- (NSMutableDictionary *) getEncrypedIdentifiers;

@end


/**
 * The KMA_Stream object which is returned from the sensor when is called
 * the `track` method.
 */
@interface KMA_Stream : NSObject<NSCopying> {
}
/**
 * Stops the tracking on this KMA_Stream.
 * It is not possible to reactivate the tracking.
 */
- (void) stop;

/**
 * Returns the UID of the stream.
 */
- (NSString*) getUid;

@end


/**
 * @mainpage
 
 <div align="center">
 <h2>Kantar Media Streaming Sensor AppleTV User Manual</h2>
 </div>
 
<div>
    <h3 style="color: red">AppStore Submission with tvOS 11</h3>
    <p>Please be aware that if you do not include the AdSupport.framework in your app you will have to disable the use of the IDFA via API in the constructor. Otherwise your App may be rejected from the AppStore for legal reasons.</p>
    <p>For more information see the API documentation of the constructor.</p>
</div>

 <div style="background-color: grey;" >
 <div align="center">



 </div> 
 
 <h3>App Transport Security (ATS)</h3>
 <p>In Apple TV apps, App Transport Security (ATS) enforces best practices in the secure connections between an app and its back end. Migrating from http to https has to be planed for the more secure communication. However for this moment, if you decide to keep http in KMA_Springstreams library, please add following into the project plist file, otherwise please activate ssl on in the library. </p>
 
 <div style="border:1px solid black;">
 &lt;key&gt;NSAppTransportSecurity&lt;/key&gt;
 <br>&lt;dict&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;NSAllowsArbitraryLoads&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;false/&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;NSExceptionDomains&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;dict&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;<span style="color:#0000CD;">@domain</span>&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;dict&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;NSIncludesSubdomains&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;true/&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;NSTemporaryExceptionAllowsInsecureHTTPLoads&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;true/&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;key&gt;NSExceptionRequiresForwardSecrecy&lt;/key&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;false/&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;/dict&gt;
 <br>&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&lt;/dict&gt;
 <br>&nbsp;&nbsp; &nbsp;&lt;/dict&gt;</div>
 <p><i><span class="marker"><span style="color:#0000CD;">if</span></span> ATS is not enabled in your application, as NSAllowsArbitraryLoads = true, then you don't need to modify anything.
 </i></p>
 
 <h3>Notification registration for debug purpose</h3>
 
 <p>From KMA streaming iOS version 1.7.0, a notification is inserted into the implementation, so that the customers are able to retrieve the requests sent by the library, see more info #KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION. The notification contains a NSDictionary object, with the keys, "Request" and "Statuscode". With the following implementation, it is sample to fetch the debug information.</p>
 <pre><code>
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@ selector(handleApplicationEvent:) name:KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION object:nil];
 &minus; (void) handleApplicationEvent:(NSNotification *)n {
 if(KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION == [n name]) {
    &nbsp;&nbsp;&nbsp;&nbsp; have the implementation
 }
 }
 </code></pre>
 <p><i>Please Note: Set the debug mode (KMA_SpringStreams.debug) to false in your live product, otherwise there will be a debug flag in the measurement request.
 </i></p>
 
 <h3>BitCode</h3>
 <p>Bitcode is a new feature on iOS 9, an intermediate representation of a compiled program. Now you have the new KMA_SpringStreams lib with bitcode enabled, for your application you have the chance to enable or disable the bitcode service.</p>
 </div>
 
 <h3>Integration into Swift Project</h3>
  <div>
 <p>If the project is a Swift project, a swift bridging header file is required for the integration, more tutorial can be found here: https://kantarmedia.atlassian.net/wiki/spaces/public/pages/159726961/Tutorial+on+how+to+import+KMA+measurement+Objective-C+library+into+Swift+project</p>
 </div>
 
 <h3>Offline Mode</h3>
 <p>Kantar Media Streaming Sensor AppleTV has feature so called "offlineMode". This mode can be switched on and off by using public API: KMA_SpringStreams.offlineMode.
 If the lib is configured to offlineMode, KMA_SpringStreams library will hold all requests in a local buffer and send them when the device goes back online. KMA_SpringStreams lib checks the Internet connection regularly by using the Timer and send the data as soon as possible.
 Please notice:
 -# Old requests will be dropped if too many requests pump into local buffer for the limitation in buffer size. The default buffer size is 500. The data will be stored in a local file, so the lib will not lose the requests even if the application terminates.
 -# KMA_SpringStreams lib tries to send the requests in a fixed rate, 10 seconds by default, and sends them if device is online.</p>
 
 <h3>UDID</h3>
 <p>Advertising ID is optional in springstream library, if it exists, it will be used as primary unique ID (AdsupportFramework is required for advertising ID). ID_For_Vendor is retrieved by KMA_springstreams library and will be used to ID the device by the help of "Panel App".</p>
 

 
 <p><i>Please attention: Apple will reject all the applications which retrieve advertising ID but with no advertising content provided. So Advertising-Framework is linked as optional in the library, If the Advertising ID should be used as udid, please import Advertising-Framework into your projects.</i></p>
 
 <h3>NOTICE</h3>
 <p><i>Please Note: Some components in Kantar Media Sensor libs are running in background threads. Please keep the initialization and usage of Spring libs in your main thread, Spring libs will not block your UI display.
 </i></p>

 
 <div align="center">
 <h2>Release Notes</h2>
 </div>

  <h3>Version 1.8.0</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>

 <tr><td>32Bit iOS devices</td>
 <td>Bugfix</td>
 <td><p>Fixes a crash on 32-bit devices, when using a VirtualMeter app.</p></td></tr>

 <tr><td>Scrubbing</td>
 <td>Improvement</td>
 <td><p>Scrubbing now will not add more playstates to request.</p></td></tr> 

  <tr><td>Requests</td>
 <td>Improvement</td>
 <td><p>New payload information in requestes: OS Version & Application Name.</p></td></tr> 

  <tr><td>32Bit iOS devices</td>
 <td>Bugfix</td>
 <td><p>Fixes a bug, which causes the VirtualMeter app been triggered to often.</p></td></tr> 
</table>

  <h3>Version 1.7.3</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>Control over IDFA Access</td>
 <td>Bugfix</td>
 <td><p>The use of the IDFA can now be disabled in constructor. See API documentation for more information.</p></td></tr>
</table>

   <h3>Version 1.7.2</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>UID</td>
 <td>Bugfix</td>
 <td><p>UID generation now working correctly also on 32-bit devices.</p></td></tr>
</table>
 
 <h3>Version 1.7.1</h3>
 <table>
 
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>

   <tr><td>Payload object</td>
 <td>Improvement</td>
 <td><p>OS Version (osv) and Application Name (an) now are added to the payload object of each request.</p></td></tr>
 
    <tr><td>User agent</td>
 <td>Improvement</td>
 <td><p>OS Version and Application Name now are added to the user agent string.</p></td></tr>
 
 <tr><td>Cookie Management</td>
 <td>Improvement</td>
 <td><p>Store cookies in app data in order to prevent deletion of the cookies.</p></td></tr>

  <tr><td>Expose identifiers</td>
 <td>Improvement</td>
 <td><p>The mobile identifiers can be accessed with the new public method getEncryptedIdentifiers of the class Stream.</p></td></tr>

  <tr><td>Ringbuffer</td>
 <td>Improvement</td>
 <td><p>Ringbuffer now flushes all requests when the app goes into background.</p></td></tr>

  <tr><td>SSL</td>
 <td>Improvement</td>
 <td><p>Non-SSL communication has been removed.</p></td></tr>

  <tr><td>Ringbuffer</td>
 <td>Improvement</td>
 <td><p>Requests from the ringbuffer will now be sent always, not only in offline mode.</p></td></tr>

  <tr><td>Streamname</td>
 <td>Refaktoring</td>
 <td><p>Variable stream is now mandatory.</p></td></tr>

  <tr><td>UID</td>
 <td>Improvement</td>
 <td><p>Randomness of UID has been increased and UID is now accessable with an getter.</p></td></tr>
 
 <tr><td>Ringbuffer Handling</td>
 <td>Improvement</td>
 <td><p>Requests from the ringbuffer should be sent always, not only in offline mode.</p></td></tr>
 
 <tr><td>Player position</td>
 <td>Bugfix</td>
 <td><p>Player position (PST object) not accurate in Offline mode for app streaming.</p></td></tr>
 
 <tr><td>URL Scheme Trigger</td>
 <td>Improvement</td>
 <td><p>The VM Trigger frequence has been raised. Within first month after install trigger VM once a week. After the first month after install, trigger VM once a month.</p></td></tr>
 
 <tr><td>URL Scheme Trigger</td>
 <td>Improvement</td>
 <td><p>The URL scheme trigger triggers the CamelCase version first, if unsuccessful the lowercase version is called.</p></td></tr>
 
 <tr><td>AVPlayerViewController</td>
 <td>Improvement</td>
 <td><p>The deprecated API MPMoviePlayerController now is replaced by AVPlayerViewController, in the sample KMA_MediaPlayerAdapter implementation.</p></td></tr>
 
 <tr><td>Request Debugger</td>
 <td>Improvement</td>
 <td><p>A debug Notification is integrated into the library, so that the customers are able to fetch the request sent by the library. See more #KMA_STREAMING_DEBUGINTERFACE_NOTIFICATION.</p></td></tr>
 
 <tr><td>Debug mode</td>
 <td>Improvement</td>
 <td><p>
 Debug mode should be set to false if the application is live product. If the debug set to true, the KMA library will automatic add a flag "isDebug=1" in the http request.</p></td></tr>
 <tr><td>URL Scheme</td>
 <td>Improvement</td>
 <td><p>New beta iOS 10 release has already fixed the url-scheme bug, now capital letters are again valid in url-scheme registration.</p></td></tr>
 
 <tr><td>URL encoding</td>
 <td>Bugfix</td>
 <td><p>URL encoding component is updated in the library. Symbols will be also url-encoded in measurement requests. </p></td></tr>
</table>
 
 <h3>Version 1.4.3</h3>
 <table>
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>Project setting</td>
 <td>Improvement</td>
 <td><p>Enabled Modules (C and Objective-C) (CLANG_ENABLE_MODULES) = NO, in order to eliminate the wired warnings.</p></td></tr>
 </table>
 
 <h3>Version 1.4.2</h3>
 <table>
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>Bitcode</td>
 <td>Improvement</td>
 <td><p>Compile the libraries by using xcode 7, in order to avoid bitcode version confict by xcode 7 and 8.</p></td></tr>
 </table>
 
 <h3>Version 1.4.1</h3>
 <table>
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>Compile Target</td>
 <td>Improvement</td>
 <td><p>Downgrade the compile target to tvOS 9.0, so that all tvOS projects can apply.</p></td></tr>
 </table>
 
 <h3>Version 1.4.0</h3>
 <table>
 <tr><th>Changes</th><th>Attribute</th><th>Description</th></tr>
 
 <tr><td>First Release</td>
 <td>Improvement</td>
 <td><p>This is the first version for Apple TVOS, the library is based on the iOS streaming project, but a new project and configured for Apple TVOS.</p></td></tr>
 </table>
 
 */
