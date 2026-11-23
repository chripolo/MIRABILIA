//
//  PhotoPolicy.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import Foundation

// Single point of truth for photo licensing and URL sizing within Data.
enum PhotoPolicy {

    // MARK: - License allowlist

    private static let allowedLicenses: Set<String> = [
        "cc0",
        "cc-by",
        "cc-by-sa",
        "cc-by-nc",
        "cc-by-nc-sa",
        "cc-by-nd",
        "cc-by-nc-nd",
    ]

    static func isLicenseAllowed(_ licenseCode: String?) -> Bool {
        guard let code = licenseCode else { return false }
        return allowedLicenses.contains(code)
    }

    // Comma-separated list for use in API query parameters.
    static var allowedLicensesQueryValue: String {
        allowedLicenses.sorted().joined(separator: ",")
    }

    // MARK: - Image size conversion

    // iNaturalist photo URLs use size tokens in the path, e.g. `.../photos/123/square.jpg`
    static func mediumURL(fromSquare squareURLString: String) -> URL? {
        let mediumString = squareURLString.replacingOccurrences(of: "/square.", with: "/medium.")
        // Only accept the result if the replacement actually changed the string,
        // otherwise the URL was not in the expected format.
        guard mediumString != squareURLString else { return nil }
        return URL(string: mediumString)
    }

    static func largeURL(fromSquare squareURLString: String) -> URL? {
        let largeString = squareURLString.replacingOccurrences(of: "/square.", with: "/large.")
        guard largeString != squareURLString else { return nil }
        return URL(string: largeString)
    }
}
