//
//  Version.swift
//  LXSemVer
//
//  Created by Stan Chang Khin Boon on 21/10/15.
//  Copyright © 2015 lxcid. All rights reserved.
//

import Foundation

public struct Version {
    // https://github.com/sindresorhus/semver-regex
    static let versionNumberPattern = "(?:0|[1-9][0-9]*)"
    static let prereleasePattern = "(?:-[0-9A-Za-z-]+(?:\\.[0-9A-Za-z-]+)*)"
    static let buildMetadataPattern = "(?:\\+[0-9A-Za-z-]+(?:\\.[0-9A-Za-z-]+)*)"
    static let semanticVersioningPattern = "\\A(\(versionNumberPattern))\\.(\(versionNumberPattern))\\.(\(versionNumberPattern))(\(prereleasePattern)?)(\(buildMetadataPattern)?)\\z"
    
    public let major: UInt
    public let minor: UInt
    public let patch: UInt
    public let prerelease: DotSeparatedValues?
    public let buildMetadata: DotSeparatedValues?
    
    public init(major: UInt, minor: UInt, patch: UInt, prerelease: DotSeparatedValues? = nil, buildMetadata: DotSeparatedValues? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.buildMetadata = buildMetadata
    }
    
    public init?(string: String) {
        guard
            let regex = try? NSRegularExpression(pattern: "\\A\(Version.semanticVersioningPattern)\\z", options: []),
            let match = regex.firstMatchInString(string, options: [], range: NSRange(location: 0, length: string.characters.count)),
            let major = UInt((string as NSString).substringWithRange(match.rangeAtIndex(1))),
            let minor = UInt((string as NSString).substringWithRange(match.rangeAtIndex(2))),
            let patch = UInt((string as NSString).substringWithRange(match.rangeAtIndex(3)))
            else {
                return nil
        }
        
        var prerelease: DotSeparatedValues? = nil
        let prereleaseRange = match.rangeAtIndex(4)
        if prereleaseRange.length > 0 {
            let prereleaseString = (string as NSString).substringWithRange(NSRange(location: prereleaseRange.location + 1, length: prereleaseRange.length - 1))
            prerelease = DotSeparatedValues(string: prereleaseString)
            assert(prerelease != nil)
        }
        
        var buildMetadata: DotSeparatedValues? = nil
        let buildMetadataRange = match.rangeAtIndex(5)
        if buildMetadataRange.length > 0 {
            let buildMetadataString = (string as NSString).substringWithRange(NSRange(location: buildMetadataRange.location + 1, length: buildMetadataRange.length - 1))
            buildMetadata = DotSeparatedValues(string: buildMetadataString)
            assert(buildMetadata != nil)
        }
        
        self.init(major: major, minor: minor, patch: patch, prerelease: prerelease, buildMetadata: buildMetadata)
    }
}

extension Version : Equatable {
}

public func ==(lhs: Version, rhs: Version) -> Bool {
    return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch && lhs.prerelease == rhs.prerelease
}

extension Version : Comparable {
}

public func <(lhs: Version, rhs: Version) -> Bool {
    if lhs.major != rhs.major {
        return lhs.major < rhs.major
    } else if lhs.minor != rhs.minor {
        return lhs.minor < rhs.minor
    } else if lhs.patch != rhs.patch {
        return lhs.patch < rhs.patch
    } else if let lprv = lhs.prerelease, let rprv = rhs.prerelease where lprv != rprv {
        return lprv < rprv
    } else if lhs.prerelease != nil && rhs.prerelease == nil {
        return true
    } else {
        return false
    }
}

extension Version : StringLiteralConvertible {
    public init(unicodeScalarLiteral value: String) {
        self.init(string: value)!
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(string: value)!
    }
    
    public init(stringLiteral value: String) {
        self.init(string: value)!
    }
}

extension Version : CustomStringConvertible {
    public var description: String {
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

extension Version {
    public func next() -> [Version] {
        if let prerelease = self.prerelease {
            var versions = prerelease.next().map { Version(major: self.major, minor: self.minor, patch: self.patch, prerelease: $0) }
            if let firstPrereleaseIdentifier = prerelease.values.first?.lowercaseString {
                switch firstPrereleaseIdentifier {
                case "alpha":
                    versions.append(Version(major: self.major, minor: self.minor, patch: self.patch, prerelease: "beta.1"))
                case "beta":
                    versions.append(Version(major: self.major, minor: self.minor, patch: self.patch, prerelease: "rc.1"))
                case "rc":
                    versions.append(Version(major: self.major, minor: self.minor, patch: self.patch))
                    break
                default:
                    break
                }
            }
            return versions
        } else {
            return [
                Version(major: self.major, minor: self.minor, patch: self.patch + 1, prerelease: "alpha.1"),
                Version(major: self.major, minor: self.minor + 1, patch: 0, prerelease: "alpha.1"),
                Version(major: self.major + 1, minor: 0, patch: 0, prerelease: "alpha.1")
            ]
        }
    }
}