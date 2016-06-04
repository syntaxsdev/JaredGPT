//
//  TwitterModule.swift
//  Jared
//
//  Created by Zeke Snider on 4/9/16.
//  Copyright © 2016 Zeke Snider. All rights reserved.
//

import Foundation
import Alamofire
import JaredFramework
import SwiftyJSON

private extension String {
    func getBase64() -> String {
        let credentialData = self.dataUsingEncoding(NSUTF8StringEncoding)!
        return credentialData.base64EncodedStringWithOptions([])
    }
}

struct Tweet {
    var Text: String
}

class TwitterModule: RoutingModule {
    var routes: [Route] = []
    var description = "Twitter Integration"
    var accessToken: String?
    let defaults = NSUserDefaults.standardUserDefaults()
    var consumerKey: String {
        get {
            return defaults.stringForKey("TwitterKey") ?? "None"
        }
    }
    var consumerSecret: String {
        get {
            return defaults.stringForKey("TwitterSecret") ?? "None"
        }
    }
    
    let baseUrlString = "https://api.twitter.com/1.1/"
    let pageSize = 20
    
    required init() {        
        let twitterStatus = Route(name: "Twitter Tweet Integration", comparisons: [.ContainsURL: ["twitter.com"]], call: self.twitterStatusID, description: "Twitter integration to get detail of a tweet URLs")
        
        routes = [twitterStatus]
        
        print("hi")
    }
    
    
    func twitterStatusID(message:String, myRoom: Room) -> Void {
        if message.containsString("/status") {
            let urlComp = message.componentsSeparatedByString("/status/")
            let tweetID = urlComp[1]
            getTweet(tweetID, sendToGroupID: myRoom.GUID)
        }
        else {
            let urlComp = message.componentsSeparatedByString("/")
            let count = urlComp.count
            getTwitterUser(urlComp[count-1], sendToGroupID: myRoom.GUID)
        }
        
    }
    
    func authenticate(completionBlock: Void -> ()) {
        if accessToken != nil {
            completionBlock()
        }
        
        let credentials = "\(consumerKey):\(consumerSecret)"
        let headers = ["Authorization": "Basic \(credentials.getBase64())"]
        let params: [String : AnyObject] = ["grant_type": "client_credentials"]
        
        Alamofire.request(.POST, "https://api.twitter.com/oauth2/token", headers: headers, parameters: params)
            .responseJSON { response in
                if let JSON = response.result.value {
                    print(response)
                    self.accessToken = JSON.objectForKey("access_token") as? String
                    completionBlock()
                }
        }
    }
    func getTweet(fromID: String, sendToGroupID: String) {
        authenticate {
            guard let token = self.accessToken else {
                // TODO: Show authentication error
                return
            }
            
            let headers = ["Authorization": "Bearer \(token)"]
            let params: [String : AnyObject] = [
                "id" : fromID,
                "include_entities": false
            ]
            Alamofire.request(.GET, self.baseUrlString + "statuses/show.json", headers: headers, parameters: params)
                .responseString { response in
                    print(response.response)
                    
                    self.sendTweet(response.result.value!, toChat: sendToGroupID)
            }
            
        }
    }
    
    func getTwitterUser(fromUser: String, sendToGroupID: String) {
        authenticate {
            guard let token = self.accessToken else {
                // TODO: Show authentication error
                return
            }
            
            let headers = ["Authorization": "Bearer \(token)"]
            let params: [String : AnyObject] = [
                "screen_name" : fromUser
            ]
            Alamofire.request(.GET, self.baseUrlString + "users/show.json", headers: headers, parameters: params)
                .responseString { response in
                    print(response.response)
                    
                    self.sendTwitterUser(response.result.value!, toChat: sendToGroupID)
            }
            
        }
    }
    
    func sendTweet(tweetJSON: String, toChat: String) {
        if let dataFromString = tweetJSON.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let JSONParse = JSON(data: dataFromString)
            let TweetString = "\"\(JSONParse["text"].stringValue)\"\n-\(JSONParse["user"]["name"].stringValue)\n\(convertJSONDate(JSONParse["created_at"].stringValue))"
            SendText(TweetString, toRoom: Room(GUID: toChat))
        }
    }
    
    func sendTwitterUser(tweetJSON: String, toChat: String) {
        if let dataFromString = tweetJSON.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let JSONParse = JSON(data: dataFromString)
            let TweetString = "\(JSONParse["name"].stringValue)\n\"\(JSONParse["description"].stringValue)\"\n\(JSONParse["statuses_count"]) Tweets\n\(JSONParse["followers_count"]) Followers\n\(JSONParse["friends_count"]) Following\nJoined Twitter on \(convertJSONDate(JSONParse["created_at"].stringValue))\n"
            SendText(TweetString, toRoom: Room(GUID: toChat))
        }
    }
    
    func getTimelineForScreenName(screenName: String) {
        
        authenticate {
            
            guard let token = self.accessToken else {
                // TODO: Show authentication error
                return
            }
            
            let headers = ["Authorization": "Bearer \(token)"]
            let params: [String : AnyObject] = [
                "screen_name" : screenName,
                "count": self.pageSize
            ]
            Alamofire.request(.GET, self.baseUrlString + "statuses/user_timeline.json", headers: headers, parameters: params)
                .responseJSON { response in
                    print(response.response)
                    
                    if let JSON = response.result.value {
                        print(JSON)
                    }
            }
        }
    }
    
}