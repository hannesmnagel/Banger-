//
//  BangGameView.swift
//  Banger!
//
//  Created by Hannes Nagel on 6/23/25.
//

import SwiftUI
import GameKit

struct BangGameView: View {
    @Bindable var gameManager: BangGameManager
    @State private var selectedCard: Card?
    @State private var selectedTarget: BangPlayer?
    @State private var showingPlayerDetails = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Western-themed background
                    LinearGradient(
                        gradient: Gradient(colors: [Color.brown.opacity(0.3), Color.orange.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                    // Top UI - Opponent Players
                    PlayersCircleView(
                        players: gameManager.gameState.players,
                        localPlayer: gameManager.localPlayer,
                        currentPlayerIndex: gameManager.gameState.currentPlayerIndex,
                        selectedTarget: $selectedTarget
                    )
                    .frame(height: geometry.size.height * 0.4)
                    
                    Spacer()
                    
                    // Center Area - Game Info
                    GameInfoView(gameState: gameManager.gameState)
                        .frame(height: 80)
                    
                    Spacer()
                    
                    // Bottom UI - Local Player
                    LocalPlayerView(
                        gameManager: gameManager,
                        selectedCard: $selectedCard,
                        selectedTarget: $selectedTarget
                    )
                    .frame(height: geometry.size.height * 0.4)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Leave") {
                    gameManager.resetGame()
                }
                .foregroundColor(.red)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Rules") {
                    showingPlayerDetails.toggle()
                }
            }
        }
            .sheet(isPresented: $showingPlayerDetails) {
                GameRulesView()
            }
        }
    }
}

struct PlayersCircleView: View {
    let players: [BangPlayer]
    let localPlayer: BangPlayer?
    let currentPlayerIndex: Int
    @Binding var selectedTarget: BangPlayer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(otherPlayers.enumerated()), id: \.element.id) { index, player in
                    PlayerCardView(
                        player: player,
                        isCurrentPlayer: players.firstIndex(where: { $0.id == player.id }) == currentPlayerIndex,
                        isSelected: selectedTarget?.id == player.id
                    )
                    .position(positionFor(index: index, total: otherPlayers.count, in: geometry.size))
                    .onTapGesture {
                        if selectedTarget?.id == player.id {
                            selectedTarget = nil
                        } else {
                            selectedTarget = player
                        }
                    }
                }
            }
        }
    }
    
    private var otherPlayers: [BangPlayer] {
        return players.filter { $0.id != localPlayer?.id && $0.isAlive }
    }
    
    private func positionFor(index: Int, total: Int, in size: CGSize) -> CGPoint {
        let angle = 2 * Double.pi * Double(index) / Double(total) - Double.pi / 2
        let radius = min(size.width, size.height) * 0.35
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        return CGPoint(
            x: centerX + CGFloat(cos(angle)) * radius,
            y: centerY + CGFloat(sin(angle)) * radius
        )
    }
}

struct PlayerCardView: View {
    let player: BangPlayer
    let isCurrentPlayer: Bool
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Player Avatar
            AsyncImage(url: nil) { _ in
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            .frame(width: 50, height: 50)
            .background(isCurrentPlayer ? Color.yellow.opacity(0.3) : Color.clear)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.red : (isCurrentPlayer ? Color.yellow : Color.clear), lineWidth: 3)
            )
            
            // Player Name
            Text(player.displayName)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: 80)
            
            // Character Name
            if let character = player.character {
                Text(character.name)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 80)
            }
            
            // Life Points
            HStack(spacing: 2) {
                ForEach(0..<player.maxLife, id: \.self) { index in
                    Image(systemName: index < player.currentLife ? "heart.fill" : "heart")
                        .font(.caption2)
                        .foregroundColor(index < player.currentLife ? .red : .gray)
                }
            }
            
            // Role (only if sheriff or dead)
            if player.role == .sheriff || !player.isAlive {
                Text(player.role?.rawValue ?? "")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .background(roleColor(player.role))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private func roleColor(_ role: Role?) -> Color {
        switch role {
        case .sheriff: return .blue
        case .deputy: return .green
        case .outlaw: return .red
        case .renegade: return .purple
        case .none: return .gray
        }
    }
}

struct GameInfoView: View {
    let gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Turn: \(gameState.currentPlayer?.displayName ?? "Unknown")")
                    .font(.headline)
                
                Spacer()
                
                Text("Phase: \(gameState.turnPhase.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(gameState.deck.count)", systemImage: "rectangle.stack")
                    .font(.caption)
                
                Spacer()
                
