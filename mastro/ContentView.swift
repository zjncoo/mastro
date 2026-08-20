import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers

enum ActiveSheet: Identifiable {
    case newCantiere
    case editCantiere(Cantiere)
    case newMezzo
    case editMezzo(Mezzo)
    case newDipendente
    case editDipendente(Dipendente)
    case newSubappaltatore
    case editSubappaltatore(Subappaltatore)
    case tutorial
    case setupWizard
    
    var id: String {
        switch self {
        case .newCantiere: return "newCantiere"
        case .editCantiere(let c): return "editCantiere_\(c.id)"
        case .newMezzo: return "newMezzo"
        case .editMezzo(let m): return "editMezzo_\(m.id)"
        case .newDipendente: return "newDipendente"
        case .editDipendente(let d): return "editDipendente_\(d.id)"
        case .newSubappaltatore: return "newSubappaltatore"
        case .editSubappaltatore(let s): return "editSubappaltatore_\(s.id)"
        case .tutorial: return "tutorial"
        case .setupWizard: return "setupWizard"
        }
    }
}

enum NavSection: String, CaseIterable, Identifiable {
    case cantieri = "Cantieri"
    case mezzi = "Parco Mezzi"
    case dipendenti = "Dipendenti"
    case subappaltatori = "Subappalti"
    case preventivi = "Preventivi"
    case scadenze = "Scadenzario"
    case settings = "Impostazioni"
    
    var id: String { rawValue }
}

struct ContentView: View {
    @StateObject private var manager = AppDataManager()
    @State private var selectedNav: NavSection = .cantieri
    @State private var searchText: String = ""
    @State private var currentDate: Date = Date()
    @State private var isLoading: Bool = true
    @State private var activeSheet: ActiveSheet? = nil
    
    // Animazione a cascata degli elementi della UI
    @State private var showSidebarUI: Bool = false
    @State private var showHeaderUI: Bool = false
    @State private var showContentUI: Bool = false
    
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial: Bool = false
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup: Bool = false
    
    var isDarkMode: Bool { manager.settings.temaSelezionato == 2 }
    
    var currentColorScheme: ColorScheme? {
        if manager.settings.temaSelezionato == 1 { return .light }
        if manager.settings.temaSelezionato == 2 { return .dark }
        return nil
    }
    
    private func triggerCascadingAnimation() {
        showSidebarUI = false
        showHeaderUI = false
        showContentUI = false
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            showSidebarUI = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                showHeaderUI = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.spring(response: 0.50, dampingFraction: 0.78)) {
                showContentUI = true
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            BackgroundGradientView(isDarkMode: isDarkMode)
            
            if isLoading {
                SplashScreenView(manager: manager, isDarkMode: isDarkMode)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                HStack(spacing: 0) {
                    if showSidebarUI {
                        SidebarView(manager: manager, selectedNav: $selectedNav, activeSheet: $activeSheet, isDarkMode: isDarkMode)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    if showHeaderUI || showContentUI {
                        MainContentView(
                            manager: manager,
                            selectedNav: selectedNav,
                            searchText: $searchText,
                            currentDate: currentDate,
                            isDarkMode: isDarkMode,
                            activeSheet: $activeSheet,
                            showHeaderUI: showHeaderUI,
                            showContentUI: showContentUI
                        )
                    }
                }
            }
            
            if let toast = manager.activeToast {
                ToastNotificationOverlay(toast: toast)
                    .zIndex(100)
            }
        }
        .preferredColorScheme(currentColorScheme)
        .task {
            // 1. Caricamento iniziale SplashScreen con logo ad ogni apertura
            try? await Task.sleep(for: .milliseconds(1400))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                isLoading = false
            }
            
            // 2. Se prima apertura dell'app: mostra la procedura di setup con sfondo non trasparente
            if !hasCompletedInitialSetup {
                try? await Task.sleep(for: .milliseconds(300))
                activeSheet = .setupWizard
            } else {
                // Avvii successivi: scatena subito l'animazione a cascata degli elementi UI
                triggerCascadingAnimation()
                
                // 3. Esattamente 2 secondi dopo l'apparizione a cascata, avvia il tutorial se non completato
                if !hasCompletedTutorial {
                    try? await Task.sleep(for: .seconds(2))
                    activeSheet = .tutorial
                }
            }
            
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                currentDate = Date()
            }
        }
        .sheet(item: $activeSheet) { sheet in
            sheetDestination(for: sheet)
        }
        .onAppear {
            manager.updateWindowTitle()
        }
        .onChange(of: manager.settings.nomeAzienda) { _, _ in
            manager.updateWindowTitle()
        }
        .frame(minWidth: 1080, minHeight: 720)
    }
    
    @ViewBuilder
    private func sheetDestination(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .newCantiere:
            EditCantiereSheet(manager: manager, cantiereEsistente: nil)
        case .editCantiere(let cantiere):
            EditCantiereSheet(manager: manager, cantiereEsistente: cantiere)
        case .newMezzo:
            EditMezzoSheet(manager: manager, mezzoEsistente: nil)
        case .editMezzo(let mezzo):
            EditMezzoSheet(manager: manager, mezzoEsistente: mezzo)
        case .newDipendente:
            EditDipendenteSheet(manager: manager, dipendenteEsistente: nil)
        case .editDipendente(let dipendente):
            EditDipendenteSheet(manager: manager, dipendenteEsistente: dipendente)
        case .newSubappaltatore:
            EditSubappaltatoreSheet(manager: manager, subappaltatoreEsistente: nil)
        case .editSubappaltatore(let subappaltatore):
            EditSubappaltatoreSheet(manager: manager, subappaltatoreEsistente: subappaltatore)
        case .tutorial:
            OnboardingTutorialSheet(onFinish: {
                hasCompletedTutorial = true
                activeSheet = nil
            })
        case .setupWizard:
            InitialSetupWizardSheet(manager: manager, onFinish: {
                hasCompletedInitialSetup = true
                activeSheet = nil
                
                // Alla chiusura del setup: scatena l'animazione a cascata ed attendi 2s per il tutorial
                Task { @MainActor in
                    triggerCascadingAnimation()
                    if !hasCompletedTutorial {
                        try? await Task.sleep(for: .seconds(2))
                        activeSheet = .tutorial
                    }
                }
            })
        }
    }
}

// MARK: - Componenti Isolate

struct BackgroundGradientView: View {
    let isDarkMode: Bool
    var body: some View {
        let colors = isDarkMode
            ? [Color(red: 0.08, green: 0.09, blue: 0.12), Color(red: 0.04, green: 0.05, blue: 0.07)]
            : [Color(red: 0.94, green: 0.95, blue: 0.97), Color(red: 0.89, green: 0.91, blue: 0.94)]
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
    }
}

struct SplashScreenView: View {
    @ObservedObject var manager: AppDataManager
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 22) {
            CompanyLogoBadgeView(logoImage: manager.logoImage, size: 78, cornerRadius: 18)
            VStack(spacing: 6) {
                Text(manager.settings.nomeAzienda.isEmpty ? "Impresa Edile" : manager.settings.nomeAzienda)
                    .font(.manrope(20, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : Color.black.opacity(0.88))
                Text("Inizializzazione Workspace...").font(.manrope(13, weight: .medium)).foregroundColor(.secondary)
            }
            ProgressView().scaleEffect(0.9).padding(.top, 4)
        }
        .padding(44)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(isDarkMode ? Color.white.opacity(0.15) : Color.white.opacity(0.8), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 30, x: 0, y: 15)
    }
}

struct SidebarView: View {
    @ObservedObject var manager: AppDataManager
    @Binding var selectedNav: NavSection
    @Binding var activeSheet: ActiveSheet?
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SidebarBrandHeader(manager: manager, isDarkMode: isDarkMode)
            Divider().opacity(isDarkMode ? 0.2 : 0.4)
            SidebarNavButtons(manager: manager, selectedNav: $selectedNav, isDarkMode: isDarkMode)
            Spacer()
            QuickAccessBox(manager: manager, isDarkMode: isDarkMode)
            DeadlinesBox(totalAlerts: manager.totalAlerts, selectedNav: $selectedNav, isDarkMode: isDarkMode)
            HStack(spacing: 8) {
                SidebarSettingsButton(selectedNav: $selectedNav, isDarkMode: isDarkMode)
                Button(action: { activeSheet = .tutorial }) {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill").font(.manrope(11)).foregroundColor(.blue)
                        Text("Guida").font(.manrope(11, weight: .semibold)).foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help("Mostra Guida & Tutorial Interattivo")
            }
        }
        .padding(12)
        .frame(width: 220)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.06)).frame(width: 1), alignment: .trailing)
    }
}

struct SidebarBrandHeader: View {
    @ObservedObject var manager: AppDataManager
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            CompanyLogoBadgeView(logoImage: manager.logoImage, size: 34, cornerRadius: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(manager.settings.nomeAzienda.isEmpty ? "Impresa Edile" : manager.settings.nomeAzienda)
                    .font(.manrope(13, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : Color.black.opacity(0.88))
                    .lineLimit(1)
                Text("Workspace Locale").font(.manrope(10, weight: .medium)).foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 6).padding(.top, 12)
    }
}

struct SidebarNavButtons: View {
    @ObservedObject var manager: AppDataManager
    @Binding var selectedNav: NavSection
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            SidebarButtonLiquid(title: "Cantieri", icon: "building.2", count: manager.cantieri.filter { !$0.isTerminato }.count, isSelected: selectedNav == .cantieri, isDark: isDarkMode, action: { selectedNav = .cantieri })
            SidebarButtonLiquid(title: "Parco Mezzi", icon: "truck.box", count: manager.mezzi.count, isSelected: selectedNav == .mezzi, isDark: isDarkMode, action: { selectedNav = .mezzi })
            SidebarButtonLiquid(title: "Dipendenti", icon: "person.2", count: manager.dipendenti.count, isSelected: selectedNav == .dipendenti, isDark: isDarkMode, action: { selectedNav = .dipendenti })
            SidebarButtonLiquid(title: "Subappalti", icon: "building.2.crop.circle.fill", count: manager.subappaltatori.count, isSelected: selectedNav == .subappaltatori, isDark: isDarkMode, action: { selectedNav = .subappaltatori })
            SidebarButtonLiquid(title: "Preventivi", icon: "doc.text.fill", count: manager.recuperaPreventiviFiles().count, isSelected: selectedNav == .preventivi, isDark: isDarkMode, action: { selectedNav = .preventivi })
            SidebarButtonLiquid(title: "Scadenzario", icon: "calendar.badge.clock", count: manager.totalAlerts, isSelected: selectedNav == .scadenze, isDark: isDarkMode, action: { selectedNav = .scadenze })
        }
    }
}

struct QuickAccessBox: View {
    @ObservedObject var manager: AppDataManager
    let isDarkMode: Bool
    
    var allLinks: [QuickLinkItem] {
        manager.tuttiGliAccessiRapidi
    }
    
    let maxVisibleCount = 4
    
    var primaryLinks: [QuickLinkItem] {
        Array(allLinks.prefix(maxVisibleCount))
    }
    
