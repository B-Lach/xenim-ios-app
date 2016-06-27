//
//  HelperExtensions.swift
//  Xenim
//
//  Created by Stefan Trauth on 06/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit
import MediaPlayer

extension CMTime {
    func humanReadable() -> (minutes: Int, seconds: Int) {
        guard !self.isIndefinite else {
            return (0,0)
        }
        let totalSeconds = CMTimeGetSeconds(self)
        let minutes = Int(floor(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60))
        let seconds = Int(floor(totalSeconds.truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60)))
        return (minutes, seconds)
    }
}



extension Array {
    func orderedIndexOf(_ elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

extension UIApplication {
    func appVersion() -> String? {
        if let version = Bundle.main().infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main().infoDictionary?[kCFBundleVersionKey as String] as? String {
            return "Version \(version) (\(build))"
        }
        return nil
    }
}

class DateViewGenerator: NSObject {
    static func generateLabelsFromDate(_ eventDate: Date, showsDate: Bool) -> (topLabelString: String, bottomLabelString: String, accessibilityValue: String) {
        
        
        let topLabelString: String
        let bottomLabelString: String
        let accessibilityValue: String
        
        // calculate in how many days this event takes place
        let cal = Calendar.current()
        let now = Date()
        var diff = cal.components(Calendar.Unit.day,
                                  from: cal.startOfDay(for: now),
                                  to: eventDate,
                                  options: Calendar.Options.wrapComponents )
        let daysLeft = diff.day
        
        
        if showsDate {
            let formatter = DateFormatter();
            formatter.locale = Locale.current()
            
            formatter.dateStyle = .longStyle
            formatter.timeStyle = .mediumStyle
            accessibilityValue = formatter.string(from: eventDate)
            
            // http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
            
            formatter.setLocalizedDateFormatFromTemplate("HH:mm")
            let time = formatter.string(from: eventDate)
            bottomLabelString = time
            
            if daysLeft < 7 {
                formatter.setLocalizedDateFormatFromTemplate("cccccc")
                var day = formatter.string(from: eventDate)
                day = day.replacingOccurrences(of: ".", with: "")
                day = day.uppercased()
                topLabelString = day
            } else {
                formatter.setLocalizedDateFormatFromTemplate("d.M")
                let date = formatter.string(from: eventDate)
                topLabelString = date
            }
            
            return (topLabelString, bottomLabelString, accessibilityValue)
            
        } else {
            
            diff = cal.components(Calendar.Unit.hour, from: now, to: eventDate, options: Calendar.Options.wrapComponents )
            let hoursLeft = diff.hour
            diff = cal.components(Calendar.Unit.minute, from: now, to: eventDate, options: Calendar.Options.wrapComponents )
            let minutesLeft = diff.minute
            
            // check if there are less than 24 hours left
            // use absolute value here to make it also work for negative values if a show is overdue
            if abs(minutesLeft!) < 1440 {
                // check if there are less than 1 hour left
                if abs(minutesLeft!) < 60 {
                    // show minutes left
                    // could be negative!
                    topLabelString = "\(minutesLeft)"
                    let minutesString = NSLocalizedString("minute", value: "min", comment: "min")
                    bottomLabelString = minutesString
                    accessibilityValue = "\(minutesLeft) \(minutesString) left"
                    return (topLabelString, bottomLabelString, accessibilityValue)
                } else {
                    // show hours left
                    topLabelString = "\(hoursLeft)"
                    let hoursStringSingle = NSLocalizedString("hour", value: "hour", comment: "hour")
                    let hoursStringMultiple = NSLocalizedString("hours", value: "hours", comment: "hours")
                    if hoursLeft == 1 {
                        bottomLabelString = hoursStringSingle
                        accessibilityValue = "\(hoursLeft) \(hoursStringSingle) left"
                    } else {
                        bottomLabelString = hoursStringMultiple
                        accessibilityValue = "\(hoursLeft) \(hoursStringMultiple) left"
                    }
                    return (topLabelString, bottomLabelString, accessibilityValue)
                }
            } else {
                // show days left
                topLabelString = "\(daysLeft)"
                let daysStringSingle = NSLocalizedString("day", value: "day", comment: "day")
                let daysStringMultiple = NSLocalizedString("days", value: "days", comment: "days")
                if daysLeft == 1 {
                    bottomLabelString = daysStringSingle
                    accessibilityValue = "\(daysLeft) \(daysStringSingle) left"
                } else {
                    bottomLabelString = daysStringMultiple
                    accessibilityValue = "\(daysLeft) \(daysStringMultiple) left"
                }
                return (topLabelString, bottomLabelString, accessibilityValue)
            }
        }

    }
}
