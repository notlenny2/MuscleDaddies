import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showOnboarding = false
    @State private var displayName = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.cardDark, Color(red: 0.15, green: 0.05, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo / Title
                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(colors: [.statRed, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )

                    Text("MUSCLE\nDADDIES")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                            LinearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom)
                        )

                    Text("Turn your workouts into an RPG")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    let appleRequest = authService.handleSignInWithApple()
                    request.requestedScopes = appleRequest.requestedScopes
                    request.nonce = appleRequest.nonce
                }
                onCompletion: { result in
                    Task {
                        await authService.handleSignInWithAppleCompletion(result: result)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 54)
                .cornerRadius(4)
                .padding(.horizontal, 40)

                if let error = authService.error {
                    Text(error)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer()
                    .frame(height: 40)
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(displayName: $displayName)
        }
        .onChange(of: authService.isAuthenticated) { _, isAuth in
            if isAuth && authService.currentUser == nil {
                showOnboarding = true
            }
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var displayName: String
    @Environment(\.dismiss) private var dismiss
    @State private var classTheme: Constants.ClassTheme = .fantasy
    @State private var selectedClass: Constants.MuscleClass = .warrior

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.cardDark, Color(red: 0.12, green: 0.05, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("MUSCLE DADDIES")
                                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                                .tracking(2)

                            Text("Create Your Card")
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(.cardGold)
                        }
                        .padding(.top, 10)

                        HStack(spacing: 8) {
                            Text("STEP 1")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.cardGold)
                            Text("Profile")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("•")
                                .foregroundColor(.gray)
                            Text("STEP 2")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.cardGold.opacity(0.7))
                            Text("Class")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Name")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)

                            TextField("Display Name", text: $displayName)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardDarkGray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Theme (Unlocks)")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)

                            HStack(spacing: 10) {
                                themeBadge(.fantasy, totalXP: 0)
                                themeBadge(.sports, totalXP: 0)
                                themeBadge(.scifi, totalXP: 0)
                            }

                            Text("Fantasy is default. Other themes unlock with XP.")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardDarkGray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Your Class")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)

                            VStack(spacing: 8) {
                                ForEach(Constants.MuscleClass.allCases.filter { $0.theme == .fantasy }, id: \.rawValue) { cls in
                                    Button {
                                        selectedClass = cls
                                    } label: {
                                        HStack {
                                            Text(cls.displayName)
                                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                                .foregroundColor(.white)
                                            Spacer()
                                            if selectedClass == cls {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.cardGold)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(selectedClass == cls ? Color.cardGold.opacity(0.18) : Color.cardDarkGray)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(selectedClass == cls ? Color.cardGold.opacity(0.6) : Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardDarkGray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                        Button {
                            Task {
                                await authService.completeOnboarding(
                                    displayName: displayName,
                                    classTheme: classTheme,
                                    selectedClass: selectedClass
                                )
                                dismiss()
                            }
                        } label: {
                            Text("Forge My Card")
                                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.cardGold)
                                .cornerRadius(4)
                                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                        }
                        .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension OnboardingView {
    func themeBadge(_ theme: Constants.ClassTheme, totalXP: Double) -> some View {
        let unlocked = totalXP >= theme.unlockXP
        return HStack(spacing: 6) {
            Text(theme.displayName)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
            if !unlocked {
                Text("🔒 \(Int(theme.unlockXP)) XP")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.gray)
            } else {
                Text("Unlocked")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.cardDarkGray.opacity(0.6))
        )
    }
}