    var extraLinks: [QuickLinkItem] {
        if allLinks.count > maxVisibleCount {
            return Array(allLinks.suffix(allLinks.count - maxVisibleCount))
        }
        return []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("ACCESSO RAPIDO").font(.manrope(9, weight: .bold)).foregroundColor(.secondary)
                Spacer()
                if !extraLinks.isEmpty {
                    Text("\(allLinks.count) link").font(.manrope(9, weight: .semibold)).foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 4) {
                Button(action: { manager.openBaseFolder() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.gearshape").font(.manrope(11)).foregroundColor(.orange).frame(width: 14)
                        Text("Cartella Madre File").font(.manrope(11, weight: .semibold)).foregroundColor(isDarkMode ? .white : .primary)
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.manrope(8)).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6).padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                
                ForEach(primaryLinks) { link in
                    SidebarQuickLinkRow(title: link.titolo, icon: link.icona, urlStr: link.urlStr, isDark: isDarkMode, manager: manager)
                }
                
                if !extraLinks.isEmpty {
                    Menu {
                        ForEach(extraLinks) { link in
                            Button(action: { manager.openBrowser(urlStr: link.urlStr) }) {
                                Label(link.titolo, systemImage: link.icona)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "ellipsis.circle.fill").font(.manrope(11)).foregroundColor(.blue).frame(width: 14)
                            Text("Altri Accessi Rapidi (\(extraLinks.count))...").font(.manrope(11, weight: .semibold)).foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.down").font(.manrope(9, weight: .bold)).foregroundColor(.blue)
                        }
                        .padding(.horizontal, 6).padding(.vertical, 4)
                        .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .menuStyle(.borderlessButton)
                }
            }
        }
        .padding(8)
        .background(isDarkMode ? Color.white.opacity(0.04) : Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1))
    }
}

struct DeadlinesBox: View {
    let totalAlerts: Int
    @Binding var selectedNav: NavSection
    let isDarkMode: Bool
    
    var body: some View {
        Button(action: { selectedNav = .scadenze }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(totalAlerts > 0 ? .orange : .green)
                    Text("Scadenze 30gg").font(.manrope(11, weight: .bold)).foregroundColor(isDarkMode ? .white : .primary)
                }
                Text(totalAlerts > 0 ? "\(totalAlerts) avvisi critici" : "Tutto aggiornato").font(.manrope(10, weight: .medium)).foregroundColor(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isDarkMode ? Color.white.opacity(0.04) : Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct SidebarSettingsButton: View {
    @Binding var selectedNav: NavSection
    let isDarkMode: Bool
    
    var body: some View {
        HStack {
            Button(action: { selectedNav = .settings }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(selectedNav == .settings ? (isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.12)) : Color.clear)
                    Image(systemName: "gearshape.fill").font(.manrope(14)).foregroundColor(selectedNav == .settings ? (isDarkMode ? .white : .blue) : .secondary)
                }
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help("Impostazioni Generali")
            Spacer()
        }
        .padding(.top, 2)
    }
}

// MARK: - Vista Principale

struct MainContentView: View {
    @ObservedObject var manager: AppDataManager
    let selectedNav: NavSection
    @Binding var searchText: String
    let currentDate: Date
    let isDarkMode: Bool
    @Binding var activeSheet: ActiveSheet?
    let showHeaderUI: Bool
    let showContentUI: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if showHeaderUI {
                topSectionHeader
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if selectedNav != .settings && selectedNav != .scadenze {
                searchAndActionBar
            }
            if showContentUI {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        contentBySection
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
                .transition(.scale(scale: 0.97).combined(with: .opacity))
            }
        }
    }
    
    private var topSectionHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedNav.rawValue).font(.manrope(24, weight: .bold)).foregroundColor(isDarkMode ? .white : .primary)
                Text("Piattaforma di archiviazione documentale locale").font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Text(currentDate.formatted(.dateTime.weekday(.wide).day().month().locale(Locale(identifier: "it_IT"))).capitalized).font(.manrope(12, weight: .semibold)).foregroundColor(.secondary)
                Circle().fill(Color.secondary.opacity(0.4)).frame(width: 4, height: 4)
                Text(currentDate.formatted(.dateTime.hour().minute())).font(.manrope(13, weight: .bold)).foregroundColor(.blue)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 28).padding(.top, 20)
    }
    
    private var searchAndActionBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Cerca...", text: $searchText).textFieldStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
            
            Spacer()
            
            if selectedNav == .cantieri {
                Button(action: { activeSheet = .newCantiere }) { Label("Nuovo Cantiere", systemImage: "plus") }.buttonStyle(.borderedProminent)
            } else if selectedNav == .mezzi {
                Button(action: { activeSheet = .newMezzo }) { Label("Nuovo Mezzo", systemImage: "plus") }.buttonStyle(.borderedProminent)
            } else if selectedNav == .dipendenti {
                Button(action: { activeSheet = .newDipendente }) { Label("Nuovo Dipendente", systemImage: "plus") }.buttonStyle(.borderedProminent)
            } else if selectedNav == .subappaltatori {
                Button(action: { activeSheet = .newSubappaltatore }) { Label("Nuovo Subappaltatore", systemImage: "plus") }.buttonStyle(.borderedProminent)
            } else if selectedNav == .preventivi {
                HStack(spacing: 8) {
                    Button(action: {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = true
                        panel.canChooseDirectories = false
                        panel.canChooseFiles = true
                        if panel.runModal() == .OK {
                            for url in panel.urls {
                                manager.importaFileInPreventivi(da: url)
                            }
                        }
                    }) { Label("Importa Preventivo", systemImage: "plus") }.buttonStyle(.borderedProminent)
                    
                    Button(action: { manager.openFolder(path: manager.activePreventiviDir.path) }) { Label("Apri Cartella", systemImage: "folder") }.buttonStyle(.bordered)
                }
            }
        }
        .padding(.horizontal, 28)
    }
    
    @ViewBuilder
    private var contentBySection: some View {
        switch selectedNav {
        case .cantieri:
            cantieriList
        case .mezzi:
            mezziList
        case .dipendenti:
            dipendentiList
        case .subappaltatori:
            SubappaltatoriView(manager: manager, searchText: searchText, isDarkMode: isDarkMode, onEdit: { activeSheet = .editSubappaltatore($0) })
        case .preventivi:
            PreventiviView(manager: manager, searchText: searchText, isDarkMode: isDarkMode)
        case .scadenze:
            ScadenzarioView(manager: manager, isDarkMode: isDarkMode)
        case .settings:
            SettingsView(manager: manager, isDark: isDarkMode, activeSheet: $activeSheet)
        }
    }
    
    @ViewBuilder
    private var cantieriList: some View {
        if manager.cantieri.isEmpty {
            EmptyStateView(icon: "building.2", text: "Nessun cantiere registrato.", isDark: isDarkMode)
        } else {
            ForEach($manager.cantieri) { $cantiere in
                if searchText.isEmpty || cantiere.nome.localizedCaseInsensitiveContains(searchText) || cantiere.indirizzo.localizedCaseInsensitiveContains(searchText) {
                    CantiereCard(cantiere: $cantiere, manager: manager, onEdit: { activeSheet = .editCantiere(cantiere) }, onDelete: {
                        if let idx = manager.cantieri.firstIndex(where: { $0.id == cantiere.id }) {
                            manager.cantieri.remove(at: idx)
                            manager.save()
                            manager.showToast(titolo: "Cantiere eliminato", icona: "building.2.fill", tipo: .delete)
                        }
                    })
                }
            }
        }
    }
    
    @ViewBuilder
    private var mezziList: some View {
        if manager.mezzi.isEmpty {
            EmptyStateView(icon: "truck.box", text: "Nessun automezzo registrato.", isDark: isDarkMode)
        } else {
            ForEach($manager.mezzi) { $mezzo in
                if searchText.isEmpty || mezzo.targa.localizedCaseInsensitiveContains(searchText) || mezzo.modello.localizedCaseInsensitiveContains(searchText) {
                    MezzoCard(mezzo: $mezzo, manager: manager, onEdit: { activeSheet = .editMezzo(mezzo) }, onDelete: {
                        if let idx = manager.mezzi.firstIndex(where: { $0.id == mezzo.id }) {
                            manager.mezzi.remove(at: idx)
                            manager.save()
                            manager.showToast(titolo: "Automezzo eliminato dal parco", icona: "truck.box.fill", tipo: .delete)
                        }
                    })
                }
            }
        }
    }
    
    @ViewBuilder
    private var dipendentiList: some View {
        if manager.dipendenti.isEmpty {
            EmptyStateView(icon: "person.2", text: "Nessun dipendente registrato.", isDark: isDarkMode)
        } else {
            ForEach($manager.dipendenti) { $dipendente in
                if searchText.isEmpty || dipendente.nome.localizedCaseInsensitiveContains(searchText) || dipendente.mansione.localizedCaseInsensitiveContains(searchText) {
                    DipendenteCard(dipendente: $dipendente, manager: manager, isDarkMode: isDarkMode, onEdit: { activeSheet = .editDipendente(dipendente) }, onDelete: {
                        if let idx = manager.dipendenti.firstIndex(where: { $0.id == dipendente.id }) {
                            manager.dipendenti.remove(at: idx)
                            manager.save()
                            manager.showToast(titolo: "Dipendente rimosso dall'organico", icona: "person.fill.xmark", tipo: .delete)
                        }
                    })
                }
            }
        }
    }
}

// MARK: - Vista Preventivi
struct PreventiviView: View {
    @ObservedObject var manager: AppDataManager
    let searchText: String
    let isDarkMode: Bool
    
    @State private var sortNewestFirst: Bool = true
    
    var preventiviFiltratiESortati: [PreventivoFileItem] {
        let files = manager.recuperaPreventiviFiles()
        let filtrati = files.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
        return filtrati.sorted { f1, f2 in
            if sortNewestFirst {
                return f1.modificationDate > f2.modificationDate
            } else {
                return f1.modificationDate < f2.modificationDate
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                        Text(manager.activePreventiviDir.path)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                
                Spacer()
                
                // Freccetta in alto a destra per ordinamento (Più recente / Meno recente)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        sortNewestFirst.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(sortNewestFirst ? "Più recenti" : "Meno recenti")
                            .font(.manrope(12, weight: .bold))
                        Image(systemName: sortNewestFirst ? "arrow.down" : "arrow.up")
                            .font(.manrope(11, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.12), in: Capsule())
                    .foregroundColor(.blue)
                    .overlay(Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help(sortNewestFirst ? "Ordinamento attuale: Dal più recente al meno recente. Clicca per invertire." : "Ordinamento attuale: Dal meno recente al più recente. Clicca per invertire.")
            }
            .padding(.horizontal, 4)
            
            if preventiviFiltratiESortati.isEmpty {
                EmptyStateView(icon: "doc.text", text: "Nessun preventivo trovato nella cartella selezionata.", isDark: isDarkMode)
            } else {
                VStack(spacing: 8) {
                    ForEach(preventiviFiltratiESortati) { item in
                        PreventivoCardRow(item: item, manager: manager, isDark: isDarkMode)
                    }
                }
            }
        }
    }
}

struct PreventivoCardRow: View {
    let item: PreventivoFileItem
    @ObservedObject var manager: AppDataManager
    let isDark: Bool
    
