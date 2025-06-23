//
//  ContentView.swift
//  Banger!
//
//  Created by Hannes Nagel on 6/23/25.
//

import SwiftUI
import GameKit

struct ContentView: View {
    @State private var gameManager = BangGameManager()
    @State private var showingMatchmaker = false
    @State private var showingGameCenter = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Game Title
                VStack {
                    Text("BANG!")
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundColor(.brown)
                    
                    Text("The Wild West Card Game")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Game Options
                VStack(spacing: 16) {
                    // Start Game Section
                    GroupBox("Start Game") {
                        VStack(spacing: 12) {
                            Button(action: {
                                showingMatchmaker = true
                            }) {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                    Text("Choose Players")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(!gameManager.matchAvailable)
                            
                            Toggle("Quick Match", isOn: $gameManager.automatch)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .onChange(of: gameManager.automatch) {
                                    if gameManager.automatch {
                                        Task {
                                            await gameManager.findRandomMatch()
                                        }
                                    } else {
                                        // Cancel automatch if needed
                                    }
                                }
                                .disabled(!gameManager.matchAvailable)
                        }
                        .padding()
                    }
                    .backgroundStyle(.regularMaterial)
                    
                    // Game Center Section
                    GroupBox("Game Center") {
                        VStack(spacing: 12) {
                            Button("Achievements") {
                                showingGameCenter = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Leaderboards") {
                                showingGameCenter = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                    .backgroundStyle(.regularMaterial)
                    .disabled(!gameManager.matchAvailable)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Status
                if !gameManager.matchAvailable {
                    Text("Authenticating with Game Center...")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                // Player Avatar
                HStack {
                    gameManager.myAvatar
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    if gameManager.matchAvailable {
                        Text(GKLocalPlayer.local.displayName)
                            .font(.headline)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            if !gameManager.playingGame {
                gameManager.authenticatePlayer()
            }
        }
        .fullScreenCover(isPresented: $gameManager.playingGame) {
            BangGameView(gameManager: gameManager)
        }
        .alert("Game Over", isPresented: $gameManager.showingGameOver) {
            Button("OK") {
                gameManager.resetGame()
            }
        } message: {
            Text(gameManager.gameOverMessage)
        }
        .matchmaker(
            isPresented: $showingMatchmaker,
            request: gameManager.createMatchRequest(),
            onMatchFound: { match in
                gameManager.startMatch(match)
            },
            onError: { error in
                print("Matchmaker error: \(error.localizedDescription)")
            }
        )
        .gameCenter(isPresented: $showingGameCenter)
        .sheet(isPresented: $gameManager.showingAuthenticationModal) {
            if let authVC = gameManager.authenticationViewController {
                AuthenticationView(viewController: authVC) {
                    gameManager.showingAuthenticationModal = false
                    gameManager.authenticationViewController = nil
                }
            }
        }
    }
}

// SwiftUI wrapper for authentication view controller
struct AuthenticationView: UIViewControllerRepresentable {
    let viewController: UIViewController
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    ContentView()
}
