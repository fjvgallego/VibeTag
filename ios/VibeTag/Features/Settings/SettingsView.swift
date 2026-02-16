import SwiftUI
import SwiftData
import AuthenticationServices

struct SettingsView: View {
    let container: AppContainer
    @State private var viewModel: SettingsViewModel
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteSuccess = false
    @Environment(SessionManager.self) var sessionManager

    init(container: AppContainer) {
        self.container = container
        self._viewModel = State(initialValue: SettingsViewModel(
            libraryActionService: container.libraryActionService,
            authRepository: container.authRepo
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsHeaderView()

            ScrollView {
                VStack(spacing: 24) {
                    accountSection

                    LibrarySyncSection(viewModel: viewModel, sessionManager: sessionManager)

                    if sessionManager.isAuthenticated {
                        DangerZoneSection { showingDeleteConfirmation = true }
                    }

                    SettingsFooterView()
                }
                .padding(.top, 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: sessionManager.isAuthenticated)
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Error desconocido")
        }
        .alert("Cuenta eliminada", isPresented: $showingDeleteSuccess) {
            Button("Entendido", role: .cancel) {
                sessionManager.logout()
            }
        } message: {
            Text("Tu cuenta y todos tus datos han sido eliminados correctamente de la app.")
        }
        .onAppear {
            viewModel.updateAuthorizationStatus()
        }
        .confirmationDialog("¿Estás seguro?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Eliminar Cuenta", role: .destructive) {
                Task { @MainActor in
                    do {
                        try await sessionManager.deleteAccount()
                        showingDeleteSuccess = true
                    } catch {
                        viewModel.errorMessage = "Error al eliminar cuenta: \(error.localizedDescription)"
                    }
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer y perderás todos tus datos.")
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if sessionManager.isAuthenticated {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.green.opacity(0.1))
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .foregroundColor(.green)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(width: 32, height: 32)
                        Text("Cuenta de Apple enlazada")
                            .font(.nunito(.body, weight: .medium))
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                    .padding(.horizontal, 4)

                    Divider()

                    Button(action: { sessionManager.logout() }) {
                        Text("Cerrar Sesión")
                            .font(.nunito(.body, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            } else {
                Text("Crea una cuenta para sincronizar tus etiquetas entre dispositivos.")
                    .font(.nunito(.subheadline, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    viewModel.handleAuthorization(result: result, sessionManager: sessionManager)
                }
                .signInWithAppleButtonStyle(Color.primary == .white ? .white : .black)
                .frame(height: 50)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
    }
}

// MARK: - Private subviews

private struct SettingsHeaderView: View {
    var body: some View {
        HStack {
            Text("Ajustes")
                .font(.nunito(.largeTitle, weight: .bold))
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

private struct LibrarySyncSection: View {
    let viewModel: SettingsViewModel
    let sessionManager: SessionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BIBLIOTECA Y SINCRONIZACIÓN")
                .font(.nunito(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                if viewModel.isAppleMusicLinked {
                    SettingsRow(
                        title: "Apple Music Enlazado",
                        icon: "music.note",
                        iconColor: .green,
                        trailing: Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    )
                } else {
                    SettingsRow(title: "Enlazar Apple Music", icon: "music.note", iconColor: .gray) {
                        viewModel.requestMusicPermissions()
                    }
                }

                if sessionManager.isAuthenticated {
                    Divider().padding(.leading, 56)
                    SettingsRow(
                        title: "Sincronizar ahora",
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: .blue,
                        isLoading: viewModel.isSyncing
                    ) {
                        Task { await viewModel.performFullSync() }
                    }

                    Divider().padding(.leading, 56)
                    SettingsRow(
                        title: "Analizar Biblioteca (IA)",
                        icon: "sparkles",
                        iconColor: .purple,
                        isLoading: viewModel.isAnalyzing
                    ) {
                        Task { await viewModel.analyzeLibrary() }
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 16)
        }
    }
}

private struct DangerZoneSection: View {
    let onDeleteTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SettingsRow(title: "Eliminar Cuenta", icon: "trash.fill", iconColor: .red, titleColor: .red) {
                onDeleteTapped()
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }
}

private struct SettingsFooterView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("VibeTag v1.0.0")
                .font(.nunito(.caption, weight: .medium))
            Text("Hecho con ❤️ para amantes de la música")
                .font(.nunito(.caption2, weight: .regular))
        }
        .foregroundColor(.secondary)
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
}

// MARK: - SettingsRow

struct SettingsRow<Trailing: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var titleColor: Color = .primary
    var trailing: Trailing?
    var isLoading: Bool = false
    var action: (() -> Void)? = nil

    init(title: String, icon: String, iconColor: Color, titleColor: Color = .primary, trailing: Trailing? = nil as AnyView?, isLoading: Bool = false, action: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.titleColor = titleColor
        self.trailing = trailing
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.1))
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(width: 32, height: 32)

                Text(title)
                    .font(.nunito(.body, weight: .medium))
                    .foregroundColor(titleColor)

                Spacer()

                if isLoading {
                    ProgressView()
                } else if let trailing {
                    trailing
                } else if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoading || action == nil)
    }
}

extension SettingsRow where Trailing == AnyView {
    init(title: String, icon: String, iconColor: Color, titleColor: Color = .primary, isLoading: Bool = false, action: (() -> Void)? = nil) {
        self.init(title: title, icon: icon, iconColor: iconColor, titleColor: titleColor, trailing: nil, isLoading: isLoading, action: action)
    }
}
