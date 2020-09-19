//
//  URL+Extensions.swift
//  NextCall
//
//  Created by daniele on 30/08/2020.
//  Copyright © 2020 com.spillover.nextcall. All rights reserved.
//

import Foundation

extension URL {
    
    private func queryStringParam(_ param: String) -> String? {
        if let urlComponents = NSURLComponents(string: self.absoluteString),
            let queryItems = urlComponents.queryItems {
            return queryItems.filter({ (item) in item.name == param }).first?.value!
        }
        return nil
    }
    
    private func asZoomSchemeURL() -> URL {
        guard self.pathComponents[self.pathComponents.count - 2] == "j" else {
            return self
        }
        
        let confID = self.lastPathComponent
        
        
        var appURLString = "zoommtg://zoom.us/start?confno=\(confID)"
        if let pwd = self.queryStringParam("pwd") {
            appURLString += "&pwd=\(pwd)"
        }
        
        return URL(string: appURLString) ?? self
    }
    
    private func asMeetsSchemeURL() -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        components?.scheme = "msteams"
        return components?.url ?? self
    }
    
    func asSchemeURLForService(_ service: CallServices) -> URL? {
        switch service {
        case .zoom:
            return asZoomSchemeURL()
        case .teams:
            return asMeetsSchemeURL()
        default:
            return self
        }
    }
    
}
