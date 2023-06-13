//
//  HelperManager.swift
//  
//
//  Created by Adam on 16/05/2023.
//

import Clients
import Foundation
import Dependencies
import os
import ServiceManagement
import Shared

extension HelperManager: DependencyKey {
    public static let liveValue: HelperManager = {
        let service = SMAppService.daemon(plistName: Constant.helperPlistName)
        let installer = HelperInstaller(service: service)
        let logger = Logger(category: "👹")
        let manager = HelperManager(
            installHelper: {
                do {
                    logger.log(level: .debug, "Installing daemon...")
                    try await installer.registerService()
                    logger.log(level: .debug, "Daemon installed succesfully")
                } catch {
                    logger.error("Daemon registering error: \(error, privacy: .public)")
                    throw error
                }
            },
            removeHelper: {
                do {
                    logger.log(level: .debug, "Removing daemon...")
                    try await installer.unregisterService()
                    logger.log(level: .debug, "Daemon removed")
                } catch {
                    logger.error("Daemon removal error: \(error, privacy: .public)")
                    throw error
                }
            },
            helperStatus: { installer.service.status },
            observeHelperStatus: {
                return AsyncStream<SMAppService.Status> { continuation in
                    let task = Task {
                        for await _ in SuspendingClock().timer(interval: .milliseconds(500)) {
                            continuation.yield(service.status)
                        }
                    }
                    continuation.yield(service.status)
                    continuation.onTermination = { _ in
                        task.cancel()
                    }
                }
            }
        )
        return manager
    }()
}

private actor HelperInstaller {
    let service: SMAppService

    init(service: SMAppService) {
        self.service = service
    }

    func registerService() throws {
        try service.register()
    }

    func unregisterService() async throws {
        try await service.unregister()
    }
}
