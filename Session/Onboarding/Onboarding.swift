import Sodium

enum Onboarding {
    
    enum Flow {
        case register, recover, link
        
        func preregister(with seed: Data, ed25519KeyPair: Sign.KeyPair, x25519KeyPair: ECKeyPair) {
            let userDefaults = UserDefaults.standard
            KeyPairUtilities.store(seed: seed, ed25519KeyPair: ed25519KeyPair, x25519KeyPair: x25519KeyPair)
            TSAccountManager.sharedInstance().phoneNumberAwaitingVerification = x25519KeyPair.hexEncodedPublicKey
            let restorationTime: TimeInterval
            switch self {
            case .register:
                userDefaults[.hasViewedSeed] = false
                restorationTime = 0
                userDefaults[.hasSyncedConfiguration] = true
            case .recover, .link:
                userDefaults[.hasViewedSeed] = true
                restorationTime = Date().timeIntervalSince1970
                userDefaults[.hasSyncedConfiguration] = false
            }
            OWSPrimaryStorage.shared().setRestorationTime(restorationTime)
        }
    }
}