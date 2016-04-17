import Foundation
import JaredFramework

struct MessageRouting {
    var modules:[RoutingModule] = []
    var supportDir: NSURL?
    
    init () {
        let filemanager = NSFileManager.defaultManager()
        let appsupport = filemanager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)[0]
        let supportDir = appsupport.URLByAppendingPathComponent("Jared")
        let pluginDir = supportDir.URLByAppendingPathComponent("Plugins")
        
        try! filemanager.createDirectoryAtURL(supportDir, withIntermediateDirectories: true, attributes: nil)
        try! filemanager.createDirectoryAtURL(pluginDir, withIntermediateDirectories: true, attributes: nil)
        
        print(supportDir.absoluteString)
        
        
        //let path = "/Users/Zeke/Library/Developer/Xcode/DerivedData/EmoteModule-abvbbpvesnwseuaewkvascbwqpan/Build/Products/Debug/EmoteModule.bundle"
        //let myBundle = NSBundle(path: path)
        //let principleclass = myBundle?.principalClass as? RoutingModule.Type
        //let obj: RoutingModule = principleclass!.init()
        //print(obj.description)
        
        loadPlugins(pluginDir)
        
        let internalModules: [RoutingModule] = [CoreModule(), RESTModule(), TwitterModule(), EpicModule()]
        
        modules.appendContentsOf(internalModules)
    }
    
    
    mutating func loadPlugins(pluginDir: NSURL) {
        let filemanager = NSFileManager.defaultManager()
        let files = filemanager.enumeratorAtURL(pluginDir, includingPropertiesForKeys: [], options: [.SkipsHiddenFiles, .SkipsPackageDescendants], errorHandler: nil)
        while let file = files?.nextObject() {
            if let currentURL = file as? NSURL {
                if currentURL.pathExtension == "bundle" {
                    if let myBundle = NSBundle(URL: currentURL) {
                        let principleClass = myBundle.principalClass as? RoutingModule.Type
                        if let module: RoutingModule = principleClass?.init() {
                            print(module.description)
                            modules.append(module)
                        }
                    }
                }
            }
        }
    }
    
    mutating func reloadPlugins() {
        let appsupport = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)[0]
        let supportDir = appsupport.URLByAppendingPathComponent("Jared")
        let pluginDir = supportDir.URLByAppendingPathComponent("Plugins")
        
        modules = []
        loadPlugins(pluginDir)
    }
    
    func sendSingleDocumentation(routeName: String, forRoom: Room) {
        for aModule in modules {
            for aRoute in aModule.routes {
                if aRoute.name.lowercaseString == routeName.lowercaseString {
                    var documentation = "Command: "
                    documentation += routeName
                    documentation += "\n===========\n"
                    if aRoute.description != nil {
                        documentation += aRoute.description!
                    }
                    else {
                        documentation += "Description not provided."
                    }
                    documentation += "\n\n"
                    if let parameterString = aRoute.parameterSyntax {
                        documentation += "Parameters: "
                        documentation += parameterString
                    }
                    else {
                        documentation += "The developer of this route did not provide parameter documentation."
                    }
                    SendText(documentation, toRoom: forRoom)
                }
            }
        }
    }
    
    func sendDocumentation(myMessage: String, forRoom: Room) {
        let parsedMessage = myMessage.componentsSeparatedByString(",")
        
        if parsedMessage.count > 1 {
            sendSingleDocumentation(parsedMessage[1], forRoom: forRoom)
            return
        }
        
        var documentation: String = ""
        for aModule in modules {
            documentation += String(aModule.dynamicType)
            documentation += ": "
            documentation += aModule.description
            documentation += "\n==============\n"
            
            for aRoute in aModule.routes {
                documentation += aRoute.name
                documentation += ": "
                
                if let aRouteDescription = aRoute.description {
                    documentation += aRouteDescription
                    documentation += "\n"
                }
            }
            documentation += "\n"
        }
        SendText(documentation, toRoom: forRoom)
    }
    
    mutating func routeMessage(myMessage: String, fromBuddy: String, forRoom: Room) {
        
        let detector = try! NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        let matches = detector.matchesInString(myMessage, options: [], range: NSMakeRange(0, myMessage.characters.count))
        let myLowercaseMessage = myMessage.lowercaseString
        
        
        if myLowercaseMessage.containsString("/help") {
            sendDocumentation(myMessage, forRoom: forRoom)
        }
        else if myLowercaseMessage == "/reload" {
            reloadPlugins()
        }
        else {
            RootLoop: for aModule in modules {
                for aRoute in aModule.routes {
                    for aComparison in aRoute.comparisons {
                        
                        if aComparison.0 == .ContainsURL {
                            for match in matches {
                                let url = (myMessage as NSString).substringWithRange(match.range)
                                for comparisonString in aComparison.1 {
                                    if url.containsString(comparisonString) {
                                        aRoute.call(url, forRoom)
                                    }
                                }
                            }
                        }
                            
                            
                        else if aComparison.0 == .StartsWith {
                            for comparisonString in aComparison.1 {
                                if myLowercaseMessage.hasPrefix(comparisonString.lowercaseString) {
                                    aRoute.call(myMessage, forRoom)
                                    break RootLoop
                                }
                            }
                        }
                            
                        else if aComparison.0 == .Contains {
                            for comparisonString in aComparison.1 {
                                if myLowercaseMessage.containsString(comparisonString.lowercaseString) {
                                    aRoute.call(myMessage, forRoom)
                                    break RootLoop
                                }
                            }
                        }
                            
                        else if aComparison.0 == .Is {
                            for comparisonString in aComparison.1 {
                                if myLowercaseMessage == comparisonString.lowercaseString {
                                    aRoute.call(myMessage, forRoom)
                                    break RootLoop
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

