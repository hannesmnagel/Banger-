//
//  GameCenterWrapper.swift
//  Banger!
//
//  Created by Hannes Nagel on 6/23/25.
//

import SwiftUI
import GameKit

// MARK: - Game Center View Wrapper
struct GameCenterView: UIViewControllerRepresentable {
    let state: GKGameCenterViewControllerState
    let dismiss: () -> Void
    
    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let viewController = GKGameCenterViewController(state: state)
        viewController.gameCenterDelegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let parent: GameCenterView
        
        init(_ parent: GameCenterView) {
            self.parent = parent
        }
        
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Matchmaker View Wrapper
struct MatchmakerView: UIViewControllerRepresentable {
    let request: GKMatchRequest
    let onMatchFound: (GKMatch) -> Void
    let onCancel: () -> Void
    let onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> GKMatchmakerViewController {
        let viewController = GKMatchmakerViewController(matchRequest: request)!
        viewController.matchmakerDelegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: GKMatchmakerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GKMatchmakerViewControllerDelegate {
        let parent: MatchmakerView
        
        init(_ parent: MatchmakerView) {
            self.parent = parent
        }
        
        func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
            parent.onCancel()
        }
        
        func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
            parent.onError(error)
        }
        
        func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
            parent.onMatchFound(match)
        }
    }
}

// MARK: - Authentication View
struct GameCenterAuthView: UIViewControllerRepresentable {
    let onAuthenticated: () -> Void
    let onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        return context.coordinator.authViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onAuthenticated: onAuthenticated, onError: onError)
    }
    
    class Coordinator: NSObject {
        let authViewController = UIViewController()
        let onAuthenticated: () -> Void
        let onError: (Error) -> Void
        
        init(onAuthenticated: @escaping () -> Void, onError: @escaping (Error) -> Void) {
            self.onAuthenticated = onAuthenticated
            self.onError = onError
            super.init()
            authenticatePlayer()
        }
        
        private func authenticatePlayer() {
            GKLocalPlayer.local.authenticateHandler = { viewController, error in
                if let viewController = viewController {
                    self.authViewController.present(viewController, animated: true)
                } else if let error = error {
                    self.onError(error)
                } else {
                    self.onAuthenticated()
                }
            }
        }
    }
}

// MARK: - Modern SwiftUI GameCenter Integration
extension View {
    func gameCenter(
        isPresented: Binding<Bool>,
        state: GKGameCenterViewControllerState = .default
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            GameCenterView(state: state) {
                isPresented.wrappedValue = false
            }
        }
    }
    
    func matchmaker(
        isPresented: Binding<Bool>,
        request: GKMatchRequest,
        onMatchFound: @escaping (GKMatch) -> Void,
        onError: @escaping (Error) -> Void = { _ in }
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            MatchmakerView(
                request: request,
                onMatchFound: { match in
                    isPresented.wrappedValue = false
                    onMatchFound(match)
                },
                onCancel: {
                    isPresented.wrappedValue = false
                },
                onError: { error in
                    isPresented.wrappedValue = false
                    onError(error)
                }
            )
        }
    }
}