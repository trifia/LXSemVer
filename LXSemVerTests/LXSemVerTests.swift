//
//  LXSemVerTests.swift
//  LXSemVerTests
//
//  Created by Stan Chang Khin Boon on 21/10/15.
//  Copyright © 2015 lxcid. All rights reserved.
//

import XCTest
@testable import LXSemVer

// http://stackoverflow.com/a/24029847
extension CollectionType {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Generator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollectionType where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}

private func hasMatch(string: String, regex: NSRegularExpression) -> Bool {
    let numberOfMatches = regex.numberOfMatchesInString(string, options: [], range: NSMakeRange(0, string.characters.count))
    return numberOfMatches > 0
}

class LXSemVerTests: XCTestCase {
    func testVersionNumberPattern() {
        let regex = try! NSRegularExpression(pattern: "\\A\(Version.versionNumberPattern)\\z", options: [])
        
        XCTAssert(hasMatch("0", regex: regex))
        XCTAssertFalse(hasMatch("01", regex: regex))
        XCTAssert(hasMatch("1", regex: regex))
        XCTAssert(hasMatch("9", regex: regex))
        XCTAssert(hasMatch("10", regex: regex))
        XCTAssert(hasMatch("234", regex: regex))
    }
    
    func testPrereleasePattern() {
        let regex = try! NSRegularExpression(pattern: "\\A\(Version.prereleasePattern)\\z", options: [])
        
        XCTAssert(hasMatch("-alpha", regex: regex))
        XCTAssert(hasMatch("-alpha.1", regex: regex))
        XCTAssert(hasMatch("-0.3.7", regex: regex))
        XCTAssert(hasMatch("-x.7.z.92", regex: regex))
    }
    
    func testBuildMetadataPattern() {
        let regex = try! NSRegularExpression(pattern: "\\A\(Version.buildMetadataPattern)\\z", options: [])
        
        XCTAssert(hasMatch("+001", regex: regex))
        XCTAssert(hasMatch("+20130313144700", regex: regex))
        XCTAssert(hasMatch("+exp.sha.5114f85", regex: regex))
    }
    
    func testSemanticVersioningPattern() {
        let regex = try! NSRegularExpression(pattern: "\\A\(Version.semanticVersioningPattern)\\z", options: [])
        
        XCTAssert(hasMatch("0.0.0", regex: regex))
        XCTAssert(hasMatch("0.0.0-alpha", regex: regex))
        XCTAssert(hasMatch("1.0.0-alpha+001", regex: regex))
        
        XCTAssert(hasMatch("1.0.0-alpha", regex: regex))
        XCTAssert(hasMatch("1.0.0-alpha.1", regex: regex))
        XCTAssert(hasMatch("1.0.0-0.3.7", regex: regex))
        XCTAssert(hasMatch("1.0.0-x.7.z.92", regex: regex))
        
        XCTAssert(hasMatch("1.0.0-alpha+001", regex: regex))
        XCTAssert(hasMatch("1.0.0+20130313144700", regex: regex))
        XCTAssert(hasMatch("1.0.0-beta+exp.sha.5114f85", regex: regex))
    }
    
    func testVersion() {
        XCTAssertEqual(Version(string: "0.0.0")!, Version(major: 0, minor: 0, patch: 0))
        XCTAssertEqual(Version(string: "0.0.0-alpha")!, Version(major: 0, minor: 0, patch: 0, prerelease: [ "alpha" ]))
        XCTAssertEqual(Version(string: "1.0.0-beta.2+exp.sha.5114f85")!, Version(major: 1, minor: 0, patch: 0, prerelease: [ "beta", "2" ], buildMetadata: "exp.sha.5114f85"))
    }
    
    func testDotSeparatedValuesComparison() {
        XCTAssert(DotSeparatedValues(string: "1.0.0") < DotSeparatedValues(string: "2.0.0"))
        XCTAssert(DotSeparatedValues(string: "2.0.0") < DotSeparatedValues(string: "2.1.0"))
        XCTAssert(DotSeparatedValues(string: "2.1.0") < DotSeparatedValues(string: "2.1.1"))
        
        XCTAssertFalse(DotSeparatedValues(string: "1.0.0") > DotSeparatedValues(string: "2.0.0"))
        XCTAssertFalse(DotSeparatedValues(string: "2.0.0") > DotSeparatedValues(string: "2.1.0"))
        XCTAssertFalse(DotSeparatedValues(string: "2.1.0") > DotSeparatedValues(string: "2.1.1"))
        
        XCTAssert(DotSeparatedValues(string: "alpha") < DotSeparatedValues(string: "alpha.1"))
        XCTAssert(DotSeparatedValues(string: "alpha.1") < DotSeparatedValues(string: "alpha.beta"))
        XCTAssert(DotSeparatedValues(string: "alpha.beta") < DotSeparatedValues(string: "beta"))
        XCTAssert(DotSeparatedValues(string: "beta") < DotSeparatedValues(string: "beta.2"))
        XCTAssert(DotSeparatedValues(string: "beta.2") < DotSeparatedValues(string: "beta.11"))
        XCTAssert(DotSeparatedValues(string: "beta.11") < DotSeparatedValues(string: "rc.1"))
        
        XCTAssertFalse(DotSeparatedValues(string: "alpha") > DotSeparatedValues(string: "alpha.1"))
        XCTAssertFalse(DotSeparatedValues(string: "alpha.1") > DotSeparatedValues(string: "alpha.beta"))
    }
    
