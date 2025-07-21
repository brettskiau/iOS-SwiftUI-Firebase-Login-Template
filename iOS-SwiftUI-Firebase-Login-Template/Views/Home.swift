//
//  Home.swift
//
//

import SwiftUI
import FirebaseAuth

struct Home: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showSignOutConfirmation = false

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Side - User Greeting
                VStack(spacing: 24) {
                    Spacer()

                    // User greeting (moved from center to left side)
                    VStack(spacing: 8) {
                        Text("Hello, \(userName)")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("You are now signed in")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Sign Out button (moved to left side)
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                            Text("Sign Out")
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(width: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red, lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 40)
                }
                .frame(width: geometry.size.width * 0.4) // 40% of screen width
                .background(Color.gray.opacity(0.05)) // Light background to distinguish

                // Right Side - User Information
                VStack(spacing: 24) {
                    Spacer()

                    // User information card
                    VStack(spacing: 16) {
                        Text("Account Information")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.bottom, 8)

                        UserInfoRow(
                            title: "Email",
                            value: authViewModel.currentUser?.email ?? "Not available"
                        )

                        UserInfoRow(
                            title: "Sign-In Method",
                            value: authViewModel.signInMethod
                        )

                        if authViewModel.signInMethod == "Email / Password",
                           let isVerified = authViewModel.currentUser?.isEmailVerified {
                            UserInfoRow(
                                title: "Email Verified",
                                value: isVerified ? "Yes" : "No",
                                valueColor: isVerified ? .green : .red
                            )

                            if !isVerified {
                                Button {
                                    Task {
                                        await authViewModel.sendEmailVerification()
                                    }
                                } label: {
                                    Text("Send Verification Email")
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.orange) // Fixed: Color.Orange -> Color.orange
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .padding(.horizontal)

                    Spacer()
                }
                .frame(width: geometry.size.width * 0.6) // 60% of screen width
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Are you sure? If you sign out, you will return to the login screen.",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var userName: String {
        if let displayName = authViewModel.currentUser?.displayName, !displayName.isEmpty {
            return displayName
        } else {
            return "User"
        }
    }

    private func signOut() {
        Task {
            await authViewModel.signOut()
        }
    }
}

struct UserInfoRow: View {
	let title: String
	let value: String
	var valueColor: Color = .primary
	
	var body: some View {
		HStack {
			Text(title)
				.foregroundColor(.secondary)
			
			Spacer()
			
			Text(value)
				.fontWeight(.medium)
				.foregroundColor(valueColor)
		}
	}
}

struct Home_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			Home()
				.environmentObject(AuthenticationViewModel())
		}
	}
}