                Label("\(gameState.discardPile.count)", systemImage: "trash")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct LocalPlayerView: View {
    @Bindable var gameManager: BangGameManager
    @Binding var selectedCard: Card?
    @Binding var selectedTarget: BangPlayer?
    
    private var localPlayer: BangPlayer? {
        gameManager.localPlayer
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Local Player Info
            if let player = localPlayer {
                HStack {
                    VStack(alignment: .leading) {
                        Text(player.displayName)
                            .font(.headline)
                        
                        if let character = player.character {
                            Text(character.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            ForEach(0..<player.maxLife, id: \.self) { index in
                                Image(systemName: index < player.currentLife ? "heart.fill" : "heart")
                                    .font(.caption)
                                    .foregroundColor(index < player.currentLife ? .red : .gray)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Equipment
                    if !player.equipment.isEmpty || player.weapon != nil {
                        VStack {
                            Text("Equipment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                if let weapon = player.weapon {
                                    CardChipView(card: weapon)
                                }
                                
                                ForEach(player.equipment, id: \.id) { equipment in
                                    CardChipView(card: equipment)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(10)
            }
            
            // Hand Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(localPlayer?.hand ?? [], id: \.id) { card in
                        CardView(
                            card: card,
                            isSelected: selectedCard?.id == card.id,
                            canPlay: isMyTurn && BangGameEngine.canPlayCard(card, by: localPlayer!, in: gameManager.gameState)
                        )
                        .onTapGesture {
                            if selectedCard?.id == card.id {
                                selectedCard = nil
                            } else {
                                selectedCard = card
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                if isMyTurn {
                    Button("Draw Cards") {
                        if gameManager.gameState.turnPhase == .draw {
                            BangGameEngine.executeDrawPhase(for: localPlayer!, in: &gameManager.gameState)
                            gameManager.sendGameState()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(gameManager.gameState.turnPhase != .draw)
                    
                    Button("Play Card") {
                        if let card = selectedCard {
                            gameManager.playCard(card, target: selectedTarget)
                            selectedCard = nil
                            selectedTarget = nil
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCard == nil || gameManager.gameState.turnPhase != .play)
                    
                    Button("End Turn") {
                        gameManager.endTurn()
                        selectedCard = nil
                        selectedTarget = nil
                    }
                    .buttonStyle(.bordered)
                    .disabled(gameManager.gameState.turnPhase != .play)
                } else {
                    Text("Wait for your turn...")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    private var isMyTurn: Bool {
        gameManager.gameState.currentPlayer?.id == localPlayer?.id
    }
}

struct CardView: View {
    let card: Card
    let isSelected: Bool
    let canPlay: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Card Icon
            Image(systemName: cardIcon)
                .font(.title2)
                .foregroundColor(cardColor)
            
            // Card Name
            Text(card.type.rawValue)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 24)
            
            // Card Value and Suit
            HStack(spacing: 2) {
                Text(card.value)
                    .font(.caption2)
                Text(card.suit)
                    .font(.caption2)
            }
        }
        .frame(width: 60, height: 80)
        .padding(4)
        .background(isSelected ? Color.blue.opacity(0.3) : Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 2)
        )
        .cornerRadius(8)
        .opacity(canPlay ? 1.0 : 0.6)
    }
    
    private var cardIcon: String {
        switch card.type {
        case .bang: return "target"
        case .missed: return "shield"
        case .beer: return "mug"
        case .catBalou: return "hand.raised"
        case .panic: return "eye"
        case .stagecoach: return "bus"
        case .wellsFargo: return "bus.fill"
        case .saloon: return "building.2"
        case .indians: return "figure.walk"
        case .duel: return "sword.crossed"
        case .gatling: return "scope"
        case .dynamite: return "flame"
        case .jail: return "lock"
        case .barrel: return "cylinder"
        case .scope: return "scope"
        case .mustang: return "car"
        default: return "questionmark.circle"
        }
    }
    
    private var cardColor: Color {
        switch card.color {
        case .brown: return .brown
        case .blue: return .blue
        case .green: return .green
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if canPlay {
            return .green
        } else {
            return .gray
        }
    }
}

struct CardChipView: View {
    let card: Card
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: cardIcon)
                .font(.caption2)
            Text(card.type.rawValue)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(cardColor.opacity(0.2))
        .cornerRadius(8)
    }
    
    private var cardIcon: String {
        switch card.type {
        case .barrel: return "cylinder"
        case .scope: return "scope"
        case .mustang: return "car"
        case .schofield, .remington, .revCarabine, .winchester, .volcanic: return "scope"
        default: return "questionmark.circle"
        }
    }
    
    private var cardColor: Color {
        switch card.color {
        case .brown: return .brown
        case .blue: return .blue
        case .green: return .green
        }
    }
}

struct GameRulesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("BANG! Rules")
                        .font(.title)
                        .bold()
                    
                    Group {
                        RuleSection(title: "Objective", content: "Each role has different goals:\n• Sheriff: Eliminate all Outlaws and Renegades\n• Deputies: Help the Sheriff\n• Outlaws: Kill the Sheriff\n• Renegade: Be the last player standing")
                        
                        RuleSection(title: "Turn Structure", content: "1. Draw 2 cards\n2. Play any number of cards\n3. Discard excess cards")
                        
                        RuleSection(title: "Distance", content: "You can only target players within your weapon range. Default range is 1 (neighboring players).")
                        
                        RuleSection(title: "Key Cards", content: "• BANG!: Deal 1 damage to target\n• Missed!: Cancel a BANG!\n• Beer: Regain 1 life point\n• Equipment: Permanent effects")
                    }
                }
                .padding()
            }
            .navigationTitle("Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RuleSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.brown)
            
            Text(content)
                .font(.body)
        }
    }
}

#Preview {
    BangGameView(gameManager: BangGameManager())
}