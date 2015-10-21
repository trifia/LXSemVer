//
//  LXSemVerTests.swift
//  LXSemVerTests
//
//  Created by Stan Chang Khin Boon on 21/10/15.
//  Copyright © 2015 lxcid. All rights reserved.
//

import XCTest
@testable import LXSemVer

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
    
    func testVersionComparison() {
        XCTAssertLessThan(Version(string: "1.0.0")!, Version(string: "2.0.0")!)
        XCTAssertLessThan(Version(string: "2.0.0")!, Version(string: "2.1.0")!)
        XCTAssertLessThan(Version(string: "2.1.0")!, Version(string: "2.1.1")!)
        
        XCTAssertLessThan(Version(string: "1.0.0-alpha")!, Version(string: "1.0.0-alpha.1")!)
        XCTAssertLessThan(Version(string: "1.0.0-alpha.1")!, Version(string: "1.0.0-alpha.beta")!)
        XCTAssertLessThan(Version(string: "1.0.0-alpha.beta")!, Version(string: "1.0.0-beta")!)
        XCTAssertLessThan(Version(string: "1.0.0-beta")!, Version(string: "1.0.0-beta.2")!)
        XCTAssertLessThan(Version(string: "1.0.0-beta.2")!, Version(string: "1.0.0-beta.11")!)
        XCTAssertLessThan(Version(string: "1.0.0-beta.11")!, Version(string: "1.0.0-rc.1")!)
        XCTAssertLessThan(Version(string: "1.0.0-rc.1")!, Version(string: "1.0.0")!)
        XCTAssertLessThan(Version(string: "1.0.0")!, Version(string: "1.0.1-alpha")!)
        XCTAssertLessThan(Version(string: "1.0.1-alpha")!, Version(string: "1.0.1-alpha.1")!)
    }
}
