//
//  PhotoLicenseTests.swift
//  MIRABILIATests
//
//  Created by Christian Polo on 22/11/26.
//

import Testing
@testable import MIRABILIA

@Suite("PhotoLicense")
struct PhotoLicenseTests {

    @Test func displayNamesAreReadable() {
        #expect(PhotoLicense.displayName("cc-by-nc-sa") == "CC BY-NC-SA")
        #expect(PhotoLicense.displayName("cc-by") == "CC BY")
        #expect(PhotoLicense.displayName("cc0") == "CC0")
    }

    @Test func onlyNoDerivativesLicensesForbidCropping() {
        #expect(PhotoLicense.forbidsDerivatives("cc-by-nd"))
        #expect(PhotoLicense.forbidsDerivatives("cc-by-nc-nd"))
        #expect(!PhotoLicense.forbidsDerivatives("cc-by-nc"))
        #expect(!PhotoLicense.forbidsDerivatives("cc0"))
    }
}
