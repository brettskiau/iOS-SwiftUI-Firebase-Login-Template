
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var sidebarWidth: CGFloat = 0.4 // Start at 40%
    @State private var showMainContent: Bool = false

    // This will check if we have a persisted login
    private var isPersistedLogin: Bool {
        UserDefaults.standard.bool(forKey: "isLoggedIn")
    }

    private var isAuthenticated: Bool {
        authViewModel.state == .signedIn || (isPersistedLogin && authViewModel.currentUser != nil)
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if isAuthenticated {
                    // Authenticated Layout with Animation
                    HStack(spacing: 0) {
                        // Left Sidebar - animated width
                        Group {
                            if showMainContent {
                                // Main app sidebar (will be your MainSidebarView)
                                AuthenticatedSidebarView()
                            } else {
                                // Transition placeholder
                                Color.clear
                            }
                        }
                        .frame(width: geometry.size.width * sidebarWidth)
                        .background(Color.gray.opacity(0.05))

                        // Right Content - animated width
                        Group {
                            if showMainContent {
                                // Main app content (SummaryView)
                                SummaryViewPlaceholder()
                            } else {
                                // Transition placeholder
                                Color.clear
                            }
                        }
                        .frame(width: geometry.size.width * (1 - sidebarWidth))
                    }
                    .onAppear {
                        // Trigger animation when authenticated
                        withAnimation(.easeInOut(duration: 0.8)) {
                            sidebarWidth = 0.3 // Shrink to 30%
                        }

                        // Show main content after sidebar animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                showMainContent = true
                            }
                        }
                    }
                } else {
                    // Login Layout
                    NavigationStack {
                        Login()
                    }
                    .onAppear {
                        // Reset animation state when showing login
                        sidebarWidth = 0.4
                        showMainContent = false
                    }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isAuthenticated)
        }
        .overlay {
            // Show loading indicator when ViewModel is loading
            if authViewModel.isLoading {
                LoadingView()
            }
        }
        .alert(item: errorBinding) { authError in
            Alert(
                title: Text("Error"),
                message: Text(authError.errorDescription ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // Map AuthError to an Identifiable error for alerts
    private var errorBinding: Binding<IdentifiableError?> {
        Binding<IdentifiableError?>(
            get: {
                guard let error = authViewModel.error else { return nil }
                return IdentifiableError(error: error)
            },
            set: { _ in authViewModel.error = nil }
        )
    }
}

// Temporary placeholder views
struct MainSidebarPlaceholder: View {
    var body: some View {
        VStack {
            Text("Main Sidebar")
                .font(.headline)
                .padding()

            Text("(Will be replaced with your MainSidebarView)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue.opacity(0.1))
    }
}

struct SummaryViewPlaceholder: View {
    var body: some View {
        VStack {
            Text("Summary View")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Text("(Will be replaced with your SummaryView)")
                .font(.title2)
                .foregroundColor(.secondary)
                .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green.opacity(0.1))
    }
}

// Helper for making errors identifiable for alerts
struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: AuthError

    var errorDescription: String? {
        error.localizedDescription
    }
}

// MARK: - Authenticated Sidebar with Logout
struct AuthenticatedSidebarView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showSignOutConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with user info
            VStack(alignment: .leading, spacing: 12) {
                // User avatar/initial
                HStack {
                    Circle()
                        .fill(Color.Orange.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(userInitial)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.Orange)
                        )
// Start of SidebarView below
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userName)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(userEmail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                Divider()
            }
            .padding()

            // Navigation Menu (placeholder for now)
            VStack(alignment: .leading, spacing: 8) {
                SidebarMenuItem(icon: "house.fill", title: "Dashboard", isSelected: true)
                SidebarMenuItem(icon: "person.3.fill", title: "Students", isSelected: false)
                SidebarMenuItem(icon: "building.2.fill", title: "Classes", isSelected: false)
                SidebarMenuItem(icon: "doc.text.fill", title: "Assessments", isSelected: false)
                SidebarMenuItem(icon: "gearshape.fill", title: "Settings", isSelected: false)
            }
            .padding(.horizontal)

            Spacer()

            // Logout Section
            VStack(spacing: 0) {
                Divider()

                Button(action: {
                    showSignOutConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding()
                    .background(Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                .confirmationDialog(
                    "Are you sure you want to sign out?",
                    isPresented: $showSignOutConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Sign Out", role: .destructive) {
                        signOut()
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.gray.opacity(0.05))
    }

    // Computed properties for user info
    private var userName: String {
        if let displayName = authViewModel.currentUser?.displayName, !displayName.isEmpty {
            return displayName
        } else {
            return "Teacher"
        }
    }

    private var userEmail: String {
        return authViewModel.currentUser?.email ?? "No email"
    }

    private var userInitial: String {
        return String(userName.prefix(1).uppercased())
    }

    private func signOut() {
        Task {
            await authViewModel.signOut()
        }
    }
}

// MARK: - Sidebar Menu Item Component
struct SidebarMenuItem: View {
    let icon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(isSelected ? .Orange : .secondary)

            Text(title)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .Orange : .primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.Orange.opacity(0.1) : Color.clear)
        )
    }
}

// Preview provider for Xcode previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationViewModel(
                authRepository: FirebaseAuthRepository()
            ))
    }
}
