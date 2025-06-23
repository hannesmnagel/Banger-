//
//  BangModels.swift
//  Banger!
//
//  Created by Hannes Nagel on 6/23/25.
//

import Foundation
import GameKit
import Observation

// MARK: - Role Types
enum Role: String, CaseIterable, Codable {
    case sheriff = "Sheriff"
    case deputy = "Deputy"
    case outlaw = "Outlaw"
    case renegade = "Renegade"
    
    var objective: String {
        switch self {
        case .sheriff:
            return "Eliminate all Outlaws and Renegades"
        case .deputy:
            return "Help the Sheriff win"
        case .outlaw:
            return "Kill the Sheriff"
        case .renegade:
            return "Be the last player standing"
        }
    }
}

// MARK: - Card Types
enum CardType: String, CaseIterable, Codable {
    case bang = "Bang!"
    case missed = "Missed!"
    case beer = "Beer"
    case catBalou = "Cat Balou"
    case panic = "Panic!"
    case stagecoach = "Stagecoach"
    case wellsFargo = "Wells Fargo"
    case generalStore = "General Store"
    case saloon = "Saloon"
    case indians = "Indians!"
    case duel = "Duel"
    case gatling = "Gatling"
    case dynamite = "Dynamite"
    case jail = "Jail"
    case barrel = "Barrel"
    case scope = "Scope"
    case mustang = "Mustang"
    case remington = "Remington"
    case revCarabine = "Rev. Carabine"
    case schofield = "Schofield"
    case winchester = "Winchester"
    case volcanic = "Volcanic"
}

enum CardColor: String, Codable {
    case brown = "Brown"  // Instant effect
    case blue = "Blue"    // Equipment/persistent effect
    case green = "Green"  // Weapon
}

struct Card: Codable, Identifiable, Equatable {
    var id = UUID()
    let type: CardType
    let suit: String
    let value: String
    let color: CardColor
    let description: String
    let range: Int? // For weapons
    
    var isWeapon: Bool {
        color == .green
    }
    
    var isEquipment: Bool {
        color == .blue
    }
    
    var isInstant: Bool {
        color == .brown
    }
}

// MARK: - Character
struct Character: Codable, Identifiable, Equatable {
    var id = UUID()
    let name: String
    let lifePoints: Int
    let ability: String
    let description: String
}

// MARK: - Player
@Observable
class BangPlayer: Identifiable, Equatable, Codable {
    let id: UUID
    let gkPlayer: GKPlayer? // Not codable, excluded from serialization
    var character: Character?
    var role: Role?
    var currentLife: Int
    var maxLife: Int
    var hand: [Card] = []
    var equipment: [Card] = []
    var weapon: Card?
    var isAlive: Bool = true
    var position: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case id, character, role, currentLife, maxLife, hand, equipment, weapon, isAlive, position
    }
    
    init(gkPlayer: GKPlayer? = nil, character: Character? = nil) {
        self.id = UUID()
        self.gkPlayer = gkPlayer
        self.character = character
        self.currentLife = character?.lifePoints ?? 4
        self.maxLife = character?.lifePoints ?? 4
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.gkPlayer = nil // Can't decode GKPlayer
        self.character = try container.decodeIfPresent(Character.self, forKey: .character)
        self.role = try container.decodeIfPresent(Role.self, forKey: .role)
        self.currentLife = try container.decode(Int.self, forKey: .currentLife)
        self.maxLife = try container.decode(Int.self, forKey: .maxLife)
        self.hand = try container.decode([Card].self, forKey: .hand)
        self.equipment = try container.decode([Card].self, forKey: .equipment)
        self.weapon = try container.decodeIfPresent(Card.self, forKey: .weapon)
        self.isAlive = try container.decode(Bool.self, forKey: .isAlive)
        self.position = try container.decode(Int.self, forKey: .position)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        // Skip encoding gkPlayer as it's not codable
        try container.encodeIfPresent(character, forKey: .character)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encode(currentLife, forKey: .currentLife)
        try container.encode(maxLife, forKey: .maxLife)
        try container.encode(hand, forKey: .hand)
        try container.encode(equipment, forKey: .equipment)
        try container.encodeIfPresent(weapon, forKey: .weapon)
        try container.encode(isAlive, forKey: .isAlive)
        try container.encode(position, forKey: .position)
    }
    
    static func == (lhs: BangPlayer, rhs: BangPlayer) -> Bool {
        lhs.id == rhs.id
    }
    
    var displayName: String {
        gkPlayer?.displayName ?? character?.name ?? "Unknown Player"
    }
    
    var weaponRange: Int {
        weapon?.range ?? 1 // Default Colt 45 range
    }
    
    func distanceTo(_ otherPlayer: BangPlayer, in players: [BangPlayer]) -> Int {
        guard let myIndex = players.firstIndex(of: self),
              let otherIndex = players.firstIndex(of: otherPlayer) else {
            return Int.max
        }
        
        let directDistance = abs(myIndex - otherIndex)
        let wrapAroundDistance = players.count - directDistance
        var distance = min(directDistance, wrapAroundDistance)
        
        // Apply equipment modifiers
        if otherPlayer.equipment.contains(where: { $0.type == .mustang }) {
            distance += 1
        }
        
        if equipment.contains(where: { $0.type == .scope }) {
            distance = max(1, distance - 1)
        }
        
        // Apply character ability modifiers
        // Paul Regret: others see him at +1 distance
        if otherPlayer.character?.name == "Paul Regret" {
            distance += 1
        }
        
        // Rose Doolan: sees others at -1 distance
        if character?.name == "Rose Doolan" {
            distance = max(1, distance - 1)
        }
        
        return distance
    }
    
    func canTarget(_ otherPlayer: BangPlayer, in players: [BangPlayer]) -> Bool {
        return distanceTo(otherPlayer, in: players) <= weaponRange
    }
    
    func takeDamage(_ amount: Int = 1) {
        currentLife = max(0, currentLife - amount)
        if currentLife == 0 {
            isAlive = false
        }
    }
    
    func heal(_ amount: Int = 1) {
        currentLife = min(maxLife, currentLife + amount)
    }
    
    func addCard(_ card: Card) {
        hand.append(card)
    }
    
    func removeCard(_ card: Card) {
        hand.removeAll { $0.id == card.id }
    }
    
    func playEquipment(_ card: Card) {
        if card.isWeapon {
            weapon = card
        } else if card.isEquipment {
            equipment.append(card)
        }
        removeCard(card)
    }
}

