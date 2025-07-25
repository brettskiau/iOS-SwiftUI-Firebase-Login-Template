//
//  SideBarViewMain.swift
//  iOS-SwiftUI-Firebase-Login-Template
//
//  Created by Brett Nathan on 23/7/2025.
//


import SwiftUI
import Firebase

// MARK: - Main Authenticated Sidebar View
struct AuthenticatedSidebarView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Binding var selectedView: String

    // Navigation items adapted for your design
    private let navigationItems = [
        NavigationItem(id: "summary", name: "Summary", icon: "SummaryIcon2",
                      color: Color(hex: "002D35"), height: 170, cornerRadius: 0, isDefault: true),
        NavigationItem(id: "classes", name: "Classes", icon: "ClassesIcon3",
                      color: Color(hex: "FFA12F"), height: 220, cornerRadius: 4),
        NavigationItem(id: "students", name: "Students", icon: "StudentsIcon3",
                      color: Color(hex: "FFBF00"), height: 220, cornerRadius: 4)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header with authenticated user info
            AuthenticatedHeaderView()

            // Navigation Items
            VStack(spacing: 24) {
                ForEach(navigationItems) { item in
                    AuthenticatedNavigationItemView(
                        item: item,
                        isSelected: selectedView == item.name,
                        action: { selectedView = item.name }
                    )
                }
            }
            .padding(.horizontal, 0)
            .padding(.top, 16)

            Spacer()
        }
        .background(Color(hex: "FFF6E2"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Authenticated Header View
struct AuthenticatedHeaderView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingProfile = false
    @State private var showingSettings = false

    var body: some View {
        HStack {
            // Profile Button with authenticated user info
            Button(action: { showingProfile = true }) {
                // User avatar with initial
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 65, height: 65)
                    .overlay(
                        Text(userInitial)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    )
            }
            .popover(isPresented: $showingProfile) {
                AuthenticatedProfileMenuView()
                    .environmentObject(authViewModel)
            }

            Spacer()

            // App Title
            Image("MarkBookIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)

            Spacer()

            // Settings Button
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
                    .frame(width: 65, height: 65)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            .sheet(isPresented: $showingSettings) {
                AuthenticatedSettingsView()
                    .environmentObject(authViewModel)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 0)
        .padding(.bottom, 8)
        .background(Color(hex: "FFF6E2"))
        .overlay(
            Rectangle()
                .frame(height: 3)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }

    // Computed properties for user info
    private var userInitial: String {
        if let displayName = authViewModel.currentUser?.displayName, !displayName.isEmpty {
            return String(displayName.prefix(1).uppercased())
        } else if let email = authViewModel.currentUser?.email {
            return String(email.prefix(1).uppercased())
        } else {
            return "T"
        }
    }
}

// MARK: - Authenticated Navigation Item View
struct AuthenticatedNavigationItemView: View {
    let item: NavigationItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Push content down with spacer
                Spacer(minLength: 20)

                // Icon - try to load custom image, fallback to system icon
                Group {
                    if let uiImage = UIImage(named: item.icon) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        // Fallback system icons
                        Image(systemName: systemIconName(for: item.name))
                            .font(.system(size: 55))
                    }
                }
                .frame(width: 110, height: 110)
                .foregroundColor(isSelected ? .white : .black)

                // Small space before text
                Spacer(minLength: 4)

                // Label at bottom
                Text(item.name)
                    .font(.system(size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .black)
                    .multilineTextAlignment(.center)

                // Push text towards bottom
                Spacer(minLength: 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: item.height)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: item.cornerRadius)
                    .fill(isSelected ? item.color.opacity(0.9) : item.color)
            )
        }
        .scaleEffect(isSelected ? 1.0 : 1.0)
        .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 4)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // Helper function for fallback system icons
    private func systemIconName(for viewName: String) -> String {
        switch viewName.lowercased() {
        case "summary":
            return "chart.bar.fill"
        case "classes":
            return "building.2.fill"
        case "students":
            return "person.3.fill"
        default:
            return "square.fill"
        }
    }
}

// MARK: - Authenticated Profile Menu View
struct AuthenticatedProfileMenuView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showSignOutConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User info section
            VStack(alignment: .leading, spacing: 8) {
                Text(userName)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(userEmail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            Button("Account Settings") {
                // Account action
            }
            .padding()

            Divider()

            Button("Sign Out") {
                showSignOutConfirmation = true
            }
            .foregroundColor(.red)
            .padding()
        }
        .frame(width: 200)
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

    private func signOut() {
        Task {
            await authViewModel.signOut()
        }
    }
}

// MARK: - Authenticated Settings View
struct AuthenticatedSettingsView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // User info section
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(userInitial)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        )

                    Text(userName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(userEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()

                Divider()

                // Settings options
                VStack(alignment: .leading, spacing: 16) {
                    SettingsRow(icon: "person.circle", title: "Profile Settings")
                    SettingsRow(icon: "bell", title: "Notifications")
                    SettingsRow(icon: "lock", title: "Privacy & Security")
                    SettingsRow(icon: "questionmark.circle", title: "Help & Support")
                }
                .padding()

                Spacer()

                // Sign out button
                Button(action: {
                    Task {
                        await authViewModel.signOut()
                    }
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red, lineWidth: 1)
                        )
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

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
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.orange)

            Text(title)
                .font(.body)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            // Handle settings row tap
        }
    }
}

// MARK: - Navigation Item Model (keep your existing one)
struct NavigationItem: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let height: CGFloat
    let cornerRadius: CGFloat
    let isDefault: Bool

    init(id: String, name: String, icon: String, color: Color, height: CGFloat, cornerRadius: CGFloat, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.height = height
        self.cornerRadius = cornerRadius
        self.isDefault = isDefault
    }
}

// MARK: - Color Extension (keep your existing one)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
