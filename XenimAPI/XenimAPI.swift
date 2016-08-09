import Foundation
import SwiftyJSON
import Alamofire

public class XenimAPI {
    
    // "http://feeds.streams.demo.xenim.de/api/v1/"
    static let apiBaseURL = "http://feeds.streams.demo.xenim.de/api/v2/"
    
    public static func fetchEvents(status: [String]?, maxCount: Int? = 20, onComplete: (events: [Event]) -> Void){
        let url = apiBaseURL + "episode/"
        var parameters = [
            "limit": "\(maxCount!)",
            "order_by": "begin"
        ]
        if let status = status {
            let stringRepresentation = status.joined(separator: ",")
            parameters["status__in"] = stringRepresentation
        }
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                handleMultipleEventsResponse(response, onComplete: onComplete)
        }
    }
    
    public static func fetchEvents(podcastId: String, status: [String]?, maxCount: Int? = 5, onComplete: (events: [Event]) -> Void){
        let url = apiBaseURL + "podcast/\(podcastId)/episodes/"
        var parameters = [
            "limit": "\(maxCount!)",
            "order_by": "begin"
        ]
        if let status = status {
            let stringRepresentation = status.joined(separator: ",")
            parameters["status__in"] = stringRepresentation
        }
        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                handleMultipleEventsResponse(response, onComplete: onComplete)
        }
    }
    
    public static func fetchEvent(eventId: String, onComplete: (event: Event?) -> Void){
        let url = apiBaseURL + "episode/\(eventId)/"
        Alamofire.request(.GET, url, parameters: nil)
            .responseJSON { response in
                if let responseData = response.data {
                    let eventJSON = JSON(data: responseData)
                    eventFromJSON(eventJSON, onComplete: { (event) -> Void in
                        onComplete(event: event)
                    })
                } else {
                    onComplete(event: nil)
                }
        }
    }
    
    public static func fetchPodcast(podcastId: String, onComplete: (podcast: Podcast?) -> Void){
        let url = apiBaseURL + "podcast/\(podcastId)/"
        Alamofire.request(.GET, url, parameters: nil)
            .responseJSON { response in
                if let responseData = response.data {
                    let podcastJSON = JSON(data: responseData)
                    
                    if let podcast = podcastFromJSON(podcastJSON) {
                        onComplete(podcast: podcast)
                    } else {
                        onComplete(podcast: nil)
                    }
                } else {
                    onComplete(podcast: nil)
                }
        }
    }
    
    public static func fetchAllPodcasts(_ onComplete: (podcasts: [Podcast]) -> Void){
        let url = apiBaseURL + "podcast/"
        Alamofire.request(.GET, url, parameters: nil)
            .responseJSON { response in
                var podcasts = [Podcast]()
                if let responseData = response.data {
                    let json = JSON(data: responseData)
                    if let objects = json["objects"].array {
                        for podcastJSON in objects {
                            if let podcast = podcastFromJSON(podcastJSON) {
                                podcasts.append(podcast)
                            }
                        }
                    }
                }
                onComplete(podcasts: podcasts)
        }
    }
    
    // MARK: - Helpers
    
    
    private static func handleMultipleEventsResponse(_ response: Response<AnyObject, NSError>, onComplete: (events: [Event]) -> Void) {
        var events = [Event]()
        if let responseData = response.data {
            let json = JSON(data: responseData)
            if let objects = json["objects"].array {
                
                // return empty array if there is nothing to parse here
                if objects.count == 0 {
                    onComplete(events: events)
                    return
                }
                
                let blocksDispatchQueue = DispatchQueue(label: "com.domain.blocksArray.sync", attributes: DispatchQueue.Attributes.concurrent)
                let serviceGroup = DispatchGroup()
                
                for eventJSON in objects {
                    serviceGroup.enter()
                    eventFromJSON(eventJSON, onComplete: { (event) -> Void in
                        blocksDispatchQueue.async(execute: {
                            if event != nil {
                                // this has to be thread safe
                                events.append(event!)
                            }
                            serviceGroup.leave()
                        })
                    })
                }
                
                serviceGroup.notify(queue: DispatchQueue.global(), execute: {
                    // sort events by time as async processing appends them unordered
                    let sortedEvents = events.sorted(by: { (event1, event2) -> Bool in
                        event1.begin.compare(event2.begin as Date) == .orderedAscending
                    })
                    onComplete(events: sortedEvents)
                })
            } else {
                // return empty array
                onComplete(events: events)
            }
        } else {
            // return empty array
            onComplete(events: events)
        }
    }
    
    private static func podcastFromJSON(_ podcastJSON: JSON) -> Podcast? {
        let id = podcastJSON["id"].stringValue
        let name = podcastJSON["name"].stringValue
        let podcastDescription = podcastJSON["description"].stringValue
        
        let artworkJSON = podcastJSON["artwork"]
        let artwork = Artwork(thumb180Url: artworkJSON["180"].URL, thumb800Url: artworkJSON["800"].URL, thumb1600Url: artworkJSON["1600"].URL, thumb3000Url: artworkJSON["3000"].URL)
        let subtitle: String? = podcastJSON["subtitle"].stringValue != "" ? podcastJSON["subtitle"].stringValue : nil
        let websiteUrl: URL? = podcastJSON["website_url"].stringValue != "" ? podcastJSON["website_url"].URL : nil
        let feedUrl: URL? = podcastJSON["feed_url"].stringValue != "" ? podcastJSON["feed_url"].URL : nil
        let twitterUsername: String? = podcastJSON["twitter_handle"].stringValue != "" ? podcastJSON["twitter_handle"].stringValue : nil
        let email: String? =  podcastJSON["email"].stringValue != "" ? podcastJSON["email"].stringValue : nil
        
        if id != "" && name != "" {
            return Podcast(id: id, name: name, description: podcastDescription, artwork: artwork, subtitle: subtitle, websiteUrl: websiteUrl, feedUrl: feedUrl, email: email, twitterUsername: twitterUsername)
        } else {
            return nil
        }
    }
    
    private static func eventFromJSON(_ eventJSON: JSON, onComplete: (event: Event?) -> Void) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let id = eventJSON["id"].stringValue
        let podcastId = eventJSON["podcast"].stringValue.characters.split{$0 == "/"}.map(String.init).last
        
        let absoluteUrl: URL? = eventJSON["absolute_url"].stringValue != "" ? eventJSON["absolute_url"].URL : nil
        let begin = formatter.date(from: eventJSON["begin"].stringValue)
        let description: String? = eventJSON["description"].stringValue.trim() != "" ? eventJSON["description"].stringValue.trim() : nil
        let end = formatter.date(from: eventJSON["end"].stringValue)
        let shownotes: String? = eventJSON["shownotes"].stringValue.trim() != "" ? eventJSON["shownotes"].stringValue.trim() : nil
        let title: String? = eventJSON["title"].stringValue.trim() != "" ? eventJSON["title"].stringValue.trim() : nil
        let listeners: Int? = eventJSON["listeners"].stringValue != "" ? eventJSON["listeners"].int : nil
        
        var status: Status? = nil
        switch eventJSON["status"].stringValue {
        case "RUNNING": status = .running
        case "UPCOMING": status = .upcoming
        case "ARCHIVED": status = .archived
        case "EXPIRED": status = .expired
        default: break
        }
        
        var streams = [Stream]()
        if let streamsJSON = eventJSON["streams"].array {
            for streamJSON in streamsJSON {
                let bitrate = streamJSON["bitrate"].stringValue
                let codec = streamJSON["codec"].stringValue
                if let url = streamJSON["url"].URL {
                    streams.append(Stream(codec: codec, bitrate: bitrate, url: url))
                }
            }
        }
        
        
        if podcastId != nil {
            fetchPodcast(podcastId: podcastId!) { (podcast) -> Void in
                // only add this event to the list if it has a minimum number
                // of attributes set
                if id != "" && begin != nil && status != nil && podcast != nil {
                    let event = Event(id: id, status: status!, begin: begin!, end: end, podcast: podcast!, title: title, eventXenimWebUrl: absoluteUrl, streams: streams, shownotes: shownotes, description: description, listeners: listeners)
                    onComplete(event: event)
                } else {
                    onComplete(event: nil)
                }
            }
        } else {
            onComplete(event: nil)
        }
        
    }
}
