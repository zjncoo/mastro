import SwiftUI
import Combine
import UniformTypeIdentifiers

struct CantiereCard: View {
    @Binding var cantiere: Cantiere
    @ObservedObject var manager: AppDataManager
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    @State private var isExpanded: Bool = false
    @State private var showUnmappedFiles: Bool = false
    @State private var showingGiornaleSheet: Bool = false
    @State private var showingAssegnaOperaiPopover: Bool = false
    @State private var showingRegistroOreSheet: Bool = false
    @State private var showingFormulariFIRSheet: Bool = false
    @State private var showingAvanzamentoSALSheet: Bool = false
    @State private var showingDDTSheet: Bool = false
    @State private var showingNoleggiSheet: Bool = false
    
    var progressCount: (Int, Int) {
        let present = manager.docsObbligatoriCantiere.filter {
            guard let path = cantiere.documenti[$0] else { return false }
            return FileManager.default.fileExists(atPath: path)
        }.count
        return (present, manager.docsObbligatoriCantiere.count)
    }
    
    var extraFiles: [URL] {
        manager.fileNonRegistrati(nella: cantiere.cartellaPath, documentiNoti: cantiere.documenti)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerView
            
            if isExpanded {
                expandedContentView
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(cantiere.isTerminato ? 0.65 : 1.0)
        .grayscale(cantiere.isTerminato ? 0.4 : 0.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 5)
        .sheet(isPresented: $showingGiornaleSheet) {
            GiornaleLavoriSheet(cantiere: $cantiere, manager: manager, isPresented: $showingGiornaleSheet)
        }
        .sheet(isPresented: $showingRegistroOreSheet) {
            RegistroOreSheet(cantiere: $cantiere, manager: manager)
        }
        .sheet(isPresented: $showingFormulariFIRSheet) {
            FormulariFIRSheet(cantiere: $cantiere, manager: manager)
        }
        .sheet(isPresented: $showingAvanzamentoSALSheet) {
            AvanzamentoSALSheet(cantiere: $cantiere, manager: manager)
        }
        .sheet(isPresented: $showingDDTSheet) {
            RegistroDDTSheet(cantiere: $cantiere, manager: manager)
        }
        .sheet(isPresented: $showingNoleggiSheet) {
            NoleggiAttrezzatureSheet(cantiere: $cantiere, manager: manager)
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: 14) {
            avatarView
            infoView
            Spacer()
            editButton
            statusBadge
            chevronIcon
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                isExpanded.toggle()
            }
        }
    }
    
