//
//  PhotoLicense.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

/// Display helpers for iNaturalist license codes (already validated by Data).
enum PhotoLicense {
    /// "cc-by-nc-sa" -> "CC BY-NC-SA", "cc0" -> "CC0".
    static func displayName(_ code: String) -> String {
        guard code.hasPrefix("cc-") else { return code.uppercased() }
        return "CC " + code.dropFirst(3).uppercased()
    }

    /// ND licenses forbid derivative works, so those photos are never cropped.
    static func forbidsDerivatives(_ code: String) -> Bool {
        code.hasSuffix("-nd")
    }
}
