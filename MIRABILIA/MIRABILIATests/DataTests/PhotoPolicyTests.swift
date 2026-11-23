//
//  PhotoPolicyTests.swift
//  MIRABILIATests
//
//  Created by Christian Polo on 22/11/26.
//

import Foundation
import Testing
@testable import MIRABILIA

@Suite("PhotoPolicy")
struct PhotoPolicyTests {

    // MARK: - License allowlist

    @Test func cc0IsAllowed()           { #expect(PhotoPolicy.isLicenseAllowed("cc0")) }
    @Test func ccByIsAllowed()          { #expect(PhotoPolicy.isLicenseAllowed("cc-by")) }
    @Test func ccBySaIsAllowed()        { #expect(PhotoPolicy.isLicenseAllowed("cc-by-sa")) }
    @Test func ccByNcIsAllowed()        { #expect(PhotoPolicy.isLicenseAllowed("cc-by-nc")) }
    @Test func ccByNcSaIsAllowed()      { #expect(PhotoPolicy.isLicenseAllowed("cc-by-nc-sa")) }
    @Test func ccByNdIsAllowed()        { #expect(PhotoPolicy.isLicenseAllowed("cc-by-nd")) }
    @Test func ccByNcNdIsAllowed()      { #expect(PhotoPolicy.isLicenseAllowed("cc-by-nc-nd")) }

    @Test func nilLicenseIsRejected()       { #expect(!PhotoPolicy.isLicenseAllowed(nil)) }
    @Test func emptyLicenseIsRejected()     { #expect(!PhotoPolicy.isLicenseAllowed("")) }
    @Test func unknownLicenseIsRejected()   { #expect(!PhotoPolicy.isLicenseAllowed("all-rights-reserved")) }
    @Test func arrsLicenseIsRejected()      { #expect(!PhotoPolicy.isLicenseAllowed("cc-by-sa-4.0")) }

    // MARK: - Image URL conversion

    @Test func squareURLConvertsToMedium() {
        let square = "https://inaturalist-open-data.s3.amazonaws.com/photos/123/square.jpg"
        let expected = "https://inaturalist-open-data.s3.amazonaws.com/photos/123/medium.jpg"
        #expect(PhotoPolicy.mediumURL(fromSquare: square)?.absoluteString == expected)
    }

    @Test func squareURLConvertsToLarge() {
        let square = "https://inaturalist-open-data.s3.amazonaws.com/photos/123/square.jpg"
        let expected = "https://inaturalist-open-data.s3.amazonaws.com/photos/123/large.jpg"
        #expect(PhotoPolicy.largeURL(fromSquare: square)?.absoluteString == expected)
    }

    @Test func urlWithoutSquareTokenReturnsNil() {
        let noSquare = "https://inaturalist-open-data.s3.amazonaws.com/photos/123/original.jpg"
        #expect(PhotoPolicy.mediumURL(fromSquare: noSquare) == nil)
    }

    @Test func malformedURLReturnsNil() {
        // URL(string:) would succeed on most strings, but a truly malformed one should still return nil.
        let malformed = ""
        #expect(PhotoPolicy.mediumURL(fromSquare: malformed) == nil)
    }
}
