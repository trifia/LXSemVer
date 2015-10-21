//
//  Version.swift
//  LXSemVer
//
//  Created by Stan Chang Khin Boon on 21/10/15.
//  Copyright © 2015 lxcid. All rights reserved.
//

import Foundation

struct DotSeparatedValues {
    let values: [String]
    
    init(values: [String]) {
        self.values = values
    }
    
    init(string: String) {
        let values = string.characters.split(".").map(String.init)
        self.init(values: values)
    }
}

extension DotSeparatedValues : Equatable {
}

func ==(lhs: DotSeparatedValues, rhs: DotSeparatedValues) -> Bool {
    return lhs.values == rhs.values
}

extension DotSeparatedValues : Comparable {
}

func <(lhs: DotSeparatedValues, rhs: DotSeparatedValues) -> Bool {
    for (lvalue, rvalue) in zip(lhs.values, rhs.values) {
        if lvalue == rvalue {
            continue
        }
        let lnumOpt = Int(lvalue)
        let rnumOpt = Int(rvalue)
        if let lnum = lnumOpt, let rnum = rnumOpt where lnum < rnum {
            return true
        } else if lnumOpt == nil && rnumOpt == nil && lvalue < rvalue {
            return true
        } else if rnumOpt == nil {
            return true
        }
    }
    return lhs.values.count < rhs.values.count
}

extension DotSeparatedValues : ArrayLiteralConvertible {
    init(arrayLiteral elements: String...) {
        self.init(values: elements)
    }
}

extension DotSeparatedValues : StringLiteralConvertible {
    init(unicodeScalarLiteral value: String) {
        self.init(string: value)
    }
    
    init(extendedGraphemeClusterLiteral value: String) {
        self.init(string: value)
    }
    
    init(stringLiteral value: String) {
        self.init(string: value)
    }
}

extension DotSeparatedValues : CustomStringConvertible {
    var description: String {
        return self.values.joinWithSeparator(".")
    }
}

struct Version {
    // https://github.com/sindresorhus/semver-regex
    static let versionNumberPattern = "(?:0|[1-9][0-9]*)"
    static let prereleasePattern = "(?:-[0-9A-Za-z-]+(?:\\.[0-9A-Za-z-]+)*)"
    static let buildMetadataPattern = "(?:\\+[0-9A-Za-z-]+(?:\\.[0-9A-Za-z-]+)*)"
    static let semanticVersioningPattern = "\\A(\(versionNumberPattern))\\.(\(versionNumberPattern))\\.(\(versionNumberPattern))(\(prereleasePattern)?)(\(buildMetadataPattern)?)\\z"
    
    let major: Int
    let minor: Int
    let patch: Int
    let prerelease: DotSeparatedValues?
    let buildMetadata: DotSeparatedValues?
    
    init(major: Int, minor: Int, patch: Int, prerelease: DotSeparatedValues? = nil, buildMetadata: DotSeparatedValues? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.buildMetadata = buildMetadata
    }
    
    init?(string: String) {
        guard
            let regex = try? NSRegularExpression(pattern: "\\A\(Version.semanticVersioningPattern)\\z", options: []),
            let match = regex.firstMatchInString(string, options: [], range: NSRange(location: 0, length: string.characters.count)),
            let major = Int((string as NSString).substringWithRange(match.rangeAtIndex(1))),
            let minor = Int((string as NSString).substringWithRange(match.rangeAtIndex(2))),
            let patch = Int((string as NSString).substringWithRange(match.rangeAtIndex(3)))
            else {
                return nil
        }
        
        var prerelease: DotSeparatedValues? = nil
        let prereleaseRange = match.rangeAtIndex(4)
        if prereleaseRange.length > 0 {
            let prereleaseString = (string as NSString).substringWithRange(NSRange(location: prereleaseRange.location + 1, length: prereleaseRange.length - 1))
            prerelease = DotSeparatedValues(string: prereleaseString)
        }
        
        var buildMetadata: DotSeparatedValues? = nil
        let buildMetadataRange = match.rangeAtIndex(5)
        if buildMetadataRange.length > 0 {
            let buildMetadataString = (string as NSString).substringWithRange(NSRange(location: buildMetadataRange.location + 1, length: buildMetadataRange.length - 1))
            buildMetadata = DotSeparatedValues(string: buildMetadataString)
        }
        
        self.init(major: major, minor: minor, patch: patch, prerelease: prerelease, buildMetadata: buildMetadata)
    }
}

extension Version : Equatable {
}

func ==(lhs: Version, rhs: Version) -> Bool {
    return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch && lhs.prerelease == rhs.prerelease
}

extension Version : Comparable {
}

func <(lhs: Version, rhs: Version) -> Bool {
    if lhs.major < rhs.major {
        return true
    } else if lhs.minor < rhs.minor {
        return true
    } else if lhs.patch < rhs.patch {
        return true
    } else if let lprv = lhs.prerelease, let rprv = rhs.prerelease where lprv < rprv {
        return true
    } else if lhs.prerelease != nil && rhs.prerelease == nil {
        return true
    } else {
        return false
    }
}

extension Version : CustomStringConvertible {
    var description: String {
        var description = "\(self.major).\(self.minor).\(self.patch)"
        if let prerelease = self.prerelease {
            description += "-\(prerelease)"
        }
        if let buildMetadata = self.buildMetadata {
            description += "+\(buildMetadata)"
        }
        return description
    }
}
