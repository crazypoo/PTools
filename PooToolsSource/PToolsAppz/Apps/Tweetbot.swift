// English: Native PTools application descriptor adapted from the MIT-licensed upstream catalog.
// Español: Descriptor nativo de aplicación PTools adaptado del catálogo original bajo licencia MIT.
// 中文：从 MIT 许可的上游目录适配而来的 PTools 原生应用描述器。

import Foundation

public extension Applications {
    
    struct Tweetbot: PTExternalApplication {
        
        public typealias ActionType = Applications.Tweetbot.Action
        
        public let scheme = "tweetbot:"
        public let fallbackURL = "http://tapbots.com/tweetbot/"
        public let appStoreId = "722294701"
        
        public init() {} 
    }
}


public extension Applications.Tweetbot {
    
    enum Action: Sendable {
        case timeline(screenname: String?)
        case mentions(screenname: String?)
        case retweets(screenname: String?)
        case directMessages(screenname: String?)
        case lists(screenname: String?)
        case favorites(screenname: String?)
        case search(screenname: String?, query: String?, callbackurl: String?)
        case status(screenname: String?, tweetId: String, callbackurl: String?)
        case userProfile(screenname: String?, profileScreennameOrId: String, callbackurl: String?)
        case post(screenname: String?,text: String?, callbackurl: String?, repliedStatusId: String?)
        case follow(screenname: String?, followScreennameOrId: String)
        case unfollow(screenname: String?, followScreennameOrId: String)
        case favorite(screenname: String?, tweetId: String)
        case unfavorite(screenname: String?, tweetId: String)
        case retweet(screenname: String?, tweetId: String)
        case list(screenname: String?, listId: String, callbackurl: String?)
    }
}

extension Applications.Tweetbot.Action: PTExternalApplicationAction {
    
    public var paths: PTApplicationActionPaths {
        
        switch self {

        case .timeline(let screenname):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "timeline"],
                    queryParameters: [:]),
                web: PTApplicationPath())
            
        case .mentions(let screenname):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "mentions"],
                    queryParameters: [:]),
                web: PTApplicationPath())
            
        case .retweets(let screenname):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "retweets"],
                    queryParameters: [:]),
                web: PTApplicationPath())
            
        case .directMessages(let screenname):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "direct_messages"],
                    queryParameters: [:]),
                web: PTApplicationPath())
            
        case .lists(let screenname):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "lists"],
                    queryParameters: [:]),
                web: PTApplicationPath())
            
        case .favorites(let screenname):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "favorites"],
                    queryParameters: [:]),
                web: PTApplicationPath())
            
        case .search(let screenname, let query, let callbackurl):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "search"],
                    queryParameters: [
                        "query":query ?? "",
                        "callback_url":callbackurl ?? ""]),
                web: PTApplicationPath())
            
        case .status(let screenname, let tweetId, let callbackurl):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "status", tweetId],
                    queryParameters: ["callback_url":callbackurl ?? ""]),
                web: PTApplicationPath())
            
        case .userProfile(let screenname , let profileScreennameOrId , let callbackurl):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "",
                        "user_profile", profileScreennameOrId],
                    queryParameters: ["callback_url":callbackurl ?? ""]),
                web: PTApplicationPath())
            
        case .post(let screenname, let text, let callbackurl, let repliedStatusId):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "post"],
                    queryParameters: [
                        "text":text ?? "",
                        "in_reply_to_status_id": repliedStatusId ?? "",
                        "callback_url":callbackurl ?? ""]),
                web: PTApplicationPath())
            
        case .follow(let screenname, let followScreennameOrId):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "follow", followScreennameOrId],
                    queryParameters: [:]),
                web: PTApplicationPath())
            
        case .unfollow(let screenname, let followScreennameOrId):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "unfollow", followScreennameOrId],
                    queryParameters: [:]),
                web: PTApplicationPath())
            
        case .favorite(let screenname, let tweetId):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "favorite", tweetId],
                    queryParameters: [:]),
                web: PTApplicationPath())
            
        case .unfavorite(let screenname, let tweetId):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "unfavorite", tweetId],
                    queryParameters: [:]),
                web: PTApplicationPath())
            
        case .retweet(let screenname, let tweetId):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "retweet", tweetId],
                    queryParameters: [:]),
                web: PTApplicationPath())
            
        case .list(let screenname, let listId, let callbackurl):
            return PTApplicationActionPaths(
                app:
                PTApplicationPath(
                    pathComponents: [screenname ?? "", "list", listId],
                    queryParameters: ["callback_url" : callbackurl ?? ""]),
                web: PTApplicationPath())
        }
    }
}
