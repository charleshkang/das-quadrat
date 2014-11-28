//
//  FSSession.swift
//  Quadrat
//
//  Created by Constantine Fry on 26/10/14.
//  Copyright (c) 2014 Constantine Fry. All rights reserved.
//

import Foundation

public typealias AuthorizationHandler = (Bool, NSError?) -> Void

public typealias ResponseClosure = (response: Response) -> Void

public let UserSelf = "self"

public typealias Parameters = [String:String]

/**
    Posted when session have access token, but server returs response with 401 HTTP code.
    Guaranteed to be posted an main thread.
*/
public let QuadratSessionDidBecomeUnauthorizedNotification = "QuadratSessionDidBecomeUnauthorizedNotification"

private var _sharedSession : Session?

public class Session {
    let configuration       : Configuration
    let URLSession          : NSURLSession
    var authorizer          : Authorizer?
    
    /**
        One can create custom logger to process all errors and responses in one place.
        Main purpose is to debug or to track all the errors accured in framework via some analytic tool.
    */
    public var logger       : Logger?
    
    public lazy var users : Users = {
        return Users(configuration: self.configuration, session: self)
        }()
    
    public lazy var venues : Venues = {
        return Venues(configuration: self.configuration, session: self)
        }()
    
    public lazy var venueGroups : VenueGroups = {
        return VenueGroups(configuration: self.configuration, session: self)
        }()
    
    public lazy var checkins : Checkins = {
        return Checkins(configuration: self.configuration, session: self)
        }()
    
    public lazy var tips : Tips = {
        return Tips(configuration: self.configuration, session: self)
        }()
    
    public lazy var lists : Lists = {
        return Lists(configuration: self.configuration, session: self)
        }()
    
    public lazy var updates : Updates = {
        return Updates(configuration: self.configuration, session: self)
        }()
    
    public lazy var photos : Photos = {
        return Photos(configuration: self.configuration, session: self)
        }()
    
    public lazy var settings : Settings = {
        return Settings(configuration: self.configuration, session: self)
        }()
    
    public lazy var specials : Specials = {
        return Specials(configuration: self.configuration, session: self)
        }()
    
    public lazy var events : Events = {
        return Events(configuration: self.configuration, session: self)
        }()
    
    public lazy var pages : Pages = {
        return Pages(configuration: self.configuration, session: self)
        }()
    
    public lazy var pageUpdates : PageUpdates = {
        return PageUpdates(configuration: self.configuration, session: self)
        }()
    
    public lazy var multi : Multi = {
        return Multi(configuration: self.configuration, session: self)
        }()
    
    public init(configuration: Configuration, completionQueue: NSOperationQueue) {
        self.configuration = configuration
        let URLConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.URLSession = NSURLSession(configuration: URLConfiguration, delegate: nil, delegateQueue: completionQueue)
        if configuration.debugEnabled {
            self.logger = ConsoleLogger()
        }
    }
    
    public convenience init(configuration: Configuration) {
        self.init(configuration:configuration, completionQueue: NSOperationQueue.mainQueue())
    }
    
    public class func setupSharedSessionWithConfiguration(configuration: Configuration) {
        if _sharedSession == nil {
            _sharedSession = Session(configuration: configuration)
        } else {
            fatalError("You shouldn't call call setupSharedSessionWithConfiguration twice!")
        }
    }
    
    public class func sharedSession() -> Session {
        if _sharedSession == nil {
            fatalError("You must call setupSharedInstanceWithConfiguration before!")
        }
        return _sharedSession!
    }
    
    /** Whether session is authorized or not. */
    public func isAuthorized() -> Bool {
        let keychain = Keychain(configuration: self.configuration)
        let (accessToken, _) = keychain.accessToken()
        return accessToken != nil
    }
    
    /** 
        Removes access token from keychain.
        This method Doesn't post `QuadratSessionDidBecomeUnauthorizedNotification`. 
    */
    public func deauthorize() {
        let keychain = Keychain(configuration: self.configuration)
        keychain.deleteAccessToken()
    }
    
    func processResponse(response: Response) {
        if response.HTTPSTatusCode == 401 && self.isAuthorized() {
            self.deathorizeAndNotify()
        }
        self.logger?.session(self, didReceiveResponse: response)
    }
    
    func processError(error: NSError) {
        self.logger?.session(self, didGetError: error)
    }

    private func deathorizeAndNotify() {
        self.deauthorize()
        dispatch_async(dispatch_get_main_queue()) {
            let name = QuadratSessionDidBecomeUnauthorizedNotification
            NSNotificationCenter.defaultCenter().postNotificationName(name, object: self)
        }
    }
    
}