    @ViewBuilder
    private var avatarView: some View {
        let fillColor = cantiere.isTerminato ? Color.gray.opacity(0.15) : Color.blue.opacity(0.12)
        let strokeColor = cantiere.isTerminato ? Color.gray.opacity(0.3) : Color.blue.opacity(0.25)
        let icon = cantiere.isTerminato ? "🏁" : "🏗️"
        
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(fillColor)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(strokeColor, lineWidth: 1))
            Text(icon).font(.title3)
        }
        .frame(width: 44, height: 44)
    }
    
    @ViewBuilder
    private var infoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(cantiere.nome.isEmpty ? "Nuovo Cantiere" : cantiere.nome)
                    .font(.manrope(15, weight: .bold))
                    .foregroundColor(cantiere.isTerminato ? Color.secondary : Color.primary)
                    .strikethrough(cantiere.isTerminato, color: .secondary)
                
                if cantiere.isTerminato {
                    Text("TERMINATO")
                        .font(.manrope(9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.secondary)
                        .clipShape(Capsule())
                } else if !cantiere.committente.isEmpty {
                    Text("• \(cantiere.committente)")
                        .font(.manrope(12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Text("📍 \(cantiere.indirizzo.isEmpty ? "Nessun indirizzo" : cantiere.indirizzo) — Consegna: \(cantiere.dataFine.formatted(date: .abbreviated, time: .omitted))")
                .font(.manrope(12, weight: .regular))
                .foregroundColor(.secondary)
            
            if !cantiere.noteDescrizione.isEmpty {
                Text("📝 \(cantiere.noteDescrizione)")
                    .font(.manrope(11, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
    
    @ViewBuilder
    private var editButton: some View {
        Button(action: onEdit) {
            Image(systemName: "pencil")
                .font(.manrope(13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(6)
                .background(Color.primary.opacity(0.05), in: Circle())
        }
        .buttonStyle(.plain)
        .help("Modifica Cantiere")
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        let (present, total) = progressCount
        let isComplete = (present == total)
        let bgColor = isComplete ? Color.green.opacity(0.15) : Color.orange.opacity(0.15)
        let fgColor = isComplete ? Color(red: 0.05, green: 0.55, blue: 0.15) : Color(red: 0.85, green: 0.40, blue: 0.0)
        let strokeColor = isComplete ? Color.green.opacity(0.3) : Color.orange.opacity(0.3)
        
        Text("\(present)/\(total) Documenti")
            .font(.manrope(11, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(bgColor)
            .foregroundColor(fgColor)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
    }
    
    @ViewBuilder
    private var chevronIcon: some View {
        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.manrope(12, weight: .bold))
            .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    private var expandedContentView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider().opacity(0.4)
            actionBar
            risorseAssegnateBadgeView
            documentsList
            unmappedFilesSection
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    @ViewBuilder
    private var actionBar: some View {
        HStack(spacing: 6) {
            Button(action: { manager.openFolder(path: cantiere.cartellaPath) }) {
                Label("Finder", systemImage: "folder")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button(action: { showingRegistroOreSheet = true }) {
                let totalOre = cantiere.registroOre.reduce(0) { $0 + $1.oreOrdinarie + $1.oreStraordinarie }
                Label("Ore (\(Int(totalOre))h)", systemImage: "clock.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button(action: { showingFormulariFIRSheet = true }) {
                Label("FIR (\(cantiere.formulariFIR.count))", systemImage: "shippingbox.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button(action: { showingAvanzamentoSALSheet = true }) {
                let lastSAL = cantiere.statiAvanzamentoSAL.map { $0.percentuale }.max() ?? 0
                Label("SAL (\(Int(lastSAL))%)", systemImage: "chart.line.uptrend.xyaxis")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button(action: { showingDDTSheet = true }) {
                Label("DDT (\(cantiere.registroDDT.count))", systemImage: "tray.full.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button(action: { showingNoleggiSheet = true }) {
                let noloAttivi = cantiere.noleggiAttrezzature.filter { !$0.isRestituito }.count
                Label("Noleggi (\(noloAttivi))", systemImage: "wrench.and.screwdriver.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button(action: { showingGiornaleSheet = true }) {
                Label("Diario (\(cantiere.giornaleLavori.count))", systemImage: "book.pages")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Menu {
                Button("Esporta Fascicolo Tecnico PDF") { manager.esportaRiepilogoPDF(cantiere: cantiere) }
                Button("Esporta Verbale Inizio Lavori PDF") { manager.esportaVerbaleInizioLavori(cantiere: cantiere) }
                Button("Esporta Verbale Ultimazione Lavori PDF") { manager.esportaVerbaleUltimazioneLavori(cantiere: cantiere) }
            } label: {
                Label("Verbali PDF", systemImage: "doc.text.fill")
            }
            .menuStyle(.borderlessButton)
            
            Button(action: {
                withAnimation {
                    cantiere.isTerminato.toggle()
                    manager.save()
                }
            }) {
                Label(cantiere.isTerminato ? "Riapri" : "Termina", systemImage: cantiere.isTerminato ? "arrow.uturn.backward" : "checkmark.seal.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(cantiere.isTerminato ? .blue : .purple)
            
            Spacer()
            
            Button(role: .destructive, action: onDelete) {
                Label("Elimina", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
    
    @ViewBuilder
    private var risorseAssegnateBadgeView: some View {
        let dips = manager.dipendenti.filter { cantiere.dipendentiAssegnatiIDs.contains($0.id) }
        let mezz = manager.mezzi.filter { cantiere.mezziAssegnatiIDs.contains($0.id) }
        
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill").foregroundColor(.orange).font(.manrope(11))
                Text("Operai (\(dips.count)): \(dips.isEmpty ? "Nessuno" : dips.map { $0.nome }.joined(separator: ", "))")
                    .font(.manrope(11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Button(action: { showingAssegnaOperaiPopover.toggle() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "person.badge.plus").font(.manrope(10))
                        Text("Gestisci Operai").font(.manrope(10, weight: .bold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(Color(red: 0.85, green: 0.40, blue: 0.0))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingAssegnaOperaiPopover) {
                    AssegnaOperaiPopoverView(cantiere: $cantiere, manager: manager)
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: "truck.box.fill").foregroundColor(.green).font(.manrope(11))
                Text("Mezzi (\(mezz.count)): \(mezz.isEmpty ? "Nessuno" : mezz.map { $0.targa }.joined(separator: ", "))")
                    .font(.manrope(11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            let subs = manager.subappaltatori.filter { cantiere.subappaltatoriAssegnatiIDs.contains($0.id) }
            HStack(spacing: 4) {
                Image(systemName: "building.2.crop.circle.fill").foregroundColor(.purple).font(.manrope(11))
                Text("Subappalti (\(subs.count)): \(subs.isEmpty ? "Nessuno" : subs.map { $0.ragioneSociale }.joined(separator: ", "))")
                    .font(.manrope(11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(8)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private var documentsList: some View {
        VStack(spacing: 8) {
            ForEach(manager.docsObbligatoriCantiere, id: \.self) { docName in
                DocDropRowLiquid(
                    title: docName,
                    filePath: cantiere.documenti[docName],
                    expirationDate: Binding(
                        get: { cantiere.scadenze[docName] ?? Date() },
                        set: { cantiere.scadenze[docName] = $0; manager.save() }
                    ),
                    targetFolder: cantiere.cartellaPath,
                    isDURC: docName.contains("DURC"),
                    onAutoDURC: {
                        let scadenza120gg = Calendar.current.date(byAdding: .day, value: 120, to: Date()) ?? Date()
                        cantiere.scadenze[docName] = scadenza120gg
                        manager.save()
                    },
                    onSyncCalendar: {
                        if let d = cantiere.scadenze[docName] {
                            manager.aggiungiAGoogleCalendar(
                                titolo: "Scadenza \(docName): \(cantiere.nome)",
                                dettagli: "Committente: \(cantiere.committente)\nIndirizzo: \(cantiere.indirizzo)",
                                data: d
                            )
                        }
                    },
                    onFileAssigned: { originalPath in
                        // Collega direttamente il file senza copiarlo o duplicarlo
                        cantiere.documenti[docName] = originalPath
                        manager.save()
                    },
                    onRemove: {
                        cantiere.documenti.removeValue(forKey: docName)
                        manager.save()
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var unmappedFilesSection: some View {
        if !extraFiles.isEmpty {
            DisclosureGroup(isExpanded: $showUnmappedFiles) {
                VStack(spacing: 6) {
                    ForEach(extraFiles, id: \.self) { fileUrl in
                        HStack {
                            Image(systemName: "doc.fill").foregroundColor(.secondary)
                            Text(fileUrl.lastPathComponent).font(.manrope(12)).foregroundColor(.primary)
                            Spacer()
                            Button("Trova") { manager.openInFinder(path: fileUrl.path) }
                                .buttonStyle(.plain).font(.manrope(11)).foregroundColor(.blue)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.top, 4)
            } label: {
                Text("📁 Altri File Rilevati nella Cartella (\(extraFiles.count))")
                    .font(.manrope(12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Riga Documento Liquid con Collegamento Diretto
struct DocDropRowLiquid: View {
    let title: String
    var filePath: String?
    @Binding var expirationDate: Date
    let targetFolder: String
    var isDURC: Bool = false
    var onAutoDURC: (() -> Void)? = nil
    var onSyncCalendar: (() -> Void)? = nil
    var onFileAssigned: (String) -> Void
    var onRemove: () -> Void
    
    @State private var isTargeted: Bool = false
    
    var fileName: String? {
        guard let p = filePath, FileManager.default.fileExists(atPath: p) else { return nil }
        return URL(fileURLWithPath: p).lastPathComponent
    }
    
    var daysLeft: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.manrope(12, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 200, alignment: .leading)
            
            if let name = fileName {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.fill").foregroundColor(.blue)
                    Text(name).font(.manrope(12)).lineLimit(1).foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if isDURC {
                    Button("120 gg") { onAutoDURC?() }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .help("Calcola automaticamente validità DURC (120 giorni da oggi)")
                }
                
                DatePicker("", selection: $expirationDate, displayedComponents: .date)
                    .labelsHidden()
                    .controlSize(.mini)
                
                let isExpired = daysLeft < 0
                let isWarning = daysLeft <= 30
                let badgeText = isExpired ? "SCADUTO" : "\(daysLeft) gg"
                let badgeBg = isExpired ? Color.red.opacity(0.14) : (isWarning ? Color.orange.opacity(0.14) : Color.green.opacity(0.14))
                let badgeFg = isExpired ? Color(red: 0.85, green: 0.1, blue: 0.1) : (isWarning ? Color(red: 0.85, green: 0.4, blue: 0) : Color(red: 0.05, green: 0.55, blue: 0.15))
                
                Text(badgeText)
                    .font(.manrope(10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeBg)
                    .foregroundColor(badgeFg)
                    .cornerRadius(4)
                
                Button(action: { onSyncCalendar?() }) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Aggiungi scadenza a Google Calendar")
                
                Button(action: {
                    if let p = filePath { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: p)]) }
                }) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    Text("Trascina file qui dal Finder")
                        .font(.manrope(11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Sfoglia...") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        panel.canChooseFiles = true
                        if panel.runModal() == .OK, let url = panel.url {
                            onFileAssigned(url.path)
                        }
                    }
                    .controlSize(.mini)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(isTargeted ? Color.blue.opacity(0.10) : Color.primary.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(isTargeted ? Color.blue : Color.white.opacity(0.2), lineWidth: isTargeted ? 1.5 : 1))
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let sourceUrl = url else { return }
                DispatchQueue.main.async {
                    // Collegamento diretto al percorso del file senza duplicazione
                    onFileAssigned(sourceUrl.path)
                }
            }
            return true
        }
    }
}

// MARK: - Modale Giornale dei Lavori
struct GiornaleLavoriSheet: View {
    @Binding var cantiere: Cantiere
    @ObservedObject var manager: AppDataManager
    @Binding var isPresented: Bool
    
    @State private var nuovaDescrizione: String = ""
    @State private var nuovoMeteo: String = "Sereno ☀️"
    @State private var noteSicurezza: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📖 Giornale dei Lavori - \(cantiere.nome)")
                    .font(.headline)
                Spacer()
                Button("Chiudi") { isPresented = false }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Aggiungi Nota Giornaliera di Oggi")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                HStack {
                    Picker("Meteo:", selection: $nuovoMeteo) {
                        Text("Sereno ☀️").tag("Sereno ☀️")
                        Text("Nuvoloso ⛅️").tag("Nuvoloso ⛅️")
                        Text("Pioggia 🌧️").tag("Pioggia 🌧️")
                        Text("Vento Forte 💨").tag("Vento Forte 💨")
                    }
                    .frame(width: 200)
                    Spacer()
                }
                
                TextField("Lavorazioni svolte, avanzamento e presenze...", text: $nuovaDescrizione)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Note sicurezza / segnalazioni RLS...", text: $noteSicurezza)
                    .textFieldStyle(.roundedBorder)
                
                Button("Registra nel Giornale Lavori") {
                    let n = NotaGiornale(
                        data: Date(),
                        meteo: nuovoMeteo,
                        operaiPresenti: [],
                        descrizioneLavori: nuovaDescrizione,
                        noteSicurezza: noteSicurezza
                    )
                    cantiere.giornaleLavori.insert(n, at: 0)
                    manager.save()
                    nuovaDescrizione = ""
                    noteSicurezza = ""
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(nuovaDescrizione.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            
            ScrollView {
                VStack(spacing: 8) {
                    if cantiere.giornaleLavori.isEmpty {
                        Text("Nessuna nota registrata nel diario lavori.").font(.caption).foregroundColor(.secondary).padding()
                    } else {
                        ForEach(cantiere.giornaleLavori) { nota in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(nota.data.formatted(date: .complete, time: .shortened))
                                        .font(.manrope(11, weight: .bold))
                                    Spacer()
                                    Text(nota.meteo).font(.manrope(11))
                                }
                                Text(nota.descrizioneLavori).font(.manrope(12))
                                if !nota.noteSicurezza.isEmpty {
                                    Text("⚠️ Sicurezza: \(nota.noteSicurezza)")
                                        .font(.manrope(11))
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(minWidth: 580, idealWidth: 640, minHeight: 480, maxHeight: 720)
    }
}

// MARK: - Popover Assegnazione Operai
struct AssegnaOperaiPopoverView: View {
    @Binding var cantiere: Cantiere
    @ObservedObject var manager: AppDataManager
    @State private var filtroCerca: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.badge.gearshape.fill")
                    .foregroundColor(.orange)
                Text("Assegna Operai - \(cantiere.nome)")
                    .font(.manrope(14, weight: .bold))
                Spacer()
            }
            
            if manager.dipendenti.isEmpty {
                VStack(spacing: 8) {
                    Text("Nessun dipendente registrato nell'anagrafica.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
            } else {
                if manager.dipendenti.count > 4 {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("Cerca operaio...", text: $filtroCerca)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                }
                
                ScrollView {
                    VStack(spacing: 6) {
                        let filtered = manager.dipendenti.filter {
                            filtroCerca.isEmpty || $0.nome.localizedCaseInsensitiveContains(filtroCerca) || $0.mansione.localizedCaseInsensitiveContains(filtroCerca)
                        }
                        
                        ForEach(filtered) { d in
                            let isAssegnato = cantiere.dipendentiAssegnatiIDs.contains(d.id)
                            let altriCantieri = manager.cantieriAttiviPerDipendente(d.id).filter { $0.id != cantiere.id }
                            
                            HStack(spacing: 10) {
                                Toggle("", isOn: Binding(
                                    get: { isAssegnato },
                                    set: { newValue in
                                        if newValue {
                                            if !cantiere.dipendentiAssegnatiIDs.contains(d.id) {
                                                cantiere.dipendentiAssegnatiIDs.append(d.id)
                                            }
                                        } else {
                                            cantiere.dipendentiAssegnatiIDs.removeAll(where: { $0 == d.id })
                                        }
                                        manager.save()
                                    }
                                ))
                                .labelsHidden()
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(d.nome)
                                        .font(.manrope(12, weight: .bold))
                                    Text(d.mansione)
                                        .font(.manrope(10))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if isAssegnato {
                                    Text("Assegnato")
                                        .font(.manrope(10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                } else if altriCantieri.isEmpty {
                                    Text("🟢 Disponibile")
                                        .font(.manrope(10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(Color(red: 0.05, green: 0.55, blue: 0.15))
                                        .cornerRadius(4)
                                } else {
                                    Text("In: \(altriCantieri.map { $0.nome }.joined(separator: ", "))")
                                        .font(.manrope(10, weight: .semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundColor(Color(red: 0.85, green: 0.40, blue: 0.0))
                                        .lineLimit(1)
                                        .cornerRadius(4)
                                }
                            }
                            .padding(8)
                            .background(isAssegnato ? Color.blue.opacity(0.06) : Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isAssegnato ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1))
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
        .padding(14)
        .frame(width: 360)
    }
}

// MARK: - Registro Ore Sheet

struct RegistroOreSheet: View {
    @Binding var cantiere: Cantiere
    @ObservedObject var manager: AppDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var dipendenteSelezionatoID: UUID? = nil
    @State private var dataOre: Date = Date()
    @State private var oreOrdinarie: Double = 8.0
    @State private var oreStraordinarie: Double = 0.0
    @State private var noteOre: String = ""
    
    var totalOrdinarie: Double { cantiere.registroOre.reduce(0) { $0 + $1.oreOrdinarie } }
    var totalStraordinarie: Double { cantiere.registroOre.reduce(0) { $0 + $1.oreStraordinarie } }
    
    var body: some View {
        MorphingModalContainer(
            title: "Registro Ore Personale",
            subtitle: "Cantiere: \(cantiere.nome)",
            icon: "clock.fill",
            onClose: { dismiss() }
        ) {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    VStack {
                        Text("Ore Ordinarie").font(.caption).foregroundColor(.secondary)
                        Text("\(Int(totalOrdinarie)) h").font(.title2).bold().foregroundColor(.blue)
                    }
                    VStack {
                        Text("Ore Straordinarie").font(.caption).foregroundColor(.secondary)
                        Text("\(Int(totalStraordinarie)) h").font(.title2).bold().foregroundColor(.orange)
                    }
                    VStack {
                        Text("Totale Ore Manodopera").font(.caption).foregroundColor(.secondary)
                        Text("\(Int(totalOrdinarie + totalStraordinarie)) h").font(.title2).bold().foregroundColor(.green)
                    }
                }
                .padding().background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Registra Giornata Lavorativa").font(.subheadline).bold()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Operaio / Dipendente:").font(.caption).bold().foregroundColor(.secondary)
                        Picker("", selection: $dipendenteSelezionatoID) {
                            Text("Seleziona operaio...").tag(Optional<UUID>.none)
                            ForEach(manager.dipendenti) { d in
                                Text(d.nome).tag(Optional(d.id))
                            }
                        }
                        .labelsHidden()
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Data Lavoro:").font(.caption).bold().foregroundColor(.secondary)
                            DatePicker("", selection: $dataOre, displayedComponents: .date).labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ore Ordinarie: \(Int(oreOrdinarie)) h").font(.caption).bold().foregroundColor(.secondary)
                            Slider(value: $oreOrdinarie, in: 0...12, step: 0.5)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ore Straordinarie: \(Int(oreStraordinarie)) h").font(.caption).bold().foregroundColor(.secondary)
                            Slider(value: $oreStraordinarie, in: 0...8, step: 0.5)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note / Attività svolta:").font(.caption).bold().foregroundColor(.secondary)
                        TextField("Descrizione lavoro svolto...", text: $noteOre).textFieldStyle(.roundedBorder)
                    }
                    
                    Button(action: {
                        guard let dipID = dipendenteSelezionatoID, let dip = manager.dipendenti.first(where: { $0.id == dipID }) else { return }
                        let entry = RegistroOre(dipendenteID: dipID, dipendenteNome: dip.nome, data: dataOre, oreOrdinarie: oreOrdinarie, oreStraordinarie: oreStraordinarie, note: noteOre)
                        cantiere.registroOre.append(entry)
                        manager.save()
                        noteOre = ""
                    }) {
                        Label("Aggiungi Registro Ore", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(dipendenteSelezionatoID == nil)
                }
                .padding(14)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
                
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Storico Rilevazione Ore:").font(.caption).bold().foregroundColor(.secondary)
                    
                    if cantiere.registroOre.isEmpty {
                        Text("Nessuna ora registrata finora.").font(.caption).foregroundColor(.secondary).padding(.vertical, 10)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(cantiere.registroOre.sorted(by: { $0.data > $1.data })) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.dipendenteNome).font(.manrope(12, weight: .bold))
                                        Text("\(item.data.formatted(date: .numeric, time: .omitted)) • \(item.note.isEmpty ? "Lavori ordinari" : item.note)")
                                            .font(.manrope(10)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Text("\(Int(item.oreOrdinarie))h ord").font(.manrope(11, weight: .semibold)).foregroundColor(.blue)
                                        if item.oreStraordinarie > 0 {
                                            Text("+\(Int(item.oreStraordinarie))h stra").font(.manrope(11, weight: .semibold)).foregroundColor(.orange)
                                        }
                                        Button(action: {
                                            cantiere.registroOre.removeAll(where: { $0.id == item.id })
                                            manager.save()
                                        }) {
                                            Image(systemName: "trash").font(.caption).foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(8)
                                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 580, idealWidth: 640, minHeight: 480, maxHeight: 720)
        .onAppear {
            if dipendenteSelezionatoID == nil {
                dipendenteSelezionatoID = cantiere.dipendentiAssegnatiIDs.first ?? manager.dipendenti.first?.id
            }
        }
    }
}

// MARK: - Formulari FIR Sheet

struct FormulariFIRSheet: View {
    @Binding var cantiere: Cantiere
    @ObservedObject var manager: AppDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var numeroFIR: String = ""
    @State private var dataTrasporto: Date = Date()
    @State private var tipologiaRifiuto: String = "Macerie / Demolizioni"
    @State private var quantitaKgText: String = "500"
    @State private var impiantoDestinazione: String = "Discarica Autorizzata Località"
    @State private var noteFIR: String = ""
    
    let tipologieList = [
        "Macerie / Demolizioni",
        "Cartongesso & Isolanti",
        "Plastica & Imballaggi",
        "Ferro & Metalli",
        "Legno & Pallet",
        "Materiali Pericolosi (Asbesto/Guaina)"
    ]
    
    var totalKg: Double { cantiere.formulariFIR.reduce(0) { $0 + $1.quantitaKg } }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Registro Rifiuti Edili & Formulari FIR - \(cantiere.nome)").font(.headline)
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        VStack {
                            Text("Formulari Registrati").font(.caption).foregroundColor(.secondary)
                            Text("\(cantiere.formulariFIR.count)").font(.title2).bold().foregroundColor(.blue)
                        }
                        VStack {
                            Text("Totale Rifiuti Smaltiti").font(.caption).foregroundColor(.secondary)
                            Text("\(Int(totalKg)) kg").font(.title2).bold().foregroundColor(.orange)
                        }
                    }
                    .padding().background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nuovo Formulario FIR").font(.subheadline).bold()
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Numero Formulario FIR:").font(.caption).bold().foregroundColor(.secondary)
                                TextField("es. FIR-2026-001", text: $numeroFIR).textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Data Trasporto:").font(.caption).bold().foregroundColor(.secondary)
                                DatePicker("", selection: $dataTrasporto, displayedComponents: .date).labelsHidden()
                            }
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tipologia Rifiuto:").font(.caption).bold().foregroundColor(.secondary)
                                Picker("", selection: $tipologiaRifiuto) {
                                    ForEach(tipologieList, id: \.self) { t in Text(t).tag(t) }
                                }
                                .labelsHidden()
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quantità (in Kg):").font(.caption).bold().foregroundColor(.secondary)
                                TextField("500", text: $quantitaKgText).textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Impianto / Discarica Destinazione:").font(.caption).bold().foregroundColor(.secondary)
                            TextField("Discarica autorizzata...", text: $impiantoDestinazione).textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Note / Trasportatore:").font(.caption).bold().foregroundColor(.secondary)
                            TextField("Note o trasportatore...", text: $noteFIR).textFieldStyle(.roundedBorder)
                        }
                        
                        Button(action: {
                            let kg = Double(quantitaKgText) ?? 0.0
                            let fir = FormularioFIR(numeroFIR: numeroFIR, dataTrasporto: dataTrasporto, tipologiaRifiuto: tipologiaRifiuto, quantitaKg: kg, impiantoDestinazione: impiantoDestinazione, note: noteFIR)
                            cantiere.formulariFIR.append(fir)
                            manager.save()
                            numeroFIR = ""
                            noteFIR = ""
                        }) {
                            Label("Registra FIR", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(numeroFIR.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(14)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Elenco Formulari FIR Registrati:").font(.caption).bold().foregroundColor(.secondary)
                        
                        if cantiere.formulariFIR.isEmpty {
                            Text("Nessun FIR smaltimento inserito.").font(.caption).foregroundColor(.secondary).padding(.vertical, 10)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(cantiere.formulariFIR.sorted(by: { $0.dataTrasporto > $1.dataTrasporto })) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("FIR n. \(item.numeroFIR)").font(.manrope(12, weight: .bold))
                                            Text("\(item.tipologiaRifiuto) • \(Int(item.quantitaKg)) kg • Dest: \(item.impiantoDestinazione)")
                                                .font(.manrope(10)).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        HStack(spacing: 8) {
                                            Text(item.dataTrasporto.formatted(date: .numeric, time: .omitted)).font(.manrope(10)).foregroundColor(.secondary)
                                            Button(action: {
                                                cantiere.formulariFIR.removeAll(where: { $0.id == item.id })
                                                manager.save()
                                            }) {
                                                Image(systemName: "trash").font(.caption).foregroundColor(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            Button("Chiudi") { dismiss() }.buttonStyle(.bordered)
        }
        .padding(20)
        .frame(minWidth: 580, idealWidth: 640, minHeight: 480, maxHeight: 720)
    }
}

// MARK: - Avanzamento SAL Sheet

struct AvanzamentoSALSheet: View {
    @Binding var cantiere: Cantiere
    @ObservedObject var manager: AppDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var titoloSAL: String = "SAL 1"
    @State private var percentualeText: String = "30"
    @State private var importoText: String = "15000"
    @State private var dataRaggiungimento: Date = Date()
    @State private var isFatturato: Bool = false
    @State private var noteSAL: String = ""
    
    var lastPercent: Double { cantiere.statiAvanzamentoSAL.map { $0.percentuale }.max() ?? 0.0 }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Stati Avanzamento Lavori (SAL) - \(cantiere.nome)").font(.headline)
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Avanzamento Cantiere Totale:").font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(lastPercent))%").font(.headline).bold().foregroundColor(.blue)
                        }
                        ProgressView(value: min(lastPercent / 100.0, 1.0))
                    }
                    .padding().background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nuovo SAL / Acconto").font(.subheadline).bold()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Titolo SAL:").font(.caption).bold().foregroundColor(.secondary)
                            TextField("es. SAL 1 - 30% Fondamenta", text: $titoloSAL).textFieldStyle(.roundedBorder)
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Percentuale SAL (%):").font(.caption).bold().foregroundColor(.secondary)
                                TextField("30", text: $percentualeText).textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Importo Acconto (€):").font(.caption).bold().foregroundColor(.secondary)
                                TextField("15000", text: $importoText).textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Data Raggiungimento:").font(.caption).bold().foregroundColor(.secondary)
                                DatePicker("", selection: $dataRaggiungimento, displayedComponents: .date).labelsHidden()
                            }
                        }
                        
                        Toggle("Fatturato / Incassato dal Committente", isOn: $isFatturato)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Note / Oggetto Lavori:").font(.caption).bold().foregroundColor(.secondary)
                            TextField("Descrizione lavori compresi...", text: $noteSAL).textFieldStyle(.roundedBorder)
                        }
                        
                        Button(action: {
                            let perc = Double(percentualeText) ?? 0.0
                            let imp = Double(importoText) ?? 0.0
                            let sal = StatoAvanzamentoSAL(titolo: titoloSAL, percentuale: perc, importoSAL: imp, dataRaggiungimento: dataRaggiungimento, isFatturato: isFatturato, note: noteSAL)
                            cantiere.statiAvanzamentoSAL.append(sal)
                            manager.save()
                            titoloSAL = ""
                            noteSAL = ""
                        }) {
                            Label("Registra SAL", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(titoloSAL.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(14)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Storico Stati Avanzamento Lavori:").font(.caption).bold().foregroundColor(.secondary)
                        
                        if cantiere.statiAvanzamentoSAL.isEmpty {
                            Text("Nessun SAL registrato.").font(.caption).foregroundColor(.secondary).padding(.vertical, 10)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(cantiere.statiAvanzamentoSAL.sorted(by: { $0.percentuale < $1.percentuale })) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(item.titolo).font(.manrope(12, weight: .bold))
                                                Text("\(Int(item.percentuale))%")
                                                    .font(.manrope(10, weight: .bold))
                                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                                    .background(Color.blue.opacity(0.15))
                                                    .foregroundColor(.blue).cornerRadius(4)
                                            }
                                            Text("€ \(String(format: "%.2f", item.importoSAL)) • \(item.dataRaggiungimento.formatted(date: .numeric, time: .omitted))")
                                                .font(.manrope(10)).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        HStack(spacing: 8) {
                                            Text(item.isFatturato ? "✓ Fatturato" : "⏳ In attesa")
                                                .font(.manrope(10, weight: .semibold))
                                                .foregroundColor(item.isFatturato ? .green : .orange)
                                            
                                            Button(action: {
                                                cantiere.statiAvanzamentoSAL.removeAll(where: { $0.id == item.id })
                                                manager.save()
                                            }) {
                                                Image(systemName: "trash").font(.caption).foregroundColor(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            Button("Chiudi") { dismiss() }.buttonStyle(.bordered)
        }
        .padding(20)
        .frame(minWidth: 480, idealWidth: 520, minHeight: 440, maxHeight: 660)
    }
}

// MARK: - Registro DDT & Materiali Sheet

struct RegistroDDTSheet: View {
    @Binding var cantiere: Cantiere
    @ObservedObject var manager: AppDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var numeroDDT: String = ""
    @State private var dataDDT: Date = Date()
    @State private var fornitore: String = ""
    @State private var descrizioneMateriali: String = ""
    @State private var importoText: String = "0"
    @State private var noteDDT: String = ""
    
    var totaleSpesaMateriali: Double { cantiere.registroDDT.reduce(0) { $0 + $1.importoStimato } }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Gestione DDT & Materiali in Ingresso - \(cantiere.nome)").font(.headline)
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        VStack {
                            Text("DDT Registrati").font(.caption).foregroundColor(.secondary)
                            Text("\(cantiere.registroDDT.count)").font(.title2).bold().foregroundColor(.blue)
                        }
                        VStack {
                            Text("Totale Spesa Materiali").font(.caption).foregroundColor(.secondary)
                            Text("€ \(String(format: "%.2f", totaleSpesaMateriali))").font(.title2).bold().foregroundColor(.green)
                        }
                    }
                    .padding().background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Registra Nuovo Documento di Trasporto (DDT)").font(.subheadline).bold()
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Numero DDT / Bolla:").font(.caption).bold().foregroundColor(.secondary)
                                TextField("es. 1234/A", text: $numeroDDT).textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Data DDT:").font(.caption).bold().foregroundColor(.secondary)
                                DatePicker("", selection: $dataDDT, displayedComponents: .date).labelsHidden()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fornitore / Magazzino Edile:").font(.caption).bold().foregroundColor(.secondary)
                            TextField("es. Edilizia Rossi Srl", text: $fornitore).textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Descrizione Materiali:").font(.caption).bold().foregroundColor(.secondary)
                            TextField("es. Cemento 325, Tubi PVC, Rete elettro-saldata", text: $descrizioneMateriali).textFieldStyle(.roundedBorder)
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Importo Stimato (€):").font(.caption).bold().foregroundColor(.secondary)
                                TextField("0.00", text: $importoText).textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Note Aggiuntive:").font(.caption).bold().foregroundColor(.secondary)
                                TextField("Note...", text: $noteDDT).textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        Button(action: {
                            let imp = Double(importoText) ?? 0.0
                            let ddt = DocumentoDDT(numeroDDT: numeroDDT, dataDDT: dataDDT, fornitore: fornitore, descrizioneMateriali: descrizioneMateriali, importoStimato: imp, note: noteDDT)
                            cantiere.registroDDT.append(ddt)
                            manager.save()
                            numeroDDT = ""
                            descrizioneMateriali = ""
                            noteDDT = ""
                        }) {
                            Label("Registra DDT Materiali", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(numeroDDT.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(14)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
                    .padding(4)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DDT Materiali Ingressi Cantiere:").font(.caption).bold().foregroundColor(.secondary)
                        
                        if cantiere.registroDDT.isEmpty {
                            Text("Nessun DDT registrato.").font(.caption).foregroundColor(.secondary).padding(.vertical, 10)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(cantiere.registroDDT.sorted(by: { $0.dataDDT > $1.dataDDT })) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("📦 DDT n. \(item.numeroDDT) • \(item.fornitore)").font(.manrope(12, weight: .bold))
                                            Text("\(item.descrizioneMateriali) • \(item.dataDDT.formatted(date: .numeric, time: .omitted))")
                                                .font(.manrope(10)).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        HStack(spacing: 8) {
                                            if item.importoStimato > 0 {
                                                Text("€ \(String(format: "%.2f", item.importoStimato))").font(.manrope(11, weight: .semibold)).foregroundColor(.green)
                                            }
                                            Button(action: {
                                                cantiere.registroDDT.removeAll(where: { $0.id == item.id })
                                                manager.save()
                                            }) {
                                                Image(systemName: "trash").font(.caption).foregroundColor(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            Button("Chiudi") { dismiss() }.buttonStyle(.bordered)
        }
        .padding(20)
        .frame(minWidth: 580, idealWidth: 640, minHeight: 480, maxHeight: 720)
    }
}

// MARK: - Noleggi Attrezzature & Ponteggi Sheet

struct NoleggiAttrezzatureSheet: View {
    @Binding var cantiere: Cantiere
    @ObservedObject var manager: AppDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var descrizione: String = ""
    @State private var noleggiatore: String = ""
    @State private var costoGiornalieroText: String = "50"
    @State private var dataInizioNolo: Date = Date()
    @State private var dataFinePrevista: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    @State private var noteNolo: String = ""
    
    let attrezzatureConsigliate = [
        "Miniescavatore 18 q.li",
        "Ponteggio Tubi e Giunti (mq)",
        "Trabattello in Alluminio",
        "Generatore Corrente 10kW",
        "Motocompressore & Martello Demolitore",
        "Piattaforma Aerea / Cestello"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Gestione Noleggi Attrezzature & Ponteggi - \(cantiere.nome)").font(.headline)
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Registra Nuovo Noleggio").font(.subheadline).bold()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Attrezzatura / Macchinario a Noleggio:").font(.caption).bold().foregroundColor(.secondary)
                            HStack {
                                TextField("es. Miniescavatore 18 q.li", text: $descrizione).textFieldStyle(.roundedBorder)
                                Picker("", selection: $descrizione) {
                                    Text("Esempi...").tag("")
                                    ForEach(attrezzatureConsigliate, id: \.self) { item in Text(item).tag(item) }
                                }
                                .labelsHidden()
                                .frame(width: 140)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Società di Noleggio / Fornitore:").font(.caption).bold().foregroundColor(.secondary)
                                TextField("es. NoloEdile SpA", text: $noleggiatore).textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Costo Giornaliero (€/gg):").font(.caption).bold().foregroundColor(.secondary)
                                TextField("50", text: $costoGiornalieroText).textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Data Inizio Nolo:").font(.caption).bold().foregroundColor(.secondary)
                                DatePicker("", selection: $dataInizioNolo, displayedComponents: .date).labelsHidden()
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Data Fine Prevista Rientro:").font(.caption).bold().foregroundColor(.secondary)
                                DatePicker("", selection: $dataFinePrevista, displayedComponents: .date).labelsHidden()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Note / Condizioni:").font(.caption).bold().foregroundColor(.secondary)
                            TextField("Note aggiuntive nolo...", text: $noteNolo).textFieldStyle(.roundedBorder)
                        }
                        
                        Button(action: {
                            let costo = Double(costoGiornalieroText) ?? 0.0
                            let nolo = NoleggioAttrezzatura(descrizione: descrizione, noleggiatore: noleggiatore, costoGiornaliero: costo, dataInizioNolo: dataInizioNolo, dataFinePrevista: dataFinePrevista, isRestituito: false, note: noteNolo)
                            cantiere.noleggiAttrezzature.append(nolo)
                            manager.save()
                            descrizione = ""
                            noteNolo = ""
                        }) {
                            Label("Registra Noleggio", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(descrizione.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(14)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
                    .padding(4)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Attrezzature in Noleggio per Cantiere:").font(.caption).bold().foregroundColor(.secondary)
                        
                        if cantiere.noleggiAttrezzature.isEmpty {
                            Text("Nessun noleggio attrezzatura registrato.").font(.caption).foregroundColor(.secondary).padding(.vertical, 10)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(cantiere.noleggiAttrezzature) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text("🚜 \(item.descrizione)").font(.manrope(12, weight: .bold))
                                                if item.isRestituito {
                                                    Text("✓ Restituito").font(.manrope(10, weight: .bold)).foregroundColor(.green)
                                                } else {
                                                    let diff = Calendar.current.dateComponents([.day], from: Date(), to: item.dataFinePrevista).day ?? 0
                                                    Text("In Nolo (\(diff) gg rimanenti)")
                                                        .font(.manrope(10, weight: .bold))
                                                        .foregroundColor(diff <= 2 ? .red : .orange)
                                                }
                                            }
                                            Text("Fornitore: \(item.noleggiatore) • € \(Int(item.costoGiornaliero))/gg • Rientro: \(item.dataFinePrevista.formatted(date: .numeric, time: .omitted))")
                                                .font(.manrope(10)).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                if let idx = cantiere.noleggiAttrezzature.firstIndex(where: { $0.id == item.id }) {
                                                    cantiere.noleggiAttrezzature[idx].isRestituito.toggle()
                                                    manager.save()
                                                }
                                            }) {
                                                Text(item.isRestituito ? "Riapri Nolo" : "Segna Restituito")
                                                    .font(.manrope(10, weight: .semibold))
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.mini)
                                            
                                            Button(action: {
                                                cantiere.noleggiAttrezzature.removeAll(where: { $0.id == item.id })
                                                manager.save()
                                            }) {
                                                Image(systemName: "trash").font(.caption).foregroundColor(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            Button("Chiudi") { dismiss() }.buttonStyle(.bordered)
        }
        .padding(20)
        .frame(minWidth: 580, idealWidth: 640, minHeight: 480, maxHeight: 720)
    }
}