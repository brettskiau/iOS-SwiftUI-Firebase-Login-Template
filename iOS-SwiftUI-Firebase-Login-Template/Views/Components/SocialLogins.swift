//
//  SocialLogins.swift
//
//

import SwiftUI

struct SocialLogins: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 15) {
            // Google Sign In Only
            Button {
                Task { await signInWithGoogle() }
            } label: {
                HStack {
                    Image("GoogleIcon")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .font(.system(size: 22))

                    Text("Continue with Google")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }

    private func signInWithGoogle() async {
        await authViewModel.login(with: .signInWithGoogle)
    }
}

struct SocialLogins_Previews: PreviewProvider {
    static var previews: some View {
        SocialLogins()
            .environmentObject(AuthenticationViewModel(
                authRepository: FirebaseAuthRepository()
            ))
    }
}
