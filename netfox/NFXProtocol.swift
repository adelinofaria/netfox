//
//  NFXProtocol.swift
//  netfox
//
//  Copyright © 2015 kasketis. All rights reserved.
//

import Foundation

@objc
public class NFXProtocol: NSURLProtocol
{
    
    var connection: NSURLConnection?
    var model: NFXHTTPModel?
    
    override public class func canInitWithRequest(request: NSURLRequest) -> Bool
    {
        if let url = request.URL {
            if (!(url.absoluteString.hasPrefix("http")) && !(url.absoluteString.hasPrefix("https"))) {
                return false
            }

            for ignoredURL in NFX.sharedInstance().ignoredURLs {
                if url.absoluteString.hasPrefix(ignoredURL) {
                    return false
                }
            }
        } else {
            return false
        }

        if NSURLProtocol.propertyForKey("NFXInternal", inRequest: request) != nil {
            return false
        }
        
        return true
    }
    
    override public func startLoading()
    {
        self.model = NFXHTTPModel()
                
        var req: NSMutableURLRequest
        req = NFXProtocol.canonicalRequestForRequest(request).mutableCopy() as! NSMutableURLRequest
        
        self.model?.saveRequest(req)
                
        NSURLProtocol.setProperty("1", forKey: "NFXInternal", inRequest: req)
        
        let session = NSURLSession.sharedSession()
        session.dataTaskWithRequest(req, completionHandler: {data, response, error in
            
            if error != nil {
                self.client?.URLProtocol(self, didFailWithError: error!)
                
            } else {
                if ((data) != nil) {
                    self.model?.saveResponse(response!, data: data!)
                }
                self.loaded()
            }
            
            if (data != nil) {
                self.client!.URLProtocol(self, didReceiveResponse: response!, cacheStoragePolicy: .NotAllowed)
                self.client!.URLProtocol(self, didLoadData: data!)
                self.client!.URLProtocolDidFinishLoading(self)

            }
            
        }).resume()
    }
    
    override public func stopLoading()
    {
        
    }
    
    override public class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest
    {
        return request
    }
    
    func loaded()
    {
        if (self.model != nil) {
            NFXHTTPModelManager.sharedInstance.add(self.model!)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("NFXReloadTableData", object: nil)
    }
    
}