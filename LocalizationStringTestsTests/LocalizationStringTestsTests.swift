//
//  LocalizationStringTestsTests.swift
//  LocalizationStringTestsTests
//
//  Created by SUNG HAO LIN on 2021/6/19.
//

import XCTest
@testable import LocalizationStringTests

class LocalizationStringTestsTests: XCTestCase {

    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let (bundle, table) = makeSUT()

        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }

    func test_localizedStrings_differentKeysHaveSameValue() {
        let (bundle, table) = makeSUT()

        assertLocalizedKeyAndValueUnique(in: bundle, table)
    }

    // MARK: - Helper

    private typealias LocalizedBundle = (bundle: Bundle, localization: String)
    private let undefinedString = "undefinedString"

    private func makeSUT() -> (bundle: Bundle, table: String) {
        let table = "Localizable"
        let bundle = Bundle(for: FakeViewController.self)
        return (bundle, table)
    }

    private func assertLocalizedKeyAndValueUnique(in presentationBundle: Bundle, _ table: String, file: StaticString = #filePath, line: UInt = #line) {
        let localizationBundles = allLocalizationBundles(in: presentationBundle, file: file, line: line)
        let localizedStringKeys = allLocalizedStringKeys(in: localizationBundles, table: table, file: file, line: line)

        localizationBundles.forEach { bundle, localization in
            var result: [String: [String]] = [:]
            localizedStringKeys.forEach { key in
                let valueString = bundle.localizedString(forKey: key, value: undefinedString, table: table)
                if let keys = result[valueString] {
                    let duplicateKeys = keys + [key]
                    result.updateValue(duplicateKeys, forKey: valueString)
                } else {
                    result[valueString] = [key]
                }
            }

            result.filter { $0.value.count > 1 }
                .forEach { (key, value) in
                    let language = Locale.current.localizedString(forLanguageCode: localization) ?? ""
                    XCTFail("The \(language) (\(localization)) localized string keys: '\(value)' have same value '\(key)' in table: '\(table)'", file: file, line: line)
                }
        }
    }

    private func assertLocalizedKeyAndValuesExist(in presentationBundle: Bundle, _ table: String, file: StaticString = #filePath, line: UInt = #line) {
        let localizationBundles = allLocalizationBundles(in: presentationBundle, file: file, line: line)
        let localizedStringKeys = allLocalizedStringKeys(in: localizationBundles, table: table, file: file, line: line)

        localizationBundles.forEach { (bundle, localization) in
            localizedStringKeys.forEach { key in
                let localizedString = bundle.localizedString(forKey: key, value: undefinedString, table: table)

                if localizedString == undefinedString {
                    let language = Locale.current.localizedString(forLanguageCode: localization) ?? ""
                    XCTFail("Missing \(language) (\(localization)) localized string for key: '\(key)' in table: '\(table)'", file: file, line: line)
                }
            }
        }
    }

    private func allLocalizationBundles(in bundle: Bundle, file: StaticString = #file, line: UInt = #line) -> [LocalizedBundle] {
        return bundle.localizations.compactMap { localization in
            guard let path = bundle.path(forResource: localization, ofType: "lproj"), let localizedBundle = Bundle(path: path) else {
                XCTFail("Couldn't find bundle for localization: \(localization)", file: file, line: line)
                return nil
            }

            return (localizedBundle, localization)
        }
    }

    private func allLocalizedStringKeys(in bundles: [LocalizedBundle], table: String, file: StaticString = #file, line: UInt = #line) -> Set<String> {
        return bundles.reduce([]) { acc, current in
            guard let path = current.bundle.path(forResource: table, ofType: "strings"), let strings = NSDictionary(contentsOfFile: path),
                  let keys = strings.allKeys as? [String]
            else {
                XCTFail("Couldn't load localized strings for localization: \(current.localization)", file: file, line: line)
                return acc
            }

            return acc.union(Set(keys))
        }
    }
}
