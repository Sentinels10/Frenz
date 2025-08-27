import SwiftUI

struct PaywallView<VM: PaywallRouting>: View {
    @ObservedObject var vm: VM

    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [Color(hex: 0x2B0B58), Color(hex: 0x18042F)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // Decorazioni (emoji come placeholder: sostituisci con asset)
            decorations

            VStack(spacing: 20) {
                header

                // Hero “tile” centrale (sostituisci con immagine/app icon)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .padding(.top, 6)

                // Titolo
                Text(vm.paywallTitle)
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                // Bullet list
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(vm.paywallBullets, id: \.self) { line in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("✦")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white)
                            Text(line)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.top, 6)

                // Toggle prova gratis
                HStack {
                    Text(vm.paywallTrialLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.leading, 16)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { vm.isTrialEnabled },
                        set: { vm.isTrialEnabled = $0 }
                    ))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: 0xB36CFF)))
                }
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .padding(.top, 6)

                // Price footer
                Text(vm.paywallPriceFooter)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 4)

                // CTA
                Button(action: { vm.paywallPurchase() }) {
                    Text(vm.paywallContinueTitle)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [Color(hex: 0xC86BFF), Color(hex: 0x9E45FF)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color(hex: 0xC86BFF, alpha: 0.7), radius: 24, x: 0, y: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Restore + terms
                VStack(spacing: 8) {
                    Button(vm.paywallRestoreTitle, action: { vm.paywallRestore() })
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.top, 2)

                    HStack(spacing: 14) {
                        Button(vm.paywallTermsTitle, action: { /* open URL */ })
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 12, weight: .semibold))
                        Text("—")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 12))
                        Button(vm.paywallPrivacyTitle, action: { /* open URL */ })
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .padding(.bottom, 10)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .navigationBarHidden(true)
    }

    // Header con close “X”
    private var header: some View {
        HStack {
            Spacer()
            Button(action: { vm.paywallClose() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // Emoji decorative: sostituisci con asset quando vuoi
    private var decorations: some View {
        ZStack {
            Text("🍆").font(.system(size: 44)).opacity(0.85).offset(x: -130, y: 40)
            Text("👠").font(.system(size: 44)).opacity(0.85).offset(x: -10, y: -10)
            Text("🕶️").font(.system(size: 42)).opacity(0.85).offset(x: 70, y: 24)
            Text("💋").font(.system(size: 46)).opacity(0.9).offset(x: -140, y: 180)
            Text("🔥").font(.system(size: 40)).opacity(0.9).offset(x: -120, y: 280)
            Text("💰").font(.system(size: 40)).opacity(0.85).offset(x: 120, y: 300)
            Text("🦷").font(.system(size: 42)).opacity(0.9).offset(x: 130, y: 160)
        }
        .allowsHitTesting(false)
    }
}
