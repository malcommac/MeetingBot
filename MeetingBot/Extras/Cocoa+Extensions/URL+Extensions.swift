//
//  URL+Extensions.swift
//  NextCall
//
//  Created by daniele on 30/08/2020.
//  Copyright © 2020 com.danielemargutti.meetingbot. All rights reserved.
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
        let urlString = self.absoluteString.replacingOccurrences(of: "?", with: "&").replacingOccurrences(of: "/j/", with: "/join?confno=")
        var teamsAppURL = URLComponents(url: URL(string: urlString)!, resolvingAgainstBaseURL: false)!
        teamsAppURL.scheme = "zoommtg"
        return teamsAppURL.url ?? self
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
