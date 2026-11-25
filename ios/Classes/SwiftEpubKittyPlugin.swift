import Flutter
import UIKit
import EpubViewerKit

public class SwiftEpubViewerPlugin: NSObject, FlutterPlugin,FolioReaderPageDelegate,FlutterStreamHandler {
    
    let folioReader = FolioReader()
    static var pageResult: FlutterResult? = nil
    static var pageChannel:FlutterEventChannel? = nil
    
    var config: EpubConfig?
    
    
    //12.13
    public static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(name: "vocsy_epub_viewer", binaryMessenger: registrar.messenger())
      let instance = SwiftEpubViewerPlugin()
        
      pageChannel = FlutterEventChannel.init(name: "page",
                                  binaryMessenger: registrar.messenger());
      // One handler for the lifetime of the engine. Setting it again on open
      // drops the active listen, and the next cancel fails with
      // "No active stream to cancel".
      pageChannel?.setStreamHandler(instance)

      registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      

      switch call.method {
      case "setConfig":
        let arguments = call.arguments as![String:Any]
        let Identifier = arguments["identifier"] as! String
        let scrollDirection = arguments["scrollDirection"] as! String
        let color = arguments["themeColor"] as! String
        let allowSharing = arguments["allowSharing"] as! Bool
        let enableTts = arguments["enableTts"] as! Bool
        let nightMode = arguments["nightMode"] as! Bool

        self.config = EpubConfig.init(Identifier: Identifier,tintColor: color,allowSharing:
            allowSharing,scrollDirection: scrollDirection, enableTts: enableTts, nightMode: nightMode)

        break
      case "open":
          let arguments = call.arguments as![String:Any]
          let bookPath = arguments["bookPath"] as! String
          self.open(epubPath: bookPath)

          break
      case "close":
          self.close()
          break
      case "setChannel":
          result(nil)
          return
      default:
          break
      }
  //    result("iOS " + UIDevice.current.systemVersion)
    }

      public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
          SwiftEpubViewerPlugin.pageResult = events
          return nil
      }

      public func onCancel(withArguments arguments: Any?) -> FlutterError? {
          SwiftEpubViewerPlugin.pageResult = nil
          return nil
      }
      
      
      fileprivate func open(epubPath: String) {
           if epubPath == "" {
              return
          }

          let readerVc = UIApplication.shared.keyWindow!.rootViewController ?? UIViewController()
          folioReader.presentReader(parentViewController: readerVc, withEpubPath: epubPath, andConfig: self.config!.config, shouldRemoveEpub: false)
          folioReader.readerCenter?.pageDelegate = self
      }

      public func pageWillLoad(_ page: FolioReaderPage) {
          
          print("page.pageNumber:"+String(page.pageNumber))

          if (SwiftEpubViewerPlugin.pageResult != nil){
              SwiftEpubViewerPlugin.pageResult!(String(page.pageNumber))
          }

      }
      
      private func close(){
          folioReader.readerContainer?.dismiss(animated: true, completion: nil)
      }

  }
