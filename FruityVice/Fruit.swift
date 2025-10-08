// Models/Fruit.swift
import Foundation

struct Fruit: Codable, Identifiable, Hashable {
    let id = UUID()              // для List/Identifiable
    let name: String
    let genus: String
    let family: String
    let order: String
    let nutritions: Nutrition

    enum CodingKeys: String, CodingKey {
        case name, genus, family, order, nutritions
    }
}

struct Nutrition: Codable, Hashable {
    let carbohydrates: Double
    let protein: Double
    let fat: Double
    let calories: Double
    let sugar: Double
}
