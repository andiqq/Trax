//
//  GPX.swift
//  Trax
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//
//  Very simple GPX file parser.
//  Only verified to work for CS193p demo purposes!
//
//  Adapted to Swift 5



import Foundation

class GPX: NSObject, XMLParserDelegate
{
    // MARK: - Public API

    var waypoints = [Waypoint]()
    var tracks = [Track]()
    var routes = [Track]()
    
    typealias GPXCompletionHandler = (GPX?) -> Void
    
    class func parse(url: URL, completionHandler: @escaping GPXCompletionHandler) {
        GPX(url: url, completionHandler: completionHandler).parse()
    }
    
    // MARK: - Public Classes
    
    class Track: Entry
    {
        var fixes = [Waypoint]()
        
        override var description: String {
            let descriptions = fixes.map {$0.description }.joined(separator: "\n")
            let waypointDescription = "fixes=[\n" + descriptions + "\n]"
            return [super.description,waypointDescription].joined(separator: " ")
            
        }
    }
    
    class Waypoint: Entry
    {
        var latitude: Double
        var longitude: Double
        
        init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
            super.init()
        }
        
        var info: String? {
            set { attributes["desc"] = newValue }
            get { return attributes["desc"] }
        }
        lazy var date: Date? = self.attributes["time"]?.asGpxDate
        
        override var description: String {
            return ["lat=\(latitude)", "lon=\(longitude)",
            super.description].joined(separator: " ")
        }
    }
    
    class Entry: NSObject
    {
        var links = [Link]()
        var attributes = [String:String]()
        
        var name: String? {
            set { attributes["name"] = newValue }
            get { return attributes["name"] }
        }
        
        override var description: String {
            var descriptions = [String]()
            if attributes.count > 0 { descriptions.append("attributes=\(attributes)") }
            if links.count > 0 { descriptions.append("links=\(links)") }
            return descriptions.joined(separator: " ")
        }
    }
    
    class Link
    {
        var href: String
        var linkattributes = [String:String]()
        
        init(href: String) { self.href = href }
        
        var url: URL? { return URL(string: href) }
        var text: String? { return linkattributes["text"] }
        var type: String? { return linkattributes["type"] }
        
        var description: String {
            var descriptions = [String]()
            descriptions.append("href=\(href)")
            if linkattributes.count > 0 { descriptions.append("linkattributes=\(linkattributes)") }
            return "[" + descriptions.joined(separator: " ") + "]"
        }
    }
    
    override var description: String {
        var descriptions = [String]()
        if waypoints.count > 0 { descriptions.append("waypoints = \(waypoints)") }
        if tracks.count > 0 { descriptions.append("tracks = \(tracks)") }
        if routes.count > 0 { descriptions.append("routes = \(routes)") }
        return descriptions.joined(separator: " ")
    }

    // MARK: - Private Implementation

    private let url: URL
    private let completionHandler: GPXCompletionHandler
    
    private init(url: URL, completionHandler: @escaping GPXCompletionHandler) {
        self.url = url
        self.completionHandler = completionHandler
    }
    
    private func complete(success: Bool) {
        DispatchQueue.main.async {
            self.completionHandler(success ? self : nil)
        }
    }
    
    private func fail() { complete(success: false) }
    private func succeed() { complete(success: true) }
    
    private func parse() {
        if let data1 = NSData(contentsOf: self.url) {
            let data = data1 as Data
            
            //  these 2 lines are useful if sth goes wrong with the xml parsing:
             let debugString = String(data: data, encoding: .utf8)!
              print(debugString)
            
                let parser = XMLParser(data: data)
                parser.delegate = self
                parser.shouldProcessNamespaces = false
                parser.shouldReportNamespacePrefixes = false
                parser.shouldResolveExternalEntities = false
                parser.parse()
            } else {
                self.fail()
            }
    }

    func parserDidEndDocument(_ parser: XMLParser) { succeed() }
    private func parser(parser: XMLParser!, parseErrorOccurred parseError: Error!) { fail() }
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) { fail() }
    
    private var input = ""

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        input += string
    }
    
    private var waypoint: Waypoint?
    private var track: Track?
    private var link: Link?
    
    internal func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        //print (elementName as Any)
        switch elementName {
            case "trkseg":
                if track == nil { fallthrough }
            case "trk":
                tracks.append(Track())
                track = tracks.last
            case "rte":
                routes.append(Track())
                track = routes.last
            case "rtept", "trkpt", "wpt":
                let latitude = Double(attributeDict["lat"]!)
                let longitude = Double(attributeDict["lon"]!)
                waypoint = Waypoint(latitude: latitude!, longitude: longitude!)
            case "link":
                link = Link(href: attributeDict["href"]!)
            default: break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
            case "wpt":
                if waypoint != nil { waypoints.append(waypoint!); waypoint = nil }
            case "trkpt", "rtept":
                if waypoint != nil { track?.fixes.append(waypoint!); waypoint = nil }
            case "trk", "trkseg", "rte":
                track = nil
            case "link":
                if link != nil {
                    if waypoint != nil {
                        waypoint!.links.append(link!)
                    } else if track != nil {
                        track!.links.append(link!)
                    }
                }
                link = nil
            default:
                if link != nil {
                    link!.linkattributes[elementName] = input.trimmed
                } else if waypoint != nil {
                    waypoint!.attributes[elementName] = input.trimmed
                } else if track != nil {
                    track!.attributes[elementName] = input.trimmed
                }
                input = ""
        }
    }
}

// MARK: - Extensions

private extension String {
    var trimmed: String {
        return (self as NSString).trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
}

extension String {
    var asGpxDate: Date? {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z"
            return dateFormatter.date(from: self) as Date?
        }
    }
}