// MARK: - Game State
enum GamePhase: String, Codable {
    case setup = "Setup"
    case playing = "Playing"
    case gameOver = "Game Over"
}

enum TurnPhase: String, Codable {
    case draw = "Draw"
    case play = "Play"
    case discard = "Discard"
}

@Observable
class GameState: Codable {
    var players: [BangPlayer] = []
    var currentPlayerIndex: Int = 0
    var phase: GamePhase = .setup
    var turnPhase: TurnPhase = .draw
    var deck: [Card] = []
    var discardPile: [Card] = []
    var sheriffIndex: Int = 0
    var winner: Role?
    var bangPlayedThisTurn: Bool = false
    var lastUpdateTimestamp: TimeInterval = Date().timeIntervalSince1970
    
    var currentPlayer: BangPlayer? {
        guard currentPlayerIndex < players.count else { return nil }
        return players[currentPlayerIndex]
    }
    
    var sheriff: BangPlayer? {
        return players.first { $0.role == .sheriff }
    }
    
    func nextPlayer() {
        repeat {
            currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        } while !players[currentPlayerIndex].isAlive && !isGameOver()
        
        bangPlayedThisTurn = false
        turnPhase = .draw
        lastUpdateTimestamp = Date().timeIntervalSince1970
    }
    
    func isGameOver() -> Bool {
        let aliveRoles = players.filter { $0.isAlive }.compactMap { $0.role }
        
        // Sheriff wins if all outlaws and renegades are dead
        if !aliveRoles.contains(.outlaw) && !aliveRoles.contains(.renegade) {
            winner = .sheriff
            return true
        }
        
        // Outlaws win if sheriff is dead
        if !aliveRoles.contains(.sheriff) {
            if aliveRoles.contains(.renegade) {
                winner = .renegade
            } else {
                winner = .outlaw
            }
            return true
        }
        
        // Renegade wins if only renegade is alive
        if aliveRoles.count == 1 && aliveRoles.contains(.renegade) {
            winner = .renegade
            return true
        }
        
        return false
    }
    
    func playerKilled(_ player: BangPlayer, by killer: BangPlayer?) {
        player.isAlive = false
        
        // Reward for killing outlaw
        if player.role == .outlaw && killer?.role != .outlaw {
            // Draw 3 cards as reward
            for _ in 0..<3 {
                if let card = deck.popLast() {
                    killer?.addCard(card)
                }
            }
        }
        
        // Penalty for killing deputy as sheriff
        if player.role == .deputy && killer?.role == .sheriff {
            // Sheriff discards all cards
            killer?.hand.removeAll()
            killer?.equipment.removeAll()
            killer?.weapon = nil
        }
    }
}