import Foundation

/// Defines where the user defaults are stored
public enum TimeStoragePolicy {
    /// Uses `UserDefaults.Standard`
    case standard
    /// Attempts to use the specified App Group ID (which is the String) to access shared storage.
    case appGroup(String)
    /// Uses simple memory storage
    case memory

    /// Creates an instance
    ///
    /// - parameter appGroupID: The App Group ID that maps to a shared container for `UserDefaults`. If this
    ///                         is nil, the resulting instance will be `.standard`
    public init(appGroupID: String?) {
        if let appGroupID = appGroupID {
            self = .appGroup(appGroupID)
        } else {
            self = .standard
        }
    }
}

/// Handles saving and retrieving instances of `TimeFreeze` for quick retrieval
public struct TimeStorage {
    private var storage: TimeStorageSource

    /// The most recent stored `TimeFreeze`. Getting retrieves from the UserDefaults defined by the storage
    /// policy. Setting sets the value in UserDefaults
    var stableTime: TimeFreeze? {
        get {
            return storage.stableTime
        }

        set {
            self.storage.stableTime = newValue
        }
    }

    /// Creates an instance
    ///
    /// - parameter storagePolicy: Defines the storage location of `UserDefaults`
    public init(storagePolicy: TimeStoragePolicy) {
        switch storagePolicy {
        case .standard:
            self.storage = TimeStorageUserDefaults()
        case .appGroup(let groupName):
            self.storage = TimeStorageUserDefaults(groupName: groupName)
        case .memory:
            self.storage = TimeStorageMemory()
        }
    }
}

protocol TimeStorageSource {
    var stableTime: TimeFreeze? { get set }
}

class TimeStorageUserDefaults: TimeStorageSource {
    private var userDefaults: UserDefaults
    public static let kDefaultsKey = "KronosStableTime"

    init() {
        self.userDefaults = .standard
    }

    init(groupName: String) {
        self.userDefaults = UserDefaults(suiteName: groupName) ?? .standard
    }

    /// The most recent stored `TimeFreeze`. Getting retrieves from the UserDefaults defined by the storage
    /// policy. Setting sets the value in UserDefaults
    var stableTime: TimeFreeze? {
        get {
            guard let stored = self.userDefaults.value(forKey: TimeStorageUserDefaults.kDefaultsKey) as? [String: TimeInterval],
                let previousStableTime = TimeFreeze(from: stored) else
            {
                return nil
            }

            return previousStableTime
        }

        set {
            guard let newFreeze = newValue else {
                return
            }

            self.userDefaults.set(newFreeze.toDictionary(), forKey: TimeStorageUserDefaults.kDefaultsKey)
        }
    }
}

class TimeStorageMemory: TimeStorageSource {
    private var stored: [String: TimeInterval]?

    /// The most recent stored `TimeFreeze`. Getting retrieves from the UserDefaults defined by the storage
    /// policy. Setting sets the value in UserDefaults
    var stableTime: TimeFreeze? {
        get {
            guard let stored = self.stored, let previousStableTime = TimeFreeze(from: stored) else {
                return nil
            }

            return previousStableTime
        }

        set {
            guard let newFreeze = newValue else {
                return
            }

            self.stored = newFreeze.toDictionary()
        }
    }
}

