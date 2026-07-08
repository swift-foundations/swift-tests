//
//  Test.Trait.Collection.swift
//  swift-tests
//
//  Type-safe, extensible collection of traits backed by Witness.Values.
//

extension Test.Trait {
    /// A type-safe, extensible collection of traits backed by ``Witness/Values``.
    public struct Collection: Sendable {
        /// The underlying witness values storage.
        public var storage: Witness.Values

        /// Creates an empty trait collection.
        public init() {
            self.storage = Witness.Values()
        }

        /// Converts from the Layer 1 enum-based trait array.
        ///
        /// - Parameter traits: The array of enum-based traits to convert.
        public init(from traits: [Test.Trait]) {
            self.storage = Witness.Values()
            for trait in traits {
                switch trait.kind {
                case .timeLimit(let duration):
                    storage[TimeLimit.self] = duration

                case .tag(let name):
                    var tags = storage[Tag.self]
                    tags.insert(name)
                    storage[Tag.self] = tags

                case .enabled(let flag, let comment):
                    storage[Enabled.self] = Enabled(isEnabled: flag, comment: comment)

                case .bug(let id, let comment):
                    storage[Bug.self] = Bug(id: id, comment: comment)

                case .serialized:
                    storage[Serialized.self] = true

                case .exclusive(let group):
                    storage[Exclusive.self] = Exclusive(group: group)

                case .timed(let config):
                    storage[Timed.self] = config
                }
            }
        }

        /// Creates a trait collection from modifiers.
        ///
        /// - Parameter modifiers: The modifiers to apply.
        public init(modifiers: [Modifier]) {
            self.storage = Witness.Values()
            for modifier in modifiers {
                modifier.apply(to: &self)
            }
        }
    }
}

extension Test.Trait.Collection {
    /// Type-safe subscript for any witness key.
    public subscript<K: Witness.Key>(key: K.Type) -> K.Value where K.Value: Copyable {
        get { storage[key] }
        set { storage[key] = newValue }
    }
}
