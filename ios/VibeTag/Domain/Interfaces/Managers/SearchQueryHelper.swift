//
//  SearchQueryHelper.swift
//  VibeTag
//
//  Created by Francisco Javier Gallego Lahera on 1/2/26.
//

import Foundation

protocol SearchQueryHelping {
    func expandSearchTerm(_ text: String) -> [String]
}