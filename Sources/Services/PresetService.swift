import Foundation
import SwiftUI

struct Preset: Codable, Identifiable {
    var id = UUID()
    var name: String
    var r: Int
    var g: Int
    var b: Int
    var brightness: Int = 100
    var mode: UInt8? // Optional mode if it's a dynamic scene
}

class PresetService: ObservableObject {
    @Published var favorites: [Preset] = []
    
    private let storageKey = "user_presets"
    
    init() {
        load()
    }
    
    func save(name: String, r: Int, g: Int, b: Int, brightness: Int, mode: UInt8? = nil) {
        let newPreset = Preset(name: name, r: r, g: g, b: b, brightness: brightness, mode: mode)
        favorites.append(newPreset)
        persist()
    }
    
    func delete(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        persist()
    }
    
    private func persist() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Preset].self, from: data) {
            favorites = decoded
        }
    }
}
