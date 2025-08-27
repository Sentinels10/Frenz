// Models/PlayerInput.swift
import Foundation

public struct PlayerInput: Identifiable, Equatable {
    public let id: Int
    public var name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
