//
//  SyncService.swift
//  VibeTag
//
//  Created by Francisco Javier Gallego Lahera on 1/2/26.
//

import Foundation

protocol SyncService {
    func syncLibrary() async throws
}