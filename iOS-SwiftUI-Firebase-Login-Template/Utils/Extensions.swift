
import SwiftUI
import CryptoKit

public extension Color {
    static let Orange = Color("Orange")
}

extension View {
    func styledTextField() -> some View {
        self
            .padding(.horizontal)
            .frame(height: 50)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}


public extension TextField {
    func withLoginStyles() -> some View {
        self.padding()
            .frame(maxWidth: 350)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.Orange, lineWidth: 2)
            )
            .background(Color(red: 1.0, green: 0.98, blue: 0.94))
            .cornerRadius(8)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .padding(.bottom, 20)
    }
}

public extension SecureField {
    func withSecureFieldStyles() -> some View {
        self.padding()
            .frame(maxWidth: 350)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.Orange, lineWidth: 2)
            )
            .background(Color(red: 1.0, green: 0.98, blue: 0.94))
            .cornerRadius(8)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .padding(.bottom, 20)
    }
}

// Needed for Sign in With Apple
extension String {
    var sha256: String {
        let inputData = Data(self.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if length == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}

public extension View {
    #if canImport(UIKit)
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    #endif
}