    func testDotSeparatedValuesNext() {
        XCTAssertEqual(
            DotSeparatedValues(string: "alpha").next(),
            [
                DotSeparatedValues(string: "alpha.1")
            ]
        )
        
        XCTAssertEqual(
            DotSeparatedValues(string: "alpha.1").next(),
            [
                DotSeparatedValues(string: "alpha.2")
            ]
        )
        
        XCTAssertEqual(
            DotSeparatedValues(string: "alpha.beta").next(),
            [
                DotSeparatedValues(string: "alpha.1"),
                DotSeparatedValues(string: "alpha.beta.1")
            ]
        )
        
        XCTAssertEqual(
            DotSeparatedValues(string: "alpha.beta.1").next(),
            [
                DotSeparatedValues(string: "alpha.1"),
                DotSeparatedValues(string: "alpha.beta.2")
            ]
        )
    }
    
    func testSemVer_2_0_0_Spec_2() {
        // Ensure Swift does not overflow when casting the string "-1" to an unsigned integer value.
        XCTAssertNil(UInt("-1"))
        XCTAssertEqual(UInt("0")!, 0)
        XCTAssertEqual(UInt("1")!, 1)
        
        XCTAssertNotNil(Version(string: "1.0.0"))
        XCTAssertNil(Version(string: "01.0.0"))
        XCTAssertNotNil(Version(string: "1.5.0"))
        XCTAssertNil(Version(string: "1.05.0"))
        XCTAssertNotNil(Version(string: "0.1.7"))
        XCTAssertNil(Version(string: "0.1.007"))
        
        XCTAssertNotNil(Version(string: "1.1.1"))
        XCTAssertNil(Version(string: "-1.1.1"))
        XCTAssertNil(Version(string: "1.-1.1"))
        XCTAssertNil(Version(string: "1.1.-1"))
    }
    
    func testSemVer_2_0_0_Spec_11() {
        do {
            XCTAssertLessThan(Version(string: "1.0.0")!, Version(string: "2.0.0")!)
            XCTAssertLessThan(Version(string: "2.0.0")!, Version(string: "2.1.0")!)
            XCTAssertLessThan(Version(string: "2.1.0")!, Version(string: "2.1.1")!)
            
            let versions: [Version] = [
                "1.0.0",
                "2.0.0",
                "2.1.0",
                "2.1.1",
            ]
            XCTAssertEqual(versions.shuffle().sort(<), versions)
        }
        
        XCTAssert(Version(string: "1.0.0-alpha")! < Version(string: "1.0.0")!)
        
        do {
            XCTAssertLessThan(Version(string: "1.0.0-alpha")!, Version(string: "1.0.0-alpha.1")!)
            XCTAssertLessThan(Version(string: "1.0.0-alpha.1")!, Version(string: "1.0.0-alpha.beta")!)
            XCTAssertLessThan(Version(string: "1.0.0-alpha.beta")!, Version(string: "1.0.0-beta")!)
            XCTAssertLessThan(Version(string: "1.0.0-beta")!, Version(string: "1.0.0-beta.2")!)
            XCTAssertLessThan(Version(string: "1.0.0-beta.2")!, Version(string: "1.0.0-beta.11")!)
            XCTAssertLessThan(Version(string: "1.0.0-beta.11")!, Version(string: "1.0.0-rc.1")!)
            XCTAssertLessThan(Version(string: "1.0.0-rc.1")!, Version(string: "1.0.0")!)
            
            let versions: [Version] = [
                "1.0.0-alpha",
                "1.0.0-alpha.1",
                "1.0.0-alpha.beta",
                "1.0.0-beta",
                "1.0.0-beta.2",
                "1.0.0-beta.11",
                "1.0.0-rc.1",
                "1.0.0",
            ]
            XCTAssertEqual(versions.shuffle().sort(<), versions)
        }
    }
    
    func testVersionNext() {
        XCTAssertEqual(
            Version(major: 1, minor: 0, patch: 0).next(),
            [
                Version(major: 1, minor: 0, patch: 1, prerelease: "alpha.1"),
                Version(major: 1, minor: 1, patch: 0, prerelease: "alpha.1"),
                Version(major: 2, minor: 0, patch: 0, prerelease: "alpha.1")
            ]
        )
        
        XCTAssertEqual(
            Version(major: 1, minor: 0, patch: 0, prerelease: "alpha").next(),
            [
                Version(major: 1, minor: 0, patch: 0, prerelease: "alpha.1"),
                Version(major: 1, minor: 0, patch: 0, prerelease: "beta.1")
            ]
        )
        
        XCTAssertEqual(
            Version(major: 1, minor: 0, patch: 0, prerelease: "alpha.1").next(),
            [
                Version(major: 1, minor: 0, patch: 0, prerelease: "alpha.2"),
                Version(major: 1, minor: 0, patch: 0, prerelease: "beta.1")
            ]
        )
        
        XCTAssertEqual(
            Version(major: 1, minor: 0, patch: 0, prerelease: "beta.9").next(),
            [
                Version(major: 1, minor: 0, patch: 0, prerelease: "beta.10"),
                Version(major: 1, minor: 0, patch: 0, prerelease: "rc.1")
            ]
        )
        
        XCTAssertEqual(
            Version(major: 1, minor: 0, patch: 0, prerelease: "rc.3").next(),
            [
                Version(major: 1, minor: 0, patch: 0, prerelease: "rc.4"),
                Version(major: 1, minor: 0, patch: 0)
            ]
        )
    }
}
