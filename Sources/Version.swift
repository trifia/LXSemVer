//
//  Version.swift
//  LXSemVer
//
//  Created by Stan Chang Khin Boon on 21/10/15.
//  Copyright © 2015 lxcid. All rights reserved.
//

import Foundation

public struct Version {
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
    
    // Heavily referenced from Swift Package Manager to build a non regex version
    public init?(characters: String.CharacterView) {
        let prereleaseStartIndex = characters.indexOf("-")
        let buildMetadataStartIndex = characters.indexOf("+")
        
        let versionEndIndex = prereleaseStartIndex ?? buildMetadataStartIndex ?? characters.endIndex
        let versionCharacters = characters.prefixUpTo(versionEndIndex)
        let versionComponents = versionCharacters.split(".", maxSplit: 2, allowEmptySlices: true).map{ String($0) }.flatMap{ UInt($0) }
        
        guard versionComponents.count == 3 else {
            return nil
        }
        
        var prerelease: DotSeparatedValues? = nil
        if let prereleaseStartIndex = prereleaseStartIndex {
            let prereleaseEndIndex = buildMetadataStartIndex ?? characters.endIndex
            let prereleaseCharacters = characters[prereleaseStartIndex.successor()..<prereleaseEndIndex]
            prerelease = DotSeparatedValues(characters: prereleaseCharacters)
            if prerelease == nil {
                return nil
            }
        }
        
        var buildMetadata: DotSeparatedValues? = nil
        if let buildMetadataStartIndex = buildMetadataStartIndex {
            let buildMetadataCharacters = characters.suffixFrom(buildMetadataStartIndex.successor())
            buildMetadata = DotSeparatedValues(characters: buildMetadataCharacters)
            if buildMetadata == nil {
                return nil
            }
        }
        
        self.init(major: versionComponents[0], minor: versionComponents[1], patch: versionComponents[2], prerelease: prerelease, buildMetadata: buildMetadata)
    }
    
    public init?(string: String) {
        self.init(characters: string.characters)
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