    var iconNameAndColor: (String, Color) {
        let ext = item.url.pathExtension.lowercased()
        switch ext {
        case "pdf":
            return ("doc.fill", .red)
        case "doc", "docx":
            return ("doc.text.fill", .blue)
        case "xls", "xlsx", "csv":
            return ("tablecells.fill", .green)
        case "png", "jpg", "jpeg":
            return ("photo.fill", .orange)
        default:
            return ("doc.plaintext.fill", .secondary)
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            let (icon, color) = iconNameAndColor
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                Image(systemName: icon)
                    .font(.manrope(18))
                    .foregroundColor(color)
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.manrope(14, weight: .bold))
                    .foregroundColor(isDark ? .white : .primary)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Text("Modificato: \(item.modificationDate.formatted(date: .numeric, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(item.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: { manager.openInFinder(path: item.url.path) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                        Text("Vedi nel Finder")
                    }
                    .font(.manrope(11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Mostra e seleziona il file nel Finder")
                
                Button(action: { manager.openFolder(path: item.url.path) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                        Text("Apri File")
                    }
                    .font(.manrope(11, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help("Apri direttamente il documento con l'applicazione predefinita")
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Cruscotto Scadenze Globale
struct ScadenzarioView: View {
    @ObservedObject var manager: AppDataManager
    let isDarkMode: Bool
    @State private var filtroGiorni: Int = 30
    @State private var categoriaSelezionata: String = "Tutte"
    
    let categorieList = ["Tutte", "Cantiere", "Mezzo", "Dipendente", "Subappalto", "DPI / D.Lgs 81/08", "Formazione Sicurezza", "Noleggio Attrezzatura"]
    
    var tutteLeScadenze: [ScadenzaItem] {
        manager.tutteLeScadenze(entroGiorni: 180)
    }
    
    var scadenzeFiltrate: [ScadenzaItem] {
        let attuali = manager.tutteLeScadenze(entroGiorni: filtroGiorni)
        if categoriaSelezionata == "Tutte" { return attuali }
        return attuali.filter { $0.categoria.lowercased().contains(categoriaSelezionata.lowercased()) }
    }
    
    var countScaduti: Int { tutteLeScadenze.filter { $0.giorniRimanenti < 0 }.count }
    var countCritici: Int { tutteLeScadenze.filter { $0.giorniRimanenti >= 0 && $0.giorniRimanenti <= 15 }.count }
    var countRegolari: Int { tutteLeScadenze.filter { $0.giorniRimanenti > 15 }.count }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // KPI Summary Dashboard Tiles
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scaduti").font(.caption).fontWeight(.bold).foregroundColor(.red)
                    Text("\(countScaduti)").font(.title).bold().foregroundColor(.red)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.2), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("In Scadenza (<= 15 gg)").font(.caption).fontWeight(.bold).foregroundColor(.orange)
                    Text("\(countCritici)").font(.title).bold().foregroundColor(.orange)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.2), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prossimi Regolari").font(.caption).fontWeight(.bold).foregroundColor(.green)
                    Text("\(countRegolari)").font(.title).bold().foregroundColor(.green)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.2), lineWidth: 1))
            }
            
            HStack {
                Picker("Intervallo Tempo:", selection: $filtroGiorni) {
                    Text("Critiche (7 Giorni)").tag(7)
                    Text("Imminenti (15 Giorni)").tag(15)
                    Text("Mese Corrente (30 Giorni)").tag(30)
                    Text("Semestre (180 Giorni)").tag(180)
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
                
                Spacer()
                
                Picker("Categoria:", selection: $categoriaSelezionata) {
                    ForEach(categorieList, id: \.self) { cat in Text(cat).tag(cat) }
                }
                .frame(width: 220)
            }
            
            if scadenzeFiltrate.isEmpty {
                EmptyStateView(icon: "checkmark.seal.fill", text: "Nessuna scadenza trovata con i filtri selezionati.", isDark: isDarkMode)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 8) {
                        ForEach(scadenzeFiltrate) { item in
                            HStack(spacing: 12) {
                                Image(systemName: iconForCategory(item.categoria))
                                    .font(.title3)
                                    .foregroundColor(colorForCategory(item.categoria))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(item.titolo).font(.manrope(13, weight: .bold))
                                        Text(item.categoria)
                                            .font(.manrope(9, weight: .bold))
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Color.primary.opacity(0.08))
                                            .cornerRadius(4)
                                    }
                                    Text("Riferimento: \(item.entitaNome) • Scadenza: \(item.data.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(item.giorniRimanenti < 0 ? "SCADUTO (\(abs(item.giorniRimanenti)) gg fa)" : "\(item.giorniRimanenti) gg rimasti")
                                    .font(.manrope(11, weight: .bold))
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(item.giorniRimanenti < 0 ? Color.red.opacity(0.18) : (item.giorniRimanenti <= 15 ? Color.orange.opacity(0.18) : Color.green.opacity(0.15)))
                                    .foregroundColor(item.giorniRimanenti < 0 ? .red : (item.giorniRimanenti <= 15 ? Color(red: 0.85, green: 0.40, blue: 0) : Color(red: 0.05, green: 0.55, blue: 0.15)))
                                    .cornerRadius(6)
                                
                                Button(action: {
                                    manager.aggiungiAGoogleCalendar(
                                        titolo: "Scadenza \(item.titolo): \(item.entitaNome)",
                                        dettagli: "Categoria: \(item.categoria)\nData: \(item.data.formatted(date: .long, time: .omitted))",
                                        data: item.data
                                    )
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar.badge.plus")
                                        Text("Google Cal")
                                    }
                                    .font(.manrope(11, weight: .semibold))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .help("Sincronizza scadenza ed imposta promemoria 3 giorni prima su Google Calendar")
                            }
                            .padding(12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                        }
                    }
                }
            }
        }
    }
    
    private func iconForCategory(_ cat: String) -> String {
        switch cat {
        case "Cantiere": return "building.2.fill"
        case "Mezzo": return "truck.box.fill"
        case "Dipendente": return "person.fill"
        case "Subappalto": return "tractor"
        case "DPI / D.Lgs 81/08": return "shield.fill"
        case "Formazione Sicurezza": return "cross.case.fill"
        case "Noleggio Attrezzatura": return "wrench.and.screwdriver.fill"
        default: return "clock.fill"
        }
    }
    
    private func colorForCategory(_ cat: String) -> Color {
        switch cat {
        case "Cantiere": return .blue
        case "Mezzo": return .orange
        case "Dipendente": return .purple
        case "Subappalto": return .brown
        case "DPI / D.Lgs 81/08": return .green
        case "Formazione Sicurezza": return .red
        case "Noleggio Attrezzatura": return .teal
        default: return .secondary
        }
    }
}

// MARK: - Morphing Popover / Modal Animation Container (Spring Physics & Glassmorphism)

struct MorphingModalContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content
    
    @State private var isAppearing: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar Morphing Effect
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.manrope(14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.manrope(15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.manrope(11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.manrope(20))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Chiudi")
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)
            .background(Color.primary.opacity(0.02))
            
            Divider().opacity(0.6)
            
            ScrollView(.vertical, showsIndicators: true) {
                content()
                    .padding(20)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
        .scaleEffect(isAppearing ? 1.0 : 0.92)
        .opacity(isAppearing ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                isAppearing = true
            }
        }
    }
}

// MARK: - Modali Form

struct EditCantiereSheet: View {
    @ObservedObject var manager: AppDataManager
    var cantiereEsistente: Cantiere?
    @Environment(\.dismiss) private var dismiss
    
    @State private var nome: String = ""
    @State private var indirizzo: String = ""
    @State private var committente: String = ""
    @State private var noteDescrizione: String = ""
    @State private var dataInizio: Date = Date()
    @State private var dataFine: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
    @State private var isTerminato: Bool = false
    @State private var dipendentiSelezionati: Set<UUID> = []
    @State private var mezziSelezionati: Set<UUID> = []
    @State private var subappaltatoriSelezionati: Set<UUID> = []
    
    @State private var tipoCartellaScelta: Int = 0
    @State private var cartellaEsistentePath: String = ""
    @State private var destinazioneCreazionePath: String = ""
    
    var body: some View {
        MorphingModalContainer(
            title: cantiereEsistente != nil ? "Modifica Scheda Cantiere" : "Registra Nuovo Cantiere",
            subtitle: "Anagrafica cantiere, operai, veicoli e subappaltatori",
            icon: "building.2.fill",
            onClose: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nome Cantiere:").font(.caption).bold().foregroundColor(.secondary)
                    TextField("es. Ristrutturazione Palazzina Via Roma", text: $nome).textFieldStyle(.roundedBorder)
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Committente / Cliente:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. Mario Rossi Srl", text: $committente).textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Indirizzo Cantiere:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. Via Roma 12, Milano", text: $indirizzo).textFieldStyle(.roundedBorder)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Descrizione / Note Cantiere:").font(.caption).bold().foregroundColor(.secondary)
                    TextField("Breve descrizione o note cantiere...", text: $noteDescrizione).textFieldStyle(.roundedBorder)
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Inizio Lavori:").font(.caption).bold().foregroundColor(.secondary)
                        DatePicker("", selection: $dataInizio, displayedComponents: .date).labelsHidden()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fine Prevista:").font(.caption).bold().foregroundColor(.secondary)
                        DatePicker("", selection: $dataFine, displayedComponents: .date).labelsHidden()
                    }
                    if cantiereEsistente != nil {
                        Spacer()
                        Toggle("Lavori Terminati / Chiusura Commessa", isOn: $isTerminato)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Assegna Operai al Cantiere:").font(.caption).bold().foregroundColor(.secondary)
                        Spacer()
                        let disponibiliCount = manager.dipendentiDisponibili().count
                        Text("🟢 \(disponibiliCount) operai disponibili").font(.caption2).foregroundColor(.secondary)
                    }
                    
