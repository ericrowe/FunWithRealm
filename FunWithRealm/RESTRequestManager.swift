//
//  JSONRequestManager.swift
//

import UIKit


class RESTRequestManager: NSObject, NSURLConnectionDelegate {
    var verbosity : Int
    
    var serverAddress : NSString?
    var serverCachingAllowed : Bool
    
    var incomingData : NSMutableData?
    var lastRequestID : NSInteger
    
    var loadingInProgress : Bool
    var results : NSMutableDictionary?
    
    var notificationName : NSString?
    let defaultNotificationName = "JSONRequestManagerDidCompleteDictionaryLoading"
    let errorNotificationName = "JSONRequestManagerDidFailDictionaryLoading"
    var notificationResponseObject : [String: RESTRequestManager]?
    
    
    var parsingCurrentElement : String?
    var parsingCurrentValue : String?
    var parserSpaceCount : NSInteger
    
    
    override init() {
        serverCachingAllowed = false
        lastRequestID = 0
        loadingInProgress = false
        verbosity = 0
        parserSpaceCount = 0
        
        super.init()
        
        notificationResponseObject = ["sender":self]
    }
    
    func loadDictionaryFromServer() -> NSInteger {
        if var remoteServerAddress = serverAddress {
            return loadDictionaryFromServer(remoteServerAddress)
        } else {
            println("no server address set")
            return 0
        }
    }
    func loadDictionaryFromServer(remoteServerAddress : NSString) -> NSInteger {
        return loadDictionaryFromServer(remoteServerAddress, notificationName: defaultNotificationName)
    }
    func loadDictionaryFromServer(remoteServerAddress : NSString, notificationName : NSString) -> NSInteger {
        
        self.notificationName = notificationName
        
        var request : NSURLRequest = NSURLRequest(
            URL: NSURL(string: remoteServerAddress as String)!,
            cachePolicy: serverCachingAllowed ? NSURLRequestCachePolicy.ReturnCacheDataElseLoad:NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 60.0)
        
        var connection : NSURLConnection? = NSURLConnection(request: request, delegate: self, startImmediately: false)
        if var validConnection = connection {
            incomingData = NSMutableData()
            validConnection.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            validConnection.start()
            loadingInProgress = true
            return lastRequestID++
        } else {
            println("didn't get valid connection")
            return 0
        }
    }

    func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        if var validIncomingData = incomingData {
            validIncomingData.length = 0
        }
    }
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        if var validIncomingData = incomingData {
            validIncomingData.appendData(data)
        }
    }
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        println("didFailWithError")
        loadingInProgress = false
        NSNotificationCenter.defaultCenter().postNotificationName(errorNotificationName, object: nil, userInfo: ["sender":self])
    }
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        if var validIncomingData = incomingData {
            var error : NSError?
            results = NSJSONSerialization.JSONObjectWithData(validIncomingData, options: NSJSONReadingOptions.AllowFragments, error: &error) as? NSMutableDictionary
            if let actualError = error {
                println("error: \(actualError)")
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotificationName, object: nil, userInfo: ["sender":self])
            } else {
                if var validJsonArray = results {
                    if var validNotificationName = notificationName {
                        NSNotificationCenter.defaultCenter().postNotificationName(validNotificationName as String, object: nil, userInfo: notificationResponseObject!)
                    } else {
                        NSNotificationCenter.defaultCenter().postNotificationName(defaultNotificationName, object: nil, userInfo: notificationResponseObject!)
                    }
                } else {
                    println("got data, but can't parse, no error returned")
                    NSNotificationCenter.defaultCenter().postNotificationName(errorNotificationName, object: nil, userInfo: ["sender":self])
                }
            }
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName(errorNotificationName, object: nil, userInfo: ["sender":self])
        }
        loadingInProgress = false
    }
}
