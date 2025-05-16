// UserDefaultsExtensions.swift
// MyChores
//
// Created on 2025-05-16.
//

import Foundation

extension UserDefaults {
    /// Check if a key exists in UserDefaults
    /// - Parameter key: The key to check
    /// - Returns: True if the key exists, false otherwise
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