                    if manager.dipendenti.isEmpty {
                        Text("Nessun operaio registrato in anagrafica.").font(.caption).foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(manager.dipendenti) { d in
                                    let isSel = dipendentiSelezionati.contains(d.id)
                                    let altri = manager.cantieriAttiviPerDipendente(d.id).filter { cantiereEsistente == nil || $0.id != cantiereEsistente?.id }
                                    let labelPrefix = isSel ? "🔵 " : (altri.isEmpty ? "🟢 " : "🟡 ")
                                    
                                    Toggle("\(labelPrefix)\(d.nome)", isOn: Binding(
                                        get: { dipendentiSelezionati.contains(d.id) },
                                        set: { if $0 { dipendentiSelezionati.insert(d.id) } else { dipendentiSelezionati.remove(d.id) } }
                                    ))
                                    .toggleStyle(.button)
                                    .controlSize(.small)
                                    .help(altri.isEmpty ? "\(d.nome) (\(d.mansione)) - Disponibile" : "\(d.nome) (\(d.mansione)) - In: \(altri.map { $0.nome }.joined(separator: ", "))")
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assegna Veicoli / Macchinari:").font(.caption).bold().foregroundColor(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(manager.mezzi) { m in
                                Toggle("\(m.emoji) \(m.targa)", isOn: Binding(
                                    get: { mezziSelezionati.contains(m.id) },
                                    set: { if $0 { mezziSelezionati.insert(m.id) } else { mezziSelezionati.remove(m.id) } }
                                ))
                                .toggleStyle(.button)
                                .controlSize(.small)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assegna Subappaltatori / Ditte Esterne:").font(.caption).bold().foregroundColor(.secondary)
                    if manager.subappaltatori.isEmpty {
                        Text("Nessun subappaltatore registrato.").font(.caption).foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(manager.subappaltatori) { sub in
                                    Toggle("🚜 \(sub.ragioneSociale)", isOn: Binding(
                                        get: { subappaltatoriSelezionati.contains(sub.id) },
                                        set: { if $0 { subappaltatoriSelezionati.insert(sub.id) } else { subappaltatoriSelezionati.remove(sub.id) } }
                                    ))
                                    .toggleStyle(.button)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                }
                
                if cantiereEsistente == nil {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gestione Cartella Archivio:").font(.caption).bold().foregroundColor(.secondary)
                        Picker("", selection: $tipoCartellaScelta) {
                            Text("📁 Crea Nuova Cartella").tag(0)
                            Text("📂 Collega Cartella Esistente").tag(1)
                            Text("🚫 Nessuna Cartella").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        
                        if tipoCartellaScelta == 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                let slug = nome.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
                                let folderName = slug.isEmpty ? "Nome_Cantiere" : slug
                                Text("Posizione dove creare la cartella '\(folderName)':").font(.caption).foregroundColor(.secondary)
                                HStack {
                                    Text(destinazioneCreazionePath.isEmpty ? manager.activeCantieriDir.path : destinazioneCreazionePath)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button("Scegli dove crearla...") {
                                        let panel = NSOpenPanel()
                                        panel.title = "Seleziona dove creare la nuova cartella"
                                        panel.canChooseFiles = false
                                        panel.canChooseDirectories = true
                                        panel.allowsMultipleSelection = false
                                        panel.canCreateDirectories = true
                                        if panel.runModal() == .OK, let folder = panel.url { destinazioneCreazionePath = folder.path }
                                    }
                                }
                            }
                        } else if tipoCartellaScelta == 1 {
                            HStack {
                                Text(cartellaEsistentePath.isEmpty ? "Nessuna cartella scelta" : URL(fileURLWithPath: cartellaEsistentePath).lastPathComponent).font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Button("Sfoglia...") {
                                    let panel = NSOpenPanel()
                                    panel.canChooseFiles = false
                                    panel.canChooseDirectories = true
                                    panel.allowsMultipleSelection = false
                                    if panel.runModal() == .OK, let folder = panel.url { cartellaEsistentePath = folder.path }
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Button("Annulla") { dismiss() }
                    Spacer()
                    Button("Salva") {
                        if var existing = cantiereEsistente, let idx = manager.cantieri.firstIndex(where: { $0.id == existing.id }) {
                            existing.nome = nome
                            existing.committente = committente
                            existing.indirizzo = indirizzo
                            existing.noteDescrizione = noteDescrizione
                            existing.dataInizio = dataInizio
                            existing.dataFine = dataFine
                            existing.isTerminato = isTerminato
                            existing.dipendentiAssegnatiIDs = Array(dipendentiSelezionati)
                            existing.mezziAssegnatiIDs = Array(mezziSelezionati)
                            existing.subappaltatoriAssegnatiIDs = Array(subappaltatoriSelezionati)
                            manager.cantieri[idx] = existing
                        } else {
                            let folderPath: String
                            if tipoCartellaScelta == 1 && !cartellaEsistentePath.isEmpty {
                                folderPath = cartellaEsistentePath
                            } else if tipoCartellaScelta == 0 {
                                let slug = nome.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
                                let parentURL = !destinazioneCreazionePath.isEmpty ? URL(fileURLWithPath: destinazioneCreazionePath) : manager.activeCantieriDir
                                let folder = parentURL.appendingPathComponent(slug)
                                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                                folderPath = folder.path
                            } else {
                                folderPath = ""
                            }
                            let c = Cantiere(
                                nome: nome,
                                indirizzo: indirizzo,
                                dataInizio: dataInizio,
                                dataFine: dataFine,
                                committente: committente,
                                cartellaPath: folderPath,
                                isTerminato: false,
                                noteDescrizione: noteDescrizione,
                                dipendentiAssegnatiIDs: Array(dipendentiSelezionati),
                                mezziAssegnatiIDs: Array(mezziSelezionati),
                                subappaltatoriAssegnatiIDs: Array(subappaltatoriSelezionati)
                            )
                            manager.cantieri.append(c)
                        }
                        manager.save()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .frame(minWidth: 580, idealWidth: 640, minHeight: 480, maxHeight: 720)
        .onAppear {
            if let c = cantiereEsistente {
                self.nome = c.nome
                self.committente = c.committente
                self.indirizzo = c.indirizzo
                self.noteDescrizione = c.noteDescrizione
                self.dataInizio = c.dataInizio
                self.dataFine = c.dataFine
                self.isTerminato = c.isTerminato
                self.dipendentiSelezionati = Set(c.dipendentiAssegnatiIDs)
                self.mezziSelezionati = Set(c.mezziAssegnatiIDs)
                self.subappaltatoriSelezionati = Set(c.subappaltatoriAssegnatiIDs)
            }
            if destinazioneCreazionePath.isEmpty {
                destinazioneCreazionePath = manager.activeCantieriDir.path
            }
        }
    }
}

struct EditMezzoSheet: View {
    @ObservedObject var manager: AppDataManager
    var mezzoEsistente: Mezzo?
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedEmoji: String = "🚛"
    @State private var targa: String = ""
    @State private var modello: String = ""
    @State private var tipo: String = "Autocarro / Furgone"
    @State private var referente: String = ""
    @State private var tipoCartellaScelta: Int = 0
    @State private var cartellaEsistentePath: String = ""
    @State private var destinazioneCreazionePath: String = ""
    
    var body: some View {
        MorphingModalContainer(
            title: mezzoEsistente != nil ? "Modifica Scheda Mezzo" : "Registra Nuovo Veicolo",
            subtitle: "Anagrafica veicolo, targa, tipo e cartella archivio",
            icon: "truck.box.fill",
            onClose: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    ForEach(manager.availableEmojis, id: \.self) { emoji in
                        Button(action: { selectedEmoji = emoji }) {
                            Text(emoji).font(.title2).padding(6)
                                .background(RoundedRectangle(cornerRadius: 8).fill(selectedEmoji == emoji ? Color.blue.opacity(0.18) : Color.primary.opacity(0.04)))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedEmoji == emoji ? Color.blue : Color.clear, lineWidth: 2))
                        }.buttonStyle(.plain)
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Targa / Matricola:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. AB123CD", text: $targa).textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Marca e Modello:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. Iveco Daily 35C15", text: $modello).textFieldStyle(.roundedBorder)
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tipologia:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. Autocarro / Furgone", text: $tipo).textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Referente / Autista:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. Marco Rossi", text: $referente).textFieldStyle(.roundedBorder)
                    }
                }
                
                if mezzoEsistente == nil {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gestione Cartella Archivio:").font(.caption).bold().foregroundColor(.secondary)
                        Picker("", selection: $tipoCartellaScelta) {
                            Text("📁 Crea Nuova Cartella").tag(0)
                            Text("📂 Collega Cartella Esistente").tag(1)
                            Text("🚫 Nessuna Cartella").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        
                        if tipoCartellaScelta == 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                let cleanTarga = targa.uppercased().trimmingCharacters(in: .whitespaces)
                                let slug = "\(cleanTarga)_\(modello)".trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
                                let folderName = slug == "_" ? "Nome_Mezzo" : slug
                                Text("Posizione dove creare la cartella '\(folderName)':").font(.caption).foregroundColor(.secondary)
                                HStack {
                                    Text(destinazioneCreazionePath.isEmpty ? manager.activeMezziDir.path : destinazioneCreazionePath)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button("Scegli dove crearla...") {
                                        let panel = NSOpenPanel()
                                        panel.title = "Seleziona dove creare la nuova cartella"
                                        panel.canChooseFiles = false
                                        panel.canChooseDirectories = true
                                        panel.allowsMultipleSelection = false
                                        panel.canCreateDirectories = true
                                        if panel.runModal() == .OK, let folder = panel.url { destinazioneCreazionePath = folder.path }
                                    }
                                }
                            }
                        } else if tipoCartellaScelta == 1 {
                            HStack {
                                Text(cartellaEsistentePath.isEmpty ? "Nessuna cartella scelta" : URL(fileURLWithPath: cartellaEsistentePath).lastPathComponent).font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Button("Sfoglia...") {
                                    let panel = NSOpenPanel()
                                    panel.canChooseFiles = false
                                    panel.canChooseDirectories = true
                                    panel.allowsMultipleSelection = false
                                    if panel.runModal() == .OK, let folder = panel.url { cartellaEsistentePath = folder.path }
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Button("Annulla") { dismiss() }
                    Spacer()
                    Button("Salva") {
                        let cleanTarga = targa.uppercased().trimmingCharacters(in: .whitespaces)
                        if var existing = mezzoEsistente, let idx = manager.mezzi.firstIndex(where: { $0.id == existing.id }) {
                            existing.emoji = selectedEmoji
                            existing.targa = cleanTarga
                            existing.modello = modello
                            existing.tipo = tipo
                            existing.referente = referente
                            manager.mezzi[idx] = existing
                        } else {
                            let folderPath: String
                            if tipoCartellaScelta == 1 && !cartellaEsistentePath.isEmpty {
                                folderPath = cartellaEsistentePath
                            } else if tipoCartellaScelta == 0 {
                                let slug = "\(cleanTarga)_\(modello)".trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
                                let parentURL = !destinazioneCreazionePath.isEmpty ? URL(fileURLWithPath: destinazioneCreazionePath) : manager.activeMezziDir
                                let folder = parentURL.appendingPathComponent(slug)
                                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                                folderPath = folder.path
                            } else {
                                folderPath = ""
                            }
                            let m = Mezzo(emoji: selectedEmoji, targa: cleanTarga, modello: modello, tipo: tipo, referente: referente, cartellaPath: folderPath)
                            manager.mezzi.append(m)
                        }
                        manager.save()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(targa.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .frame(minWidth: 580, idealWidth: 640, minHeight: 480, maxHeight: 720)
        .onAppear {
            if let m = mezzoEsistente {
                self.selectedEmoji = m.emoji
                self.targa = m.targa
                self.modello = m.modello
                self.tipo = m.tipo
                self.referente = m.referente
            }
            if destinazioneCreazionePath.isEmpty {
                destinazioneCreazionePath = manager.activeMezziDir.path
            }
        }
    }
}

struct EditDipendenteSheet: View {
    @ObservedObject var manager: AppDataManager
    var dipendenteEsistente: Dipendente?
    @Environment(\.dismiss) private var dismiss
    
    @State private var nome: String = ""
    @State private var mansione: String = "Muratore Specializzato"
    @State private var codiceFiscale: String = ""
    @State private var fotoFileName: String = ""
    @State private var noteDescrizione: String = ""
    @State private var tipoCartellaScelta: Int = 0
    @State private var cartellaEsistentePath: String = ""
    @State private var destinazioneCreazionePath: String = ""
    
    var body: some View {
        MorphingModalContainer(
            title: dipendenteEsistente != nil ? "Modifica Scheda Dipendente" : "Registra Nuovo Dipendente",
            subtitle: "Anagrafica operaio, mansione e foto profilo",
            icon: "person.fill",
            onClose: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 16) {
                    if let img = manager.getDipendenteFoto(fileName: fotoFileName) {
                        Image(nsImage: img).resizable().scaledToFill().frame(width: 54, height: 54).clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill").font(.manrope(54)).foregroundColor(.secondary)
                    }
                    Button("Carica Foto Profilo...") {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [UTType.image, UTType.png, UTType.jpeg]
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url { fotoFileName = manager.salvaFotoDipendente(da: url) }
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nome e Cognome:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. Mario Rossi", text: $nome).textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mansione / Ruolo:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. Muratore Specializzato", text: $mansione).textFieldStyle(.roundedBorder)
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Codice Fiscale:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. RSSMRA80A01H501Z", text: $codiceFiscale).textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Descrizione / Note Dipendente:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("Note dipendente...", text: $noteDescrizione).textFieldStyle(.roundedBorder)
                    }
                }
                
                if dipendenteEsistente == nil {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gestione Cartella Archivio:").font(.caption).bold().foregroundColor(.secondary)
                        Picker("", selection: $tipoCartellaScelta) {
                            Text("📁 Crea Nuova Cartella").tag(0)
                            Text("📂 Collega Cartella Esistente").tag(1)
                            Text("🚫 Nessuna Cartella").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        
                        if tipoCartellaScelta == 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                let slug = nome.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
                                let folderName = slug.isEmpty ? "Nome_Dipendente" : slug
                                Text("Posizione dove creare la cartella '\(folderName)':").font(.caption).foregroundColor(.secondary)
                                HStack {
                                    Text(destinazioneCreazionePath.isEmpty ? manager.activeDipendentiDir.path : destinazioneCreazionePath)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button("Scegli dove crearla...") {
                                        let panel = NSOpenPanel()
                                        panel.title = "Seleziona dove creare la nuova cartella"
                                        panel.canChooseFiles = false
                                        panel.canChooseDirectories = true
                                        panel.allowsMultipleSelection = false
                                        panel.canCreateDirectories = true
                                        if panel.runModal() == .OK, let folder = panel.url { destinazioneCreazionePath = folder.path }
                                    }
                                }
                            }
                        } else if tipoCartellaScelta == 1 {
                            HStack {
                                Text(cartellaEsistentePath.isEmpty ? "Nessuna cartella scelta" : URL(fileURLWithPath: cartellaEsistentePath).lastPathComponent).font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Button("Sfoglia...") {
                                    let panel = NSOpenPanel()
                                    panel.canChooseFiles = false
                                    panel.canChooseDirectories = true
                                    panel.allowsMultipleSelection = false
                                    if panel.runModal() == .OK, let folder = panel.url { cartellaEsistentePath = folder.path }
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Button("Annulla") { dismiss() }
                    Spacer()
                    Button("Salva") {
                        if var existing = dipendenteEsistente, let idx = manager.dipendenti.firstIndex(where: { $0.id == existing.id }) {
                            existing.nome = nome
                            existing.mansione = mansione
                            existing.codiceFiscale = codiceFiscale.uppercased()
                            existing.fotoFileName = fotoFileName
                            existing.noteDescrizione = noteDescrizione
                            manager.dipendenti[idx] = existing
                        } else {
                            let folderPath: String
                            if tipoCartellaScelta == 1 && !cartellaEsistentePath.isEmpty {
                                folderPath = cartellaEsistentePath
                            } else if tipoCartellaScelta == 0 {
                                let slug = nome.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
                                let parentURL = !destinazioneCreazionePath.isEmpty ? URL(fileURLWithPath: destinazioneCreazionePath) : manager.activeDipendentiDir
                                let folder = parentURL.appendingPathComponent(slug)
                                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                                folderPath = folder.path
                            } else {
                                folderPath = ""
                            }
                            let d = Dipendente(nome: nome, mansione: mansione, codiceFiscale: codiceFiscale.uppercased(), fotoFileName: fotoFileName, cartellaPath: folderPath, noteDescrizione: noteDescrizione)
                            manager.dipendenti.append(d)
                        }
                        manager.save()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .frame(minWidth: 580, idealWidth: 640, minHeight: 480, maxHeight: 720)
        .onAppear {
            if let d = dipendenteEsistente {
                self.nome = d.nome
                self.mansione = d.mansione
                self.codiceFiscale = d.codiceFiscale
                self.fotoFileName = d.fotoFileName
                self.noteDescrizione = d.noteDescrizione
            }
            if destinazioneCreazionePath.isEmpty {
                destinazioneCreazionePath = manager.activeDipendentiDir.path
            }
        }
    }
}

// MARK: - QuickLink & Settings (con Cartella Madre e Backup ZIP)

struct SidebarQuickLinkRow: View {
    let title: String
    let icon: String
    let urlStr: String
    let isDark: Bool
    let manager: AppDataManager
    
    var body: some View {
        Button(action: { manager.openBrowser(urlStr: urlStr) }) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.manrope(10)).foregroundColor(.blue).frame(width: 14)
                Text(title).font(.manrope(11, weight: .medium)).foregroundColor(isDark ? Color.white.opacity(0.85) : Color.black.opacity(0.75))
                Spacer()
                Image(systemName: "arrow.up.right").font(.manrope(8)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsView: View {
    @ObservedObject var manager: AppDataManager
    let isDark: Bool
    @Binding var activeSheet: ActiveSheet?
    
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial: Bool = false
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            brandSettingsSection
            testAndOnboardingSettingsSection
            notificationAndSoundSettingsSection
            folderSettingsSection
            backupSettingsSection
            quickLinksSettingsSection
            appearanceSettingsSection
        }
        .onChange(of: manager.settings.nomeAzienda) { _, _ in manager.save() }
        .onChange(of: manager.settings.customCartellaMadreDir) { _, _ in manager.save() }
        .onChange(of: manager.settings.customCantieriDir) { _, _ in manager.save() }
        .onChange(of: manager.settings.customMezziDir) { _, _ in manager.save() }
        .onChange(of: manager.settings.customDipendentiDir) { _, _ in manager.save() }
        .onChange(of: manager.settings.customSubappaltatoriDir) { _, _ in manager.save() }
        .onChange(of: manager.settings.customPreventiviDir) { _, _ in manager.save() }
        .onChange(of: manager.settings.linkWebmail) { _, _ in manager.save() }
        .onChange(of: manager.settings.linkFatture) { _, _ in manager.save() }
        .onChange(of: manager.settings.linkPec) { _, _ in manager.save() }
        .onChange(of: manager.settings.linkCassettoFiscale) { _, _ in manager.save() }
        .onChange(of: manager.settings.temaSelezionato) { _, _ in manager.save() }
        .onChange(of: manager.settings.enableSoundEffects) { _, _ in manager.save() }
        .onChange(of: manager.settings.customQuickLinks) { _, _ in manager.save() }
    }
    
    private var brandSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Profilo Azienda & Marchio").font(.headline).foregroundColor(isDark ? .white : .primary)
            HStack(spacing: 20) {
                CompanyLogoBadgeView(logoImage: manager.logoImage, size: 80, cornerRadius: 16)
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Ragione Sociale / Nome Impresa:", text: $manager.settings.nomeAzienda)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack(spacing: 8) {
                        Button("Carica Logo...") {
                            let panel = NSOpenPanel()
                            panel.allowedContentTypes = [UTType.image, UTType.png, UTType.jpeg]
                            if panel.runModal() == .OK, let url = panel.url { manager.salvaNuovoLogo(da: url) }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        if manager.logoImage != nil {
                            Button("Rimuovi Logo") {
                                manager.rimuoviLogo()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .padding(18).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
    
    private var folderSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Posizione Cartelle di Archiviazione").font(.headline).foregroundColor(isDark ? .white : .primary)
            VStack(spacing: 10) {
                // Cartella Madre Personalizzabile
                FolderSettingRow(title: "Cartella Madre Documenti:", currentPath: manager.activeCartellaMadreDir.path, isDark: isDark, onSelect: {
                    if let chosen = selezionaDirectory() { manager.settings.customCartellaMadreDir = chosen; manager.save() }
                }, onReset: { manager.settings.customCartellaMadreDir = ""; manager.save() })
                
                FolderSettingRow(title: "Archivio Cantieri:", currentPath: manager.activeCantieriDir.path, isDark: isDark, onSelect: {
                    if let chosen = selezionaDirectory() { manager.settings.customCantieriDir = chosen; manager.save() }
                }, onReset: { manager.settings.customCantieriDir = ""; manager.save() })
                
                FolderSettingRow(title: "Archivio Mezzi:", currentPath: manager.activeMezziDir.path, isDark: isDark, onSelect: {
                    if let chosen = selezionaDirectory() { manager.settings.customMezziDir = chosen; manager.save() }
                }, onReset: { manager.settings.customMezziDir = ""; manager.save() })
                
                FolderSettingRow(title: "Archivio Dipendenti:", currentPath: manager.activeDipendentiDir.path, isDark: isDark, onSelect: {
                    if let chosen = selezionaDirectory() { manager.settings.customDipendentiDir = chosen; manager.save() }
                }, onReset: { manager.settings.customDipendentiDir = ""; manager.save() })
                
                FolderSettingRow(title: "Archivio Subappalti:", currentPath: manager.activeSubappaltatoriDir.path, isDark: isDark, onSelect: {
                    if let chosen = selezionaDirectory() { manager.settings.customSubappaltatoriDir = chosen; manager.save() }
                }, onReset: { manager.settings.customSubappaltatoriDir = ""; manager.save() })
                
                FolderSettingRow(title: "Archivio Preventivi:", currentPath: manager.activePreventiviDir.path, isDark: isDark, onSelect: {
                    if let chosen = selezionaDirectory() { manager.settings.customPreventiviDir = chosen; manager.save() }
                }, onReset: { manager.settings.customPreventiviDir = ""; manager.save() })
            }
        }
        .padding(18).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
    
    private var backupSettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Backup & Ripristino Dati (.ZIP)").font(.headline).foregroundColor(isDark ? .white : .primary)
            HStack(spacing: 12) {
                Button("Esporta Backup Completo ZIP") { manager.eseguiBackupCompleto() }.buttonStyle(.bordered)
                Button("Ripristina da File Backup ZIP") { manager.ripristinaDaBackup() }.buttonStyle(.bordered)
            }
        }
        .padding(18).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
    
    private var quickLinksSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Collegamenti Rapidi Web & Accessi Rapidi").font(.headline).foregroundColor(isDark ? .white : .primary)
                Spacer()
                Button(action: {
                    let newLink = QuickLinkItem(titolo: "Nuovo Link", icona: "link", urlStr: "https://")
                    manager.settings.customQuickLinks.append(newLink)
                    manager.save()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Aggiungi Accesso Rapido")
                    }
                    .font(.manrope(11, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            VStack(spacing: 10) {
                HStack { Text("Webmail:").frame(width: 140, alignment: .leading); TextField("https://...", text: $manager.settings.linkWebmail).textFieldStyle(.roundedBorder) }
                HStack { Text("Fatture SDI:").frame(width: 140, alignment: .leading); TextField("https://...", text: $manager.settings.linkFatture).textFieldStyle(.roundedBorder) }
                HStack { Text("PEC:").frame(width: 140, alignment: .leading); TextField("https://...", text: $manager.settings.linkPec).textFieldStyle(.roundedBorder) }
                HStack { Text("Cassetto Fiscale:").frame(width: 140, alignment: .leading); TextField("https://...", text: $manager.settings.linkCassettoFiscale).textFieldStyle(.roundedBorder) }
                
                if !manager.settings.customQuickLinks.isEmpty {
                    Divider().padding(.vertical, 4)
                    Text("Accessi Rapidi Personalizzati:").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                    
                    ForEach($manager.settings.customQuickLinks) { $item in
                        HStack(spacing: 8) {
                            TextField("Titolo", text: $item.titolo)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 130)
                            
                            TextField("https://...", text: $item.urlStr)
                                .textFieldStyle(.roundedBorder)
                            
                            Picker("", selection: $item.icona) {
                                Label("Link", systemImage: "link").tag("link")
                                Label("Banca", systemImage: "eurosign.square.fill").tag("eurosign.square.fill")
                                Label("Documento", systemImage: "doc.text.fill").tag("doc.text.fill")
                                Label("Sicurezza", systemImage: "shield.fill").tag("shield.fill")
                                Label("Mappa", systemImage: "map.fill").tag("map.fill")
                                Label("Preferito", systemImage: "star.fill").tag("star.fill")
                                Label("Portale", systemImage: "globe").tag("globe")
                            }
                            .frame(width: 120)
                            
                            Button(action: {
                                if let idx = manager.settings.customQuickLinks.firstIndex(where: { $0.id == item.id }) {
                                    manager.settings.customQuickLinks.remove(at: idx)
                                    manager.save()
                                }
                            }) {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                            .help("Elimina questo accesso rapido")
                        }
                    }
                }
            }
        }
        .padding(18).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
    
    private var appearanceSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Aspetto").font(.headline).foregroundColor(isDark ? .white : .primary)
            Picker("Tema:", selection: $manager.settings.temaSelezionato) {
                Text("Automatico").tag(0)
                Text("Modalità Luce").tag(1)
                Text("Modalità Notte").tag(2)
            }
            .pickerStyle(.segmented)
        }
        .padding(18).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
    
    private var notificationAndSoundSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Notifiche & Effetti Sonori").font(.headline).foregroundColor(isDark ? .white : .primary)
            
            Toggle("Effetti Sonori di Sistema macOS (Glass / Pop)", isOn: $manager.settings.enableSoundEffects)
                .font(.subheadline)
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Notifiche di Sistema macOS per Scadenze Importanti")
                        .font(.subheadline).bold()
                    Text("Invia avvisi locali su Mac 30, 15 e 3 giorni prima delle scadenze dei mezzi e dei cantieri.")
                        .font(.caption).foregroundColor(.secondary)
                }
                HStack(spacing: 8) {
                    Button("Richiedi Permessi") {
                        manager.richiediPermessiNotifiche()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Testa Notifica") {
                        manager.inviaNotificaDiProva()
                        manager.showToast(titolo: "Notifica di prova inviata al Centro Notifiche macOS! 🔔", icona: "bell.fill", tipo: .info)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(18).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
    
    private var testAndOnboardingSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Procedura Guidata & Test Primo Avvio").font(.headline).foregroundColor(isDark ? .white : .primary)
            
            Text("Puoi rieseguire in qualsiasi momento la procedura di configurazione iniziale o simulare il primo avvio dell'app.")
                .font(.caption).foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button(action: {
                    activeSheet = .setupWizard
                }) {
                    Label("Riavvia Setup Iniziale", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button(action: {
                    activeSheet = .tutorial
                }) {
                    Label("Riavvia Tutorial Guida", systemImage: "questionmark.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: {
                    hasCompletedInitialSetup = false
                    hasCompletedTutorial = false
                    manager.resetAllDataToCleanState()
                }) {
                    Label("Pulisci Dati e Resetta (App 100% Pulita)", systemImage: "trash.circle")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
            }
        }
    }
}

func selezionaDirectory() -> String? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = true
    if panel.runModal() == .OK, let url = panel.url { return url.path }
    return nil
}

struct FolderSettingRow: View {
    let title: String
    let currentPath: String
    let isDark: Bool
    let onSelect: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        HStack {
            Text(title).font(.manrope(12, weight: .medium)).frame(width: 160, alignment: .leading)
            Text(currentPath).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary).lineLimit(1).truncationMode(.middle).frame(maxWidth: .infinity, alignment: .leading)
            Button("Cambia...", action: onSelect).controlSize(.small)
            Button("Reset", action: onReset).controlSize(.small)
        }
        .padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct SidebarButtonLiquid: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let isDark: Bool
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    private var iconColor: Color {
        if isSelected { return .blue }
        if isHovered { return .blue.opacity(0.85) }
        return .secondary
    }
    
    private var textColor: Color {
        if isSelected {
            return isDark ? .white : .primary
        }
        if isHovered {
            return isDark ? Color.white.opacity(0.9) : Color.black.opacity(0.85)
        }
        return .secondary
    }
    
    private var badgeBgColor: Color {
        if isSelected { return Color.blue.opacity(0.18) }
        if isHovered { return Color.blue.opacity(0.12) }
        return Color.primary.opacity(0.06)
    }
    
    private var buttonBgColor: Color {
        if isSelected {
            return isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.85)
        }
        if isHovered {
            return isDark ? Color.white.opacity(0.06) : Color.white.opacity(0.45)
        }
        return Color.clear
    }
    
    private var buttonStrokeColor: Color {
        if isSelected {
            return isDark ? Color.white.opacity(0.25) : Color.white
        }
        if isHovered {
            return isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.6)
        }
        return Color.clear
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                action()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.manrope(14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                
                Text(title)
                    .font(.manrope(13, weight: isSelected ? .bold : .medium))
                    .foregroundColor(textColor)
                
                Spacer()
                
                if count > 0 {
                    Text("\(count)")
                        .font(.manrope(11, weight: .bold))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(badgeBgColor)
                        .foregroundColor(isSelected ? .blue : .secondary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(buttonBgColor))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(buttonStrokeColor, lineWidth: 1))
            .scaleEffect(isHovered ? 1.015 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                isHovered = hover
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let text: String
    let isDark: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.manrope(38)).foregroundColor(.secondary.opacity(0.5))
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }
}

// MARK: - Subappaltatori Views

struct SubappaltatoriView: View {
    @ObservedObject var manager: AppDataManager
    let searchText: String
    let isDarkMode: Bool
    var onEdit: (Subappaltatore) -> Void
    
    var subappaltatoriFiltrati: [Subappaltatore] {
        if searchText.isEmpty { return manager.subappaltatori }
        return manager.subappaltatori.filter {
            $0.ragioneSociale.localizedCaseInsensitiveContains(searchText) ||
            $0.referente.localizedCaseInsensitiveContains(searchText) ||
            $0.partitaIva.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        if subappaltatoriFiltrati.isEmpty {
            EmptyStateView(icon: "building.2.crop.circle.fill", text: "Nessuna ditta in subappalto o artigiano registrato.", isDark: isDarkMode)
        } else {
            ForEach(subappaltatoriFiltrati) { sub in
                SubappaltatoreCard(subappaltatore: sub, manager: manager, isDarkMode: isDarkMode, onEdit: { onEdit(sub) }, onDelete: {
                    if let idx = manager.subappaltatori.firstIndex(where: { $0.id == sub.id }) {
                        manager.subappaltatori.remove(at: idx)
                        manager.save()
                    }
                })
            }
        }
    }
}

struct SubappaltatoreCard: View {
    let subappaltatore: Subappaltatore
    @ObservedObject var manager: AppDataManager
    let isDarkMode: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDocPicker: Bool = false
    @State private var selectedDocCategory: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.15))
                    Text("🚜").font(.manrope(28))
                }
                .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(subappaltatore.ragioneSociale)
                        .font(.manrope(16, weight: .bold))
                        .foregroundColor(isDarkMode ? .white : .primary)
                    
                    Text("Referente: \(subappaltatore.referente.isEmpty ? "N.D." : subappaltatore.referente)  •  P.IVA/C.F.: \(subappaltatore.partitaIva.isEmpty ? "N.D." : subappaltatore.partitaIva)")
                        .font(.manrope(11))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        if !subappaltatore.telefono.isEmpty {
                            Label(subappaltatore.telefono, systemImage: "phone.fill").font(.manrope(11)).foregroundColor(.secondary)
                        }
                        if !subappaltatore.email.isEmpty {
                            Label(subappaltatore.email, systemImage: "envelope.fill").font(.manrope(11)).foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Button(action: { manager.openFolder(path: subappaltatore.cartellaPath) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                            Text("Cartella Finder")
                        }
                        .font(.manrope(11, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(subappaltatore.cartellaPath.isEmpty)
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            Divider()
            
            let cantieriAssoluti = manager.cantieri.filter { $0.subappaltatoriAssegnatiIDs.contains(subappaltatore.id) }
            HStack(spacing: 6) {
                Text("Cantieri Assegnati:").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                if cantieriAssoluti.isEmpty {
                    Text("Nessun cantiere attivo").font(.caption).foregroundColor(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(cantieriAssoluti) { c in
                                Text("🏗️ \(c.nome)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("DOCUMENTAZIONE CONFORMITÀ SUBAPPALTO:").font(.manrope(10, weight: .bold)).foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 8)], spacing: 8) {
                    ForEach(manager.docsObbligatoriSubappaltatore, id: \.self) { docName in
                        let filePath = subappaltatore.documenti[docName] ?? ""
                        let scadenzaDate = subappaltatore.scadenze[docName]
                        
                        SubappaltatoreDocRow(
                            docName: docName,
                            filePath: filePath,
                            scadenzaDate: scadenzaDate,
                            onOpen: { manager.openInFinder(path: filePath) },
                            onSelect: {
                                selectedDocCategory = docName
                                showingDocPicker = true
                            }
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(isDarkMode ? Color.white.opacity(0.04) : Color.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1))
        .fileImporter(isPresented: $showingDocPicker, allowedContentTypes: [.item]) { result in
            if case .success(let url) = result {
                if let idx = manager.subappaltatori.firstIndex(where: { $0.id == subappaltatore.id }) {
                    manager.subappaltatori[idx].documenti[selectedDocCategory] = url.path
                    manager.save()
                }
            }
        }
    }
}

struct EditSubappaltatoreSheet: View {
    @ObservedObject var manager: AppDataManager
    var subappaltatoreEsistente: Subappaltatore?
    @Environment(\.dismiss) private var dismiss
    
    @State private var ragioneSociale: String = ""
    @State private var referente: String = ""
    @State private var partitaIva: String = ""
    @State private var telefono: String = ""
    @State private var email: String = ""
    @State private var tipoCartellaScelta: Int = 0
    @State private var cartellaEsistentePath: String = ""
    @State private var destinazioneCreazionePath: String = ""
    
    var body: some View {
        MorphingModalContainer(
            title: subappaltatoreEsistente != nil ? "Modifica Scheda Subappaltatore" : "Registra Nuova Ditta in Subappalto",
            subtitle: "Anagrafica ditta esterna, partita IVA e contatti",
            icon: "tractor",
            onClose: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ragione Sociale / Nome Ditta:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. Impianti Elettrici Rossi Srl", text: $ragioneSociale).textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Referente / Titolare:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. Ing. Mario Rossi", text: $referente).textFieldStyle(.roundedBorder)
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Partita IVA / Codice Fiscale:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. 01234567890", text: $partitaIva).textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Telefono / Cellulare:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. 333 1234567", text: $telefono).textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email / PEC:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("es. info@ditta.it", text: $email).textFieldStyle(.roundedBorder)
                    }
                }
                
                if subappaltatoreEsistente == nil {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gestione Cartella Archivio:").font(.caption).bold().foregroundColor(.secondary)
                        Picker("", selection: $tipoCartellaScelta) {
                            Text("📁 Crea Nuova Cartella").tag(0)
                            Text("📂 Collega Cartella Esistente").tag(1)
                            Text("🚫 Nessuna Cartella").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        
                        if tipoCartellaScelta == 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                let slug = ragioneSociale.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
                                let folderName = slug.isEmpty ? "Nome_Ditta" : slug
                                Text("Posizione dove creare la cartella '\(folderName)':").font(.caption).foregroundColor(.secondary)
                                HStack {
                                    Text(destinazioneCreazionePath.isEmpty ? manager.activeSubappaltatoriDir.path : destinazioneCreazionePath)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button("Scegli dove crearla...") {
                                        let panel = NSOpenPanel()
                                        panel.title = "Seleziona dove creare la nuova cartella"
                                        panel.canChooseFiles = false
                                        panel.canChooseDirectories = true
                                        panel.allowsMultipleSelection = false
                                        panel.canCreateDirectories = true
                                        if panel.runModal() == .OK, let folder = panel.url { destinazioneCreazionePath = folder.path }
                                    }
                                }
                            }
                        } else if tipoCartellaScelta == 1 {
                            HStack {
                                Text(cartellaEsistentePath.isEmpty ? "Nessuna cartella scelta" : URL(fileURLWithPath: cartellaEsistentePath).lastPathComponent).font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Button("Sfoglia...") {
                                    let panel = NSOpenPanel()
                                    panel.canChooseFiles = false
                                    panel.canChooseDirectories = true
                                    panel.allowsMultipleSelection = false
                                    if panel.runModal() == .OK, let folder = panel.url { cartellaEsistentePath = folder.path }
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Button("Annulla") { dismiss() }
                    Spacer()
                    Button("Salva") {
                        let cleanRS = ragioneSociale.trimmingCharacters(in: .whitespaces)
                        if var existing = subappaltatoreEsistente, let idx = manager.subappaltatori.firstIndex(where: { $0.id == existing.id }) {
                            existing.ragioneSociale = cleanRS
                            existing.referente = referente
                            existing.partitaIva = partitaIva.uppercased()
                            existing.telefono = telefono
                            existing.email = email
                            manager.subappaltatori[idx] = existing
                        } else {
                            let folderPath: String
                            if tipoCartellaScelta == 1 && !cartellaEsistentePath.isEmpty {
                                folderPath = cartellaEsistentePath
                            } else if tipoCartellaScelta == 0 {
                                let slug = cleanRS.replacingOccurrences(of: " ", with: "_")
                                let parentURL = !destinazioneCreazionePath.isEmpty ? URL(fileURLWithPath: destinazioneCreazionePath) : manager.activeSubappaltatoriDir
                                let folder = parentURL.appendingPathComponent(slug)
                                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                                folderPath = folder.path
                            } else {
                                folderPath = ""
                            }
                            let sub = Subappaltatore(ragioneSociale: cleanRS, referente: referente, partitaIva: partitaIva.uppercased(), telefono: telefono, email: email, cartellaPath: folderPath)
                            manager.subappaltatori.append(sub)
                        }
                        manager.save()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(ragioneSociale.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        .frame(minWidth: 580, idealWidth: 640, minHeight: 480, maxHeight: 720)
        .onAppear {
            if let sub = subappaltatoreEsistente {
                self.ragioneSociale = sub.ragioneSociale
                self.referente = sub.referente
                self.partitaIva = sub.partitaIva
                self.telefono = sub.telefono
                self.email = sub.email
            }
            if destinazioneCreazionePath.isEmpty {
                destinazioneCreazionePath = manager.activeSubappaltatoriDir.path
            }
        }
    }
}
}

struct SubappaltatoreDocRow: View {
    let docName: String
    let filePath: String
    let scadenzaDate: Date?
    let onOpen: () -> Void
    let onSelect: () -> Void
    
    var isUploaded: Bool {
        !filePath.isEmpty && FileManager.default.fileExists(atPath: filePath)
    }
    
    var daysRemaining: Int? {
        guard let d = scadenzaDate, isUploaded else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: d).day
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: isUploaded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(isUploaded ? .green : .orange)
                        .font(.manrope(12))
                    Text(docName).font(.manrope(11, weight: .medium)).lineLimit(1)
                }
                
                if let diff = daysRemaining, let d = scadenzaDate {
                    Text("Scad: \(d.formatted(date: .numeric, time: .omitted)) (\(diff) gg)")
                        .font(.manrope(9))
                        .foregroundColor(diff <= 15 ? .red : .secondary)
                }
            }
            
            Spacer()
            
            if isUploaded {
                Button(action: onOpen) {
                    Image(systemName: "doc.text.fill").font(.manrope(11)).foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Vedi Documento")
            }
            
            Button(action: onSelect) {
                Image(systemName: isUploaded ? "arrow.triangle.2.circlepath" : "plus.circle.fill")
                    .font(.manrope(12))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .help(isUploaded ? "Sostituisci Documento" : "Carica Documento")
        }
        .padding(6)
        .background(isUploaded ? Color.green.opacity(0.06) : Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(isUploaded ? Color.green.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Onboarding Tutorial Sheet (Completely Skippable & Interactive)

struct TutorialSlide {
    let title: String
    let subtitle: String
    let icon: String
    let badgeColor: Color
    let bulletPoints: [(icon: String, text: String)]
    let tip: String
}

struct OnboardingTutorialSheet: View {
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: Int = 0
    
    let slides: [TutorialSlide] = [
        TutorialSlide(
            title: "Benvenuto in Gestore Cantieri",
            subtitle: "La tua piattaforma completa per la gestione operativa di cantieri ed aziendale",
            icon: "sparkles",
            badgeColor: .blue,
            bulletPoints: [
                ("building.2.fill", "Monitora l'avanzamento dei tuoi cantieri e commesse attive in tempo reale."),
                ("folder.fill.badge.gearshape", "Collegamento automatico con le tue cartelle sul Mac nel Finder."),
                ("person.3.fill", "Assegnazione rapida di operai, mezzi aziendali e ditte in subappalto.")
            ],
            tip: "💡 Suggerimento: Puoi aprire qualsiasi cartella cantiere direttamente nel Finder con un solo clic!"
        ),
        TutorialSlide(
            title: "Operatività di Cantiere (DDT, SAL, FIR & Ore)",
            subtitle: "Tutti i registri di cantiere in un unico posto senza documenti sparsi",
            icon: "doc.text.fill",
            badgeColor: .purple,
            bulletPoints: [
                ("clock.fill", "Registro Ore Personale: rileva ore ordinarie e straordinarie degli operai."),
                ("shippingbox.fill", "Registro DDT: traccia i materiali in ingresso e i fornitori di cantiere."),
                ("chart.line.uptrend.xyaxis", "Avanzamento Lavori (SAL): monitora gli importi ed i verbali di cantiere."),
                ("trash.fill", "Formulari FIR: registra lo smaltimento dei rifiuti speciali di cantiere.")
            ],
            tip: "💡 Suggerimento: Accedi a tutti i registri direttamente dalla scheda di ciascun cantiere."
        ),
        TutorialSlide(
            title: "Parco Mezzi, DPI & Formazione Sicurezza",
            subtitle: "Conformità normativa per attrezzature e sicurezza dei lavoratori",
            icon: "shield.checkerboard",
            badgeColor: .orange,
            bulletPoints: [
                ("truck.box.fill", "Parco Mezzi: scadenze assicurazioni, revisioni e collaudi macchinari."),
                ("wrench.and.screwdriver.fill", "Noleggio Attrezzature: tracciamento ponteggi, container e noli."),
                ("cross.case.fill", "DPI & Attestati: verifica formazione obbligatoria Accordo Stato-Regioni.")
            ],
            tip: "💡 Suggerimento: Le scadenze in esaurimento vengono evidenziate in giallo e rosso nel cruscotto."
        ),
        TutorialSlide(
            title: "Cruscotto Scadenze Globale & Google Calendar",
            subtitle: "Sincronizzazione automatica degli avvisi importanti",
            icon: "calendar.badge.clock",
            badgeColor: .red,
            bulletPoints: [
                ("exclamationmark.triangle.fill", "Cruscotto Scadenze Globale con indicatori KPI immediati."),
                ("arrow.triangle.2.circlepath", "Sincronizzazione diretta a 1-click su Google Calendar."),
                ("bell.fill", "Avviso automatico di notifica impostato a 3 giorni prima del termine.")
            ],
            tip: "💡 Suggerimento: Clicca su 'Sync Google Calendar' per esportare le scadenze nel tuo calendario."
        ),
        TutorialSlide(
            title: "Salvataggio Automatico & Personalizzazione",
            subtitle: "Lavora in tranquillità, le tue modifiche rimangono sempre al sicuro",
            icon: "checkmark.seal.fill",
            badgeColor: .green,
            bulletPoints: [
                ("arrow.clockwise.circle.fill", "Auto-Save Nativo: le preferenze e le modifiche si salvano da sole."),
                ("slider.horizontal.3", "Personalizza la cartella principale, i colori ed il tema chiaro/scuro."),
                ("link.circle.fill", "Link Rapidi in Sidebar per accedere subito a portali aziendali esterni.")
            ],
            tip: "💡 Suggerimento: Puoi riaprire questa guida in qualsiasi momento cliccando 'Guida' nella sidebar!"
        )
    ]
    
    var currentSlide: TutorialSlide { slides[currentStep] }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar con Salta Tutorial (Completamente Skippable)
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [currentSlide.badgeColor, currentSlide.badgeColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 28, height: 28)
                        Image(systemName: currentSlide.icon)
                            .font(.manrope(13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("Guida Interattiva Gestore Cantieri")
                        .font(.manrope(13, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: finishTutorial) {
                    HStack(spacing: 4) {
                        Text("Salta Tutorial")
                        Image(systemName: "xmark.circle.fill")
                    }
                    .font(.manrope(12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.primary.opacity(0.06), in: Capsule())
                }
                .buttonStyle(.plain)
                .help("Chiudi la guida ed entra nell'app (Esc)")
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 12)
            
            Divider().opacity(0.5)
            
            // Corpo Slide Animato
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(currentSlide.title)
                        .font(.manrope(22, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(currentSlide.subtitle)
                        .font(.manrope(13))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(currentSlide.bulletPoints, id: \.text) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.manrope(15, weight: .bold))
                                .foregroundColor(currentSlide.badgeColor)
                                .frame(width: 22)
                            
                            Text(item.text)
                                .font(.manrope(13, weight: .medium))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .background(currentSlide.badgeColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(currentSlide.badgeColor.opacity(0.15), lineWidth: 1))
                
                // Suggerimento Utile Box
                HStack(spacing: 10) {
                    Text(currentSlide.tip)
                        .font(.manrope(11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
                
                Spacer()
                
                // Footer Navigation (Punti Pagina + Avanti/Indietro)
                HStack {
                    // Punti Pagina (Page Dots)
                    HStack(spacing: 6) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? currentSlide.badgeColor : Color.primary.opacity(0.2))
                                .frame(width: index == currentStep ? 10 : 7, height: index == currentStep ? 10 : 7)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        if currentStep > 0 {
                            Button("Indietro") {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                    currentStep -= 1
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if currentStep < slides.count - 1 {
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                    currentStep += 1
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text("Avanti")
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(action: finishTutorial) {
                                HStack(spacing: 6) {
                                    Text("Ho Capito, Inizia Subito!")
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }
                }
            }
            .padding(24)
            .id(currentStep)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
        }
        .frame(width: 620, height: 460)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 12)
    }
    
    private func finishTutorial() {
        onFinish()
        dismiss()
    }
}

// MARK: - Initial Setup Wizard Sheet (Procedura Guidata Iniziale)

struct InitialSetupWizardSheet: View {
    @ObservedObject var manager: AppDataManager
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: Int = 0
    
    // Step 1 State: Brand
    @State private var nomeAzienda: String = ""
    
    // Step 2 State: Base Dir
    @State private var customCartellaMadreDir: String = ""
    
    // Step 3 State: Preventivi Dir
    @State private var customPreventiviDir: String = ""
    
    // Step 4 State: Accessi Rapidi
    @State private var linkWebmail: String = ""
    @State private var linkFatture: String = ""
    @State private var linkPec: String = ""
    @State private var linkCassettoFiscale: String = ""
    
    // Step 5 State: Mezzo Opzionale
    @State private var targaMezzo: String = ""
    @State private var modelloMezzo: String = ""
    @State private var tipoMezzo: String = "Autocarro / Furgone"
    @State private var emojiMezzo: String = "🚛"
    
    // Step 6 State: Dipendente Opzionale
    @State private var nomeDipendente: String = ""
    @State private var mansioneDipendente: String = "Muratore Specializzato"
    @State private var cfDipendente: String = ""
    
    // Step Titles & Icons
    let stepsInfo: [(title: String, icon: String, badgeColor: Color)] = [
        ("Benvenuto & Marchio Azienda", "sparkles", .blue),
        ("Cartella Predefinita App", "folder.badge.gearshape", .purple),
        ("Notifiche di Sistema macOS", "bell.badge.fill", .red),
        ("Cartella Archivio Preventivi", "doc.text.fill", .orange),
        ("Link & Accessi Rapidi", "link.circle.fill", .green),
        ("Registra Primo Mezzo", "truck.box.fill", .indigo),
        ("Registra Primo Dipendente", "person.fill", .teal),
        ("Setup Completato!", "checkmark.seal.fill", .green)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar con Salta Tutto (Completamente Skippable in blocco)
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [stepsInfo[currentStep].badgeColor, stepsInfo[currentStep].badgeColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: stepsInfo[currentStep].icon)
                            .font(.manrope(14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stepsInfo[currentStep].title)
                            .font(.manrope(15, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Passo \(currentStep + 1) di \(stepsInfo.count)")
                            .font(.manrope(11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Pulsante Skippa Restante (Disponibile solo dopo aver completato i passaggi obbligatori 1 e 2)
                if currentStep >= 2 {
                    Button(action: finishAndSkipAll) {
                        HStack(spacing: 4) {
                            Text("Salta Restante (Predefinito)")
                            Image(systemName: "forward.fill").font(.manrope(10))
                        }
                        .font(.manrope(12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.06), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Salta i passaggi opzionali rimanenti ed usa i valori predefiniti")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 14)
            
            Divider().opacity(0.5)
            
            // Corpo dello Step Attivo
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    switch currentStep {
                    case 0: step1BrandView
                    case 1: step2BaseDirView
                    case 2: stepNotificationView
                    case 3: step3PreventiviDirView
                    case 4: step4QuickLinksView
                    case 5: step5FirstMezzoView
                    case 6: step6FirstDipendenteView
                    case 7: step7FinalSummaryView
                    default: EmptyView()
                    }
                }
                .padding(24)
            }
            .id(currentStep)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            
            Divider().opacity(0.5)
            
            // Footer Controls (Punti Stato + Avanti/Indietro/Salta Singolo Passo)
            HStack {
                // Indicatori di progresso a pallino
                HStack(spacing: 6) {
                    ForEach(0..<stepsInfo.count, id: \.self) { idx in
                        Circle()
                            .fill(idx == currentStep ? stepsInfo[currentStep].badgeColor : (idx < currentStep ? Color.green : Color.primary.opacity(0.2)))
                            .frame(width: idx == currentStep ? 10 : 7, height: idx == currentStep ? 10 : 7)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    // Pulsante Indietro
                    if currentStep > 0 && currentStep < stepsInfo.count - 1 {
                        Button("Indietro") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Pulsante Salta Singolo Passo (disponibile solo per gli step opzionali dal passo 3 in poi)
                    if currentStep >= 2 && currentStep < stepsInfo.count - 1 {
                        Button("Salta Passo") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    }
                    
                    // Pulsante Avanti / Salva
                    if currentStep < stepsInfo.count - 1 {
                        Button(action: advanceStep) {
                            HStack(spacing: 6) {
                                Text("Avanti")
                                Image(systemName: "chevron.right")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canAdvanceFromCurrentStep)
                    } else {
                        Button(action: finishWizard) {
                            HStack(spacing: 6) {
                                Text("Entra in Gestore Cantieri")
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.primary.opacity(0.02))
        }
        .frame(width: 640, height: 500)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(manager.settings.temaSelezionato == 2 ? Color(red: 0.12, green: 0.14, blue: 0.18) : Color.white)
                .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 12)
        .onAppear {
            self.nomeAzienda = manager.settings.nomeAzienda
            self.customCartellaMadreDir = manager.settings.customCartellaMadreDir
            self.customPreventiviDir = manager.settings.customPreventiviDir
            self.linkWebmail = manager.settings.linkWebmail
            self.linkFatture = manager.settings.linkFatture
            self.linkPec = manager.settings.linkPec
            self.linkCassettoFiscale = manager.settings.linkCassettoFiscale
        }
    }
    
    private var canAdvanceFromCurrentStep: Bool {
        if currentStep == 0 {
            return !nomeAzienda.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }
    
    // MARK: - Step Views
    
    private var step1BrandView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Benvenuto in Gestore Cantieri! 👋")
                        .font(.manrope(20, weight: .bold))
                    Spacer()
                    Text("Obbligatorio")
                        .font(.manrope(10, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.red.opacity(0.12), in: Capsule())
                }
                Text("Configuriamo la tua impresa in pochi passi per personalizzare workspace e documenti.")
                    .font(.manrope(13))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                CompanyLogoBadgeView(logoImage: manager.logoImage, size: 72, cornerRadius: 14)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nome Impresa Edile / Ragione Sociale: *").font(.caption).bold().foregroundColor(.secondary)
                    TextField("es. Edilizia Rossi Srl", text: $nomeAzienda).textFieldStyle(.roundedBorder)
                    
                    if nomeAzienda.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("⚠️ Il Nome dell'Impresa è un campo obbligatorio per proseguire.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Button("Carica Logo Aziendale...") {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [UTType.image, UTType.png, UTType.jpeg]
                        if panel.runModal() == .OK, let url = panel.url { manager.salvaNuovoLogo(da: url) }
                    }
                    .controlSize(.small)
                }
            }
            .padding(16)
            .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var step2BaseDirView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Cartella Predefinita dell'App (Madre) 📁")
                        .font(.manrope(18, weight: .bold))
                    Text("Obbligatorio")
                        .font(.manrope(10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.15), in: Capsule())
                        .foregroundColor(.red)
                }
                Text("Seleziona la cartella locale su Mac dove l'app salverà i dati ed i documenti.")
                    .font(.manrope(13))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Percorso Cartella Madre selezionato:").font(.manrope(12, weight: .semibold)).foregroundColor(.secondary)
                HStack {
                    Image(systemName: "folder.fill").foregroundColor(.purple)
                    Text(customCartellaMadreDir.isEmpty ? manager.activeCartellaMadreDir.path : customCartellaMadreDir)
                        .font(.manrope(12, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Sfoglia...") {
                        if let path = selezionaDirectory() {
                            customCartellaMadreDir = path
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(12)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var stepNotificationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Notifiche di Sistema macOS 🔔")
                        .font(.manrope(18, weight: .bold))
                    Text("Consigliato")
                        .font(.manrope(10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.15), in: Capsule())
                        .foregroundColor(.blue)
                }
                Text("Ricevi avvisi automatici su Mac prima della scadenza di revisioni, DPI, tagliandi e cantieri.")
                    .font(.manrope(13))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color.red.opacity(0.12)).frame(width: 48, height: 48)
                        Image(systemName: "bell.badge.fill").font(.manrope(22)).foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Avvisi Automatici a 30, 15 e 3 Giorni Prima")
                            .font(.manrope(14, weight: .bold))
                        Text("L'applicazione pianifica avvisi locali trasparenti nel Centro Notifiche del tuo Mac per evitare sanzioni o dimenticanze.")
                            .font(.manrope(12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
                
                Button(action: {
                    manager.richiediPermessiNotifiche()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                        Text("Attiva Notifiche su macOS Adesso")
                    }
                    .font(.manrope(13, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
    }
    
    private var step3PreventiviDirView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cartella Archivio Preventivi 📄")
                    .font(.manrope(18, weight: .bold))
                Text("Seleziona la cartella del tuo Mac dove conservi i preventivi ed i documenti di offerta aziendali.")
                    .font(.manrope(13))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Percorso Cartella Preventivi:").font(.caption).bold().foregroundColor(.secondary)
                
                HStack {
                    Text(customPreventiviDir.isEmpty ? manager.defaultPreventiviDir.path : customPreventiviDir)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Seleziona Cartella...") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = true
                        if panel.runModal() == .OK, let folder = panel.url {
                            customPreventiviDir = folder.path
                        }
                    }
                }
                .padding(12)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private var step4QuickLinksView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Link & Accessi Rapidi Portali Aziendali 🔗")
                    .font(.manrope(18, weight: .bold))
                Text("Inserisci i link ai portali web che utilizzi ogni giorno per aprirli con un clic dalla sidebar.")
                    .font(.manrope(13))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "envelope.fill").foregroundColor(.blue).frame(width: 20)
                    TextField("Webmail / Email Aziendale:", text: $linkWebmail).textFieldStyle(.roundedBorder)
                }
                HStack {
                    Image(systemName: "doc.text.fill").foregroundColor(.purple).frame(width: 20)
                    TextField("Fatturazione Elettronica:", text: $linkFatture).textFieldStyle(.roundedBorder)
                }
                HStack {
                    Image(systemName: "checkmark.shield.fill").foregroundColor(.green).frame(width: 20)
                    TextField("Posta Elettronica Certificata (PEC):", text: $linkPec).textFieldStyle(.roundedBorder)
                }
                HStack {
                    Image(systemName: "building.columns.fill").foregroundColor(.orange).frame(width: 20)
                    TextField("Cassetto Fiscale / Agenzia Entrate:", text: $linkCassettoFiscale).textFieldStyle(.roundedBorder)
                }
            }
        }
    }
    
    private var step5FirstMezzoView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Registra il tuo primo Automezzo (Opzionale) 🚛")
                    .font(.manrope(18, weight: .bold))
                Text("Puoi registrare subito il primo veicolo aziendale o saltare questo passaggio.")
                    .font(.manrope(13))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Targa / Matricola:").font(.caption).bold().foregroundColor(.secondary)
                    TextField("es. AB123CD", text: $targaMezzo).textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Marca e Modello:").font(.caption).bold().foregroundColor(.secondary)
                    TextField("es. Iveco Daily 35C15", text: $modelloMezzo).textFieldStyle(.roundedBorder)
                }
            }
        }
    }
    
    private var step6FirstDipendenteView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Registra il tuo primo Dipendente (Opzionale) 👷")
                    .font(.manrope(18, weight: .bold))
                Text("Inserisci un primo operaio o collaboratore, oppure salta questo passaggio.")
                    .font(.manrope(13))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nome e Cognome:").font(.caption).bold().foregroundColor(.secondary)
                    TextField("es. Mario Rossi", text: $nomeDipendente).textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mansione / Ruolo:").font(.caption).bold().foregroundColor(.secondary)
                    TextField("es. Muratore Specializzato", text: $mansioneDipendente).textFieldStyle(.roundedBorder)
                }
            }
        }
    }
    
    private var step7FinalSummaryView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 64, height: 64)
                Image(systemName: "checkmark").font(.manrope(30, weight: .bold)).foregroundColor(.white)
            }
            
            Text("Tutto Pronto per Iniziare! 🎉")
                .font(.manrope(22, weight: .bold))
            
            Text("La configurazione di Gestore Cantieri è stata completata con successo. Tutte le tue impostazioni e modifiche si salveranno automaticamente.")
                .font(.manrope(13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
    }
    
    private func advanceStep() {
        saveCurrentStepData()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            currentStep += 1
        }
    }
    
    private func saveCurrentStepData() {
        manager.settings.nomeAzienda = nomeAzienda
        manager.settings.customCartellaMadreDir = customCartellaMadreDir
        manager.settings.customPreventiviDir = customPreventiviDir
        manager.settings.linkWebmail = linkWebmail
        manager.settings.linkFatture = linkFatture
        manager.settings.linkPec = linkPec
        manager.settings.linkCassettoFiscale = linkCassettoFiscale
        
        if !targaMezzo.trimmingCharacters(in: .whitespaces).isEmpty && !manager.mezzi.contains(where: { $0.targa == targaMezzo }) {
            let m = Mezzo(emoji: emojiMezzo, targa: targaMezzo.uppercased(), modello: modelloMezzo, tipo: tipoMezzo, referente: "", cartellaPath: "")
            manager.mezzi.append(m)
            targaMezzo = ""
        }
        
        if !nomeDipendente.trimmingCharacters(in: .whitespaces).isEmpty && !manager.dipendenti.contains(where: { $0.nome == nomeDipendente }) {
            let d = Dipendente(nome: nomeDipendente, mansione: mansioneDipendente, codiceFiscale: cfDipendente.uppercased(), fotoFileName: "", cartellaPath: "", noteDescrizione: "")
            manager.dipendenti.append(d)
            nomeDipendente = ""
        }
        
        manager.save()
    }
    
    private func finishWizard() {
        saveCurrentStepData()
        onFinish()
        dismiss()
    }
    
    private func finishAndSkipAll() {
        saveCurrentStepData()
        onFinish()
        dismiss()
    }
}

// MARK: - Company Logo Badge View (White Base Background, Aspect-Fit, Never Stretched)

struct CompanyLogoBadgeView: View {
    let logoImage: NSImage?
    let size: CGFloat
    var cornerRadius: CGFloat = 10
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: size * 0.08, x: 0, y: size * 0.03)
            
            if let img = logoImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(size * 0.12) // 12% internal padding so logo never touches border or stretches
            } else {
                ZStack {
                    Color.white
                    RoundedRectangle(cornerRadius: max(2, size * 0.08), style: .continuous)
                        .stroke(Color.black, lineWidth: max(2, size * 0.06))
                        .padding(size * 0.24)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Mini Toast Notification Overlay (Glassmorphic Banner & Audio Feedback)

struct ToastNotificationOverlay: View {
    let toast: ToastNotification
    
    private var toastColor: Color {
        switch toast.tipo {
        case .success: return .green
        case .info: return .blue
        case .warning: return .orange
        case .delete: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(toastColor.opacity(0.18))
                    .frame(width: 26, height: 26)
                Image(systemName: toast.icona)
                    .font(.manrope(13, weight: .bold))
                    .foregroundColor(toastColor)
            }
            
            Text(toast.titolo)
                .font(.manrope(13, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 6)
        )
        .overlay(
            Capsule()
                .stroke(toastColor.opacity(0.35), lineWidth: 1)
        )
        .padding(.top, 14)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.92)),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }
}