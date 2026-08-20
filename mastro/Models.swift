import Foundation
import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers
import UserNotifications
import PDFKit
import EventKit

// MARK: - Manrope Universal Font Extension
extension Font {
    public static func manrope(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        switch weight {
        case .black, .heavy, .bold:
            fontName = "Manrope-Bold"
        case .semibold, .medium:
            fontName = "Manrope-SemiBold"
        case .light, .ultraLight, .thin:
            fontName = "Manrope-Light"
        default:
            fontName = "Manrope-Regular"
        }
        return Font.custom(fontName, size: size)
    }
}
// MARK: - Giornale dei Lavori
struct NotaGiornale: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var data: Date = Date()
    var meteo: String = "Sereno ☀️"
    var operaiPresenti: [String] = []
    var descrizioneLavori: String = ""
    var noteSicurezza: String = ""
}

struct QuickLinkItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var titolo: String
    var icona: String = "link"
    var urlStr: String
}

// MARK: - Impostazioni Globali dell'Azienda & Cartelle Radice
struct AppSettings: Codable {
    var nomeAzienda: String = "Impresa Edile"
    var logoFileName: String = ""
    var linkWebmail: String = "https://mail.google.com"
    var linkFatture: String = "https://areariservata.agenziaentrate.gov.it"
    var linkPec: String = ""
    var linkCassettoFiscale: String = ""
    var temaSelezionato: Int = 1 // 0: Auto, 1: Light, 2: Dark
    
    // Cartelle di destinazione e Cartella Madre personalizzabile
    var customCartellaMadreDir: String = ""
    var customCantieriDir: String = ""
    var customMezziDir: String = ""
    var customDipendentiDir: String = ""
    var customSubappaltatoriDir: String = ""
    var customPreventiviDir: String = ""
    
    // Accessi Rapidi personalizzati aggiuntivi
    var customQuickLinks: [QuickLinkItem] = []
    var syncGoogleCalendarAuto: Bool = true
    var enableSoundEffects: Bool = true
}

// MARK: - Subappaltatore (Ditte & Artigiani Esterni)
struct Subappaltatore: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ragioneSociale: String
    var referente: String
    var partitaIva: String
    var telefono: String
    var email: String
    var cartellaPath: String = ""
    var documenti: [String: String] = [:]
    var scadenze: [String: Date] = [:]
}

// MARK: - Registro Ore Personale (Manodopera)
struct RegistroOre: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var dipendenteID: UUID
    var dipendenteNome: String
    var data: Date = Date()
    var oreOrdinarie: Double = 8.0
    var oreStraordinarie: Double = 0.0
    var note: String = ""
}

// MARK: - Registro Rifiuti Edili (Formulari FIR)
struct FormularioFIR: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var numeroFIR: String
    var dataTrasporto: Date = Date()
    var tipologiaRifiuto: String // es. Macerie/Demolizioni, Cartongesso, Plastica, Ferro, Pericolosi
    var quantitaKg: Double = 0.0
    var impiantoDestinazione: String
    var note: String = ""
}

// MARK: - Registro Consegna DPI & Sicurezza (D.Lgs. 81/08)
struct ConsegnaDPI: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var tipologiaDPI: String // es. Scarpe Antinfortunistiche, Casco di Protezione, Imbracatura, Mascherine FFP3
    var dataConsegna: Date = Date()
    var dataScadenzaRinnovo: Date? = nil
    var note: String = ""
}

// MARK: - Stato Avanzamento Lavori (SAL %) & Acconti Committente
struct StatoAvanzamentoSAL: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var titolo: String
    var percentuale: Double = 0.0 // es. 30.0 per 30%
    var importoSAL: Double = 0.0
    var dataRaggiungimento: Date = Date()
    var isFatturato: Bool = false
    var note: String = ""
}
// MARK: - Formazione & Sicurezza Dipendenti (Accordo Stato-Regioni)
struct AttestatoFormazione: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var titoloCorso: String // es. Formazione Generale Rischio Alto, Primo Soccorso, Antincendio, Patentino Gru, PIMUS
    var enteFormatore: String = ""
    var dataRilascio: Date = Date()
    var dataScadenza: Date? = nil
    var note: String = ""
    var certificatoPath: String = ""
}

// MARK: - DDT & Materiali in Ingresso Cantiere
struct DocumentoDDT: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var numeroDDT: String
    var dataDDT: Date = Date()
    var fornitore: String
    var descrizioneMateriali: String
    var importoStimato: Double = 0.0
    var note: String = ""
    var allegatoPath: String = ""
}

// MARK: - Noleggio Attrezzature & Ponteggi Cantiere
struct NoleggioAttrezzatura: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var descrizione: String // es. Miniescavatore 18 q.li, Ponteggio Tubi e Giunti 200mq, Trabattello
    var noleggiatore: String
    var costoGiornaliero: Double = 0.0
    var dataInizioNolo: Date = Date()
    var dataFinePrevista: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    var isRestituito: Bool = false
    var note: String = ""
}

// MARK: - Modelli Entità
struct Cantiere: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var nome: String
    var indirizzo: String
    var dataInizio: Date
    var dataFine: Date
    var committente: String
    var cartellaPath: String
    var isTerminato: Bool = false
    var noteDescrizione: String = ""
    var dipendentiAssegnatiIDs: [UUID] = []
    var mezziAssegnatiIDs: [UUID] = []
    var subappaltatoriAssegnatiIDs: [UUID] = []
    var giornaleLavori: [NotaGiornale] = []
    var registroOre: [RegistroOre] = []
    var formulariFIR: [FormularioFIR] = []
    var statiAvanzamentoSAL: [StatoAvanzamentoSAL] = []
    var registroDDT: [DocumentoDDT] = []
    var noleggiAttrezzature: [NoleggioAttrezzatura] = []
    var documenti: [String: String] = [:]
    var scadenze: [String: Date] = [:]
}

struct Mezzo: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var emoji: String = "🚛"
    var targa: String
    var modello: String
    var tipo: String
    var referente: String
    var cartellaPath: String
    var documenti: [String: String] = [:]
    var scadenze: [String: Date] = [:]
}

struct Dipendente: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var nome: String
    var mansione: String
    var codiceFiscale: String
    var fotoFileName: String = ""
    var cartellaPath: String
    var noteDescrizione: String = ""
    var registroDPI: [ConsegnaDPI] = []
    var corsiFormazione: [AttestatoFormazione] = []
    var documenti: [String: String] = [:]
    var scadenze: [String: Date] = [:]
}

struct ScadenzaItem: Identifiable, Hashable {
    var id: String { "\(entitaID)_\(titolo)_\(data.timeIntervalSince1970)" }
    var entitaID: UUID
    var entitaNome: String
    var categoria: String
    var titolo: String
    var data: Date
    var giorniRimanenti: Int
}

struct PreventivoFileItem: Identifiable, Hashable {
    var id: String { url.path }
    var name: String
    var url: URL
    var modificationDate: Date
    var fileSize: Int64
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

// MARK: - Sistema Notifiche Toast & Audio Feedback

enum ToastType {
    case success
    case info
    case warning
    case delete
}

struct ToastNotification: Identifiable, Equatable {
    let id: UUID = UUID()
    let titolo: String
    let icona: String
    let tipo: ToastType
}

struct SoundManager {
    static func playSuccess(enabled: Bool = true) {
        guard enabled else { return }
        if let sound = NSSound(named: "Glass") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    static func playDelete(enabled: Bool = true) {
        guard enabled else { return }
        if let sound = NSSound(named: "Pop") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    static func playNotice(enabled: Bool = true) {
        guard enabled else { return }
        if let sound = NSSound(named: "Subtle") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}

// MARK: - Data Manager
@MainActor
class AppDataManager: ObservableObject {
    @Published var settings: AppSettings = AppSettings()
    @Published var cantieri: [Cantiere] = []
    @Published var mezzi: [Mezzo] = []
    @Published var dipendenti: [Dipendente] = []
    @Published var subappaltatori: [Subappaltatore] = []
    @Published var logoImage: NSImage? = nil
    
    // Toast Notification State
    @Published var activeToast: ToastNotification? = nil
    private var toastWorkItem: DispatchWorkItem? = nil
    
    func showToast(titolo: String, icona: String = "checkmark.circle.fill", tipo: ToastType = .success) {
        toastWorkItem?.cancel()
        
        let soundEnabled = settings.enableSoundEffects
        switch tipo {
        case .success, .info:
            SoundManager.playSuccess(enabled: soundEnabled)
        case .delete, .warning:
            SoundManager.playDelete(enabled: soundEnabled)
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            activeToast = ToastNotification(titolo: titolo, icona: icona, tipo: tipo)
        }
        
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    self?.activeToast = nil
                }
            }
        }
        toastWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8, execute: work)
    }
    
    let baseDir: URL
    private let dbFile: URL
    private let settingsFile: URL
    let defaultCantieriDir: URL
    let defaultMezziDir: URL
    let defaultDipendentiDir: URL
    let defaultSubappaltatoriDir: URL
    let defaultPreventiviDir: URL
    let assetsDir: URL
    
    // Cartella Madre Personalizzata o Predefinita sul Desktop di macOS
    var activeCartellaMadreDir: URL {
        if !settings.customCartellaMadreDir.isEmpty {
            let customURL = URL(fileURLWithPath: settings.customCartellaMadreDir)
            try? FileManager.default.createDirectory(at: customURL, withIntermediateDirectories: true)
            return customURL
        }
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let desktopFolder = desktop.appendingPathComponent("mastro_archivio", isDirectory: true)
        try? FileManager.default.createDirectory(at: desktopFolder, withIntermediateDirectories: true)
        return desktopFolder
    }
    
    var activeCantieriDir: URL {
        if !settings.customCantieriDir.isEmpty {
            let customURL = URL(fileURLWithPath: settings.customCantieriDir)
            try? FileManager.default.createDirectory(at: customURL, withIntermediateDirectories: true)
            return customURL
        }
        let dir = activeCartellaMadreDir.appendingPathComponent("Archivio_Cantieri", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    var activeMezziDir: URL {
        if !settings.customMezziDir.isEmpty {
            let customURL = URL(fileURLWithPath: settings.customMezziDir)
            try? FileManager.default.createDirectory(at: customURL, withIntermediateDirectories: true)
            return customURL
        }
        let dir = activeCartellaMadreDir.appendingPathComponent("Archivio_Mezzi", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    var activeDipendentiDir: URL {
        if !settings.customDipendentiDir.isEmpty {
            let customURL = URL(fileURLWithPath: settings.customDipendentiDir)
            try? FileManager.default.createDirectory(at: customURL, withIntermediateDirectories: true)
            return customURL
        }
        let dir = activeCartellaMadreDir.appendingPathComponent("Archivio_Dipendenti", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    var activeSubappaltatoriDir: URL {
        if !settings.customSubappaltatoriDir.isEmpty {
            let customURL = URL(fileURLWithPath: settings.customSubappaltatoriDir)
            try? FileManager.default.createDirectory(at: customURL, withIntermediateDirectories: true)
            return customURL
        }
        let dir = activeCartellaMadreDir.appendingPathComponent("Archivio_Subappalti", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    var activePreventiviDir: URL {
        if !settings.customPreventiviDir.isEmpty {
            let customURL = URL(fileURLWithPath: settings.customPreventiviDir)
            try? FileManager.default.createDirectory(at: customURL, withIntermediateDirectories: true)
            return customURL
        }
        let dir = activeCartellaMadreDir.appendingPathComponent("Archivio_Preventivi", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    let docsObbligatoriCantiere = [
        "POS (Piano Operativo Sicurezza)",
        "DURC Aggiornato",
        "Polizza CAR / Decennale Postuma",
        "Notifica Preliminare / PSC",
        "Idoneità Tecnico-Professionale"
    ]
    
    let docsObbligatoriMezzo = [
        "Polizza Assicurativa (RCA)",
        "Bollo di Circolazione",
        "Revisione Periodica MCTC",
        "Tagliando & Manutenzione",
        "Verifica Periodica INAIL / Gru"
    ]
    
    let docsObbligatoriDipendente = [
        "Carta d'Identità (C.I.)",
        "Tessera Sanitaria (TEAM)",
        "Visita Medica Idoneità",
        "Formazione Sicurezza (81/08)",
        "Patentino Macchine / Ponteggi",
        "Attestato Primo Soccorso / Antincendio",
        "Contratto / UNILAV"
    ]
    
    let docsObbligatoriSubappaltatore = [
        "DURC Subappalto Aggiornato",
        "POS (Piano Operativo Sicurezza) Subappalto",
        "Polizza RCT / RCO Subappaltatore",
        "Idoneità Tecnico-Professionale (Allegato XVII 81/08)",
        "Tessera di Riconoscimento Operai Esterni"
    ]
    
    let availableEmojis = ["🚛", "🚚", "🚜", "🏗️", "🚐", "🛻", "🚗", "⚡️", "🛠️"]
    
    init() {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.baseDir = docs.appendingPathComponent("GestoreCantieriApp", isDirectory: true)
        
        self.defaultCantieriDir = baseDir.appendingPathComponent("Archivio_Cantieri", isDirectory: true)
        self.defaultMezziDir = baseDir.appendingPathComponent("Archivio_Mezzi", isDirectory: true)
        self.defaultDipendentiDir = baseDir.appendingPathComponent("Archivio_Dipendenti", isDirectory: true)
        self.defaultSubappaltatoriDir = baseDir.appendingPathComponent("Archivio_Subappalti", isDirectory: true)
        self.defaultPreventiviDir = baseDir.appendingPathComponent("Archivio_Preventivi", isDirectory: true)
        self.assetsDir = baseDir.appendingPathComponent("Asset_Azienda", isDirectory: true)
        
        self.dbFile = baseDir.appendingPathComponent("gestionale_db.json")
        self.settingsFile = baseDir.appendingPathComponent("settings.json")
        
        try? fileManager.createDirectory(at: defaultCantieriDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: defaultMezziDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: defaultDipendentiDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: defaultSubappaltatoriDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: defaultPreventiviDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        registerManropeFont()
        load()
        loadLogo()
        pianificaNotificheScadenze()
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.save()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.save()
            }
        }
    }
    
    func save() {
        struct SaveContainer: Codable {
            var cantieri: [Cantiere]
            var mezzi: [Mezzo]
            var dipendenti: [Dipendente]
            var subappaltatori: [Subappaltatore]?
        }
        let payload = SaveContainer(cantieri: cantieri, mezzi: mezzi, dipendenti: dipendenti, subappaltatori: subappaltatori)
        
        let encodedDbData = try? JSONEncoder().encode(payload)
        let encodedSettingsData = try? JSONEncoder().encode(settings)
        let targetDbFile = dbFile
        let targetSettingsFile = settingsFile
        
        // Scrittura immediata ed atomica delle impostazioni su disco per evitare perdite al riavvio
        if let data = encodedSettingsData {
            try? data.write(to: targetSettingsFile, options: .atomic)
        }
        
        DispatchQueue.global(qos: .utility).async {
            if let data = encodedDbData {
                try? data.write(to: targetDbFile, options: .atomic)
            }
        }
        
        loadLogo()
        pianificaNotificheScadenze()
        updateWindowTitle()
    }
    
    func registerManropeFont() {
        let fontPaths = [
            Bundle.main.path(forResource: "Manrope", ofType: "ttf"),
            "/Users/francescozanchetta/Desktop/mastro/mastro/Resources/Fonts/Manrope.ttf"
        ]
        for path in fontPaths {
            if let p = path, FileManager.default.fileExists(atPath: p) {
                let fontURL = URL(fileURLWithPath: p)
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
            }
        }
    }

    func updateWindowTitle() {
        let nome = settings.nomeAzienda.trimmingCharacters(in: .whitespaces)
        let titleStr = nome.isEmpty ? "mastro" : "mastro - \"\(nome)\""
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                window.title = titleStr
            }
        }
    }
    
    func load() {
        if let sData = try? Data(contentsOf: settingsFile),
           let sDecoded = try? JSONDecoder().decode(AppSettings.self, from: sData) {
            self.settings = sDecoded
        }
        updateWindowTitle()
        
        if let data = try? Data(contentsOf: dbFile) {
            struct LoadContainer: Codable {
                var cantieri: [Cantiere]
                var mezzi: [Mezzo]
                var dipendenti: [Dipendente]?
                var subappaltatori: [Subappaltatore]?
            }
            if let decoded = try? JSONDecoder().decode(LoadContainer.self, from: data) {
                self.cantieri = decoded.cantieri
                self.mezzi = decoded.mezzi
                self.dipendenti = decoded.dipendenti ?? []
                self.subappaltatori = decoded.subappaltatori ?? []
            }
        }
        
        loadLogo()
    }
    
    private func creaMacAppIconConSfondoBianco(da logo: NSImage?) -> NSImage {
        let size = CGSize(width: 512, height: 512)
        let newIcon = NSImage(size: size)
        
        newIcon.lockFocus()
        
        let rect = CGRect(origin: .zero, size: size)
        let path = NSBezierPath(roundedRect: rect.insetBy(dx: 16, dy: 16), xRadius: 100, yRadius: 100)
        
        NSColor.white.setFill()
        path.fill()
        
        NSColor(white: 0, alpha: 0.1).setStroke()
        path.lineWidth = 4
        path.stroke()
        
        if let logo = logo {
            let origSize = logo.size
            let imgW = max(1, origSize.width)
            let imgH = max(1, origSize.height)
            let aspect = imgW / imgH
            
            let maxBoxSize: CGFloat = 360
            var drawW: CGFloat = maxBoxSize
            var drawH: CGFloat = maxBoxSize
            
            if aspect > 1 {
                drawH = maxBoxSize / aspect
            } else {
                drawW = maxBoxSize * aspect
            }
            
            let drawX = (512 - drawW) / 2
            let drawY = (512 - drawH) / 2
            let drawRect = CGRect(x: drawX, y: drawY, width: drawW, height: drawH)
            
            logo.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        } else {
            // Icona predefinita dell'app: Quadrato solo bordi nero su bianco (minimalista)
            let margin: CGFloat = 130
            let squareRect = CGRect(x: margin, y: margin, width: 512 - (margin * 2), height: 512 - (margin * 2))
            let squarePath = NSBezierPath(roundedRect: squareRect, xRadius: 24, yRadius: 24)
            squarePath.lineWidth = 28
            NSColor.black.setStroke()
            squarePath.stroke()
        }
        
        newIcon.unlockFocus()
        return newIcon
    }
    
    func loadLogo() {
        var loadedImage: NSImage? = nil
        
        // 1. Prova a caricare con il nome specificato nelle impostazioni
        if !settings.logoFileName.isEmpty {
            let possibleUrls = [
                assetsDir.appendingPathComponent(settings.logoFileName),
                URL(fileURLWithPath: settings.logoFileName)
            ]
            for url in possibleUrls {
                if FileManager.default.fileExists(atPath: url.path),
                   let data = try? Data(contentsOf: url),
                   let img = NSImage(data: data) {
                    loadedImage = img
                    break
                }
            }
        }
        
        // Assegna il logo caricato ed aggiorna l'icona del Mac nel Dock (o usa il camioncino 🚛 se assente)
        self.logoImage = loadedImage
        NSApplication.shared.applicationIconImage = creaMacAppIconConSfondoBianco(da: loadedImage)
    }
    
    func resetAllDataToCleanState() {
        cantieri = []
        mezzi = []
        dipendenti = []
        subappaltatori = []
        settings = AppSettings()
        logoImage = nil
        NSApplication.shared.applicationIconImage = creaMacAppIconConSfondoBianco(da: nil)
        
        try? FileManager.default.removeItem(at: dbFile)
        try? FileManager.default.removeItem(at: settingsFile)
        try? FileManager.default.removeItem(at: assetsDir)
        
        save()
        updateWindowTitle()
        showToast(titolo: "Database e logo resettati! L'app è ora 100% pulita.", icona: "trash.circle.fill", tipo: .info)
    }
    
    func salvaNuovoLogo(da urlSorgente: URL) {
        let estensione = urlSorgente.pathExtension.isEmpty ? "png" : urlSorgente.pathExtension
        let nomeFile = "logo_azienda.\(estensione)"
        let destinazione = assetsDir.appendingPathComponent(nomeFile)
        
        try? FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        
        // Pulisce vecchi file di logo
        if let existing = try? FileManager.default.contentsOfDirectory(at: assetsDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            for f in existing where f.lastPathComponent.lowercased().contains("logo") {
                try? FileManager.default.removeItem(at: f)
            }
        }
        
        if let data = try? Data(contentsOf: urlSorgente) {
            try? data.write(to: destinazione, options: .atomic)
            settings.logoFileName = nomeFile
            save()
            showToast(titolo: "Logo aziendale aggiornato", icona: "photo.badge.checkmark", tipo: .success)
        }
    }
    
    func rimuoviLogo() {
        if let existing = try? FileManager.default.contentsOfDirectory(at: assetsDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            for f in existing where f.lastPathComponent.lowercased().contains("logo") {
                try? FileManager.default.removeItem(at: f)
            }
        }
        settings.logoFileName = ""
        self.logoImage = nil
        NSApplication.shared.applicationIconImage = creaMacAppIconConSfondoBianco(da: nil)
        save()
        showToast(titolo: "Logo aziendale rimosso", icona: "trash", tipo: .delete)
    }
    
    var tuttiGliAccessiRapidi: [QuickLinkItem] {
        var list: [QuickLinkItem] = []
        if !settings.linkWebmail.isEmpty {
            list.append(QuickLinkItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, titolo: "Webmail", icona: "envelope.fill", urlStr: settings.linkWebmail))
        }
        if !settings.linkFatture.isEmpty {
            list.append(QuickLinkItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, titolo: "Fatture SDI", icona: "doc.plaintext.fill", urlStr: settings.linkFatture))
        }
        if !settings.linkPec.isEmpty {
            list.append(QuickLinkItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, titolo: "Posta PEC", icona: "lock.shield.fill", urlStr: settings.linkPec))
        }
        if !settings.linkCassettoFiscale.isEmpty {
            list.append(QuickLinkItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, titolo: "Cassetto Fiscale", icona: "building.columns.fill", urlStr: settings.linkCassettoFiscale))
        }
        list.append(contentsOf: settings.customQuickLinks)
        return list
    }
    
    func recuperaPreventiviFiles() -> [PreventivoFileItem] {
        let dir = activePreventiviDir
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: .skipsHiddenFiles) else {
            return []
        }
        return contents.compactMap { fileUrl in
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: fileUrl.path, isDirectory: &isDir), !isDir.boolValue {
                let values = try? fileUrl.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                let modDate = values?.contentModificationDate ?? Date.distantPast
                let size = Int64(values?.fileSize ?? 0)
                return PreventivoFileItem(name: fileUrl.lastPathComponent, url: fileUrl, modificationDate: modDate, fileSize: size)
            }
            return nil
        }
    }
    
    func importaFileInPreventivi(da urlSorgente: URL) {
        let destinazione = activePreventiviDir.appendingPathComponent(urlSorgente.lastPathComponent)
        try? FileManager.default.copyItem(at: urlSorgente, to: destinazione)
        showToast(titolo: "Preventivo caricato nell'archivio 📄", icona: "doc.badge.plus", tipo: .success)
    }
    
    func getDipendenteFoto(fileName: String) -> NSImage? {
        guard !fileName.isEmpty else { return nil }
        let url = URL(fileURLWithPath: fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            return NSImage(contentsOf: url)
        }
        let assetUrl = assetsDir.appendingPathComponent(fileName)
        return NSImage(contentsOf: assetUrl)
    }
    
    func salvaFotoDipendente(da urlSorgente: URL) -> String {
        return urlSorgente.path // Salva solo il collegamento al file esistente
    }
    
    func cantieriAttiviPerDipendente(_ dipendenteID: UUID) -> [Cantiere] {
        return cantieri.filter { !$0.isTerminato && $0.dipendentiAssegnatiIDs.contains(dipendenteID) }
    }
    
    func dipendentiDisponibili() -> [Dipendente] {
        let assegnatiIDs = Set(cantieri.filter { !$0.isTerminato }.flatMap { $0.dipendentiAssegnatiIDs })
        return dipendenti.filter { !assegnatiIDs.contains($0.id) }
    }
    
    func richiediPermessiNotifiche() {
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared
        
        center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.showToast(titolo: "Notifiche macOS attivate con successo! 🔔", icona: "bell.badge.fill", tipo: .success)
                    SoundManager.playNotice()
                    self.inviaNotificaDiProva()
                } else {
                    self.showToast(titolo: "Permessi disattivati. Apertura Preferenze Notifiche macOS...", icona: "bell.slash.fill", tipo: .warning)
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
    
    func inviaNotificaDiProva() {
        let content = UNMutableNotificationContent()
        content.title = "🔔 mastro - Notifiche macOS"
        content.body = "Le notifiche di sistema sono attive! Riceverai avvisi automatici per scadenze cantieri, DPI e mezzi."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notif_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func pianificaNotificheScadenze() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let now = Date()
        
        for mezzo in mezzi {
            for (nomeScadenza, dataScadenza) in mezzo.scadenze {
                if let diff = Calendar.current.dateComponents([.day], from: now, to: dataScadenza).day, diff >= 0 && diff <= 30 {
                    creaNotifica(
                        titolo: "⚠️ Scadenza Mezzo: \(mezzo.modello) [\(mezzo.targa)]",
                        corpo: "\(nomeScadenza) in scadenza tra \(diff) giorni",
                        identificativo: "mezzo_\(mezzo.id)_\(nomeScadenza)"
                    )
                }
            }
        }
        
        for cantiere in cantieri where !cantiere.isTerminato {
            for (nomeScadenza, dataScadenza) in cantiere.scadenze {
                if let diff = Calendar.current.dateComponents([.day], from: now, to: dataScadenza).day, diff >= 0 && diff <= 30 {
                    creaNotifica(
                        titolo: "🏗️ Cantiere: \(cantiere.nome)",
                        corpo: "\(nomeScadenza) in scadenza tra \(diff) giorni",
                        identificativo: "cantiere_\(cantiere.id)_\(nomeScadenza)"
                    )
                }
            }
        }
    }
    
    private func creaNotifica(titolo: String, corpo: String, identificativo: String) {
        let content = UNMutableNotificationContent()
        content.title = titolo
        content.body = corpo
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: identificativo, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func openInFinder(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    func openFolder(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }
    
    func openBaseFolder() {
        openFolder(path: activeCartellaMadreDir.path)
    }
    
    func openBrowser(urlStr: String) {
        guard let url = URL(string: urlStr), !urlStr.isEmpty else { return }
        NSWorkspace.shared.open(url)
    }
    
    var totalAlerts: Int {
        tutteLeScadenze(entroGiorni: 30).count
    }
    
    func tutteLeScadenze(entroGiorni: Int) -> [ScadenzaItem] {
        var items: [ScadenzaItem] = []
        let now = Date()
        
        for c in cantieri where !c.isTerminato {
            for (nomeDoc, data) in c.scadenze {
                if let diff = Calendar.current.dateComponents([.day], from: now, to: data).day, diff <= entroGiorni {
                    items.append(ScadenzaItem(entitaID: c.id, entitaNome: c.nome, categoria: "Cantiere", titolo: nomeDoc, data: data, giorniRimanenti: diff))
                }
            }
        }
        for m in mezzi {
            for (nomeDoc, data) in m.scadenze {
                if let diff = Calendar.current.dateComponents([.day], from: now, to: data).day, diff <= entroGiorni {
                    items.append(ScadenzaItem(entitaID: m.id, entitaNome: "\(m.modello) (\(m.targa))", categoria: "Mezzo", titolo: nomeDoc, data: data, giorniRimanenti: diff))
                }
            }
        }
        for d in dipendenti {
            for (nomeDoc, data) in d.scadenze {
                if let diff = Calendar.current.dateComponents([.day], from: now, to: data).day, diff <= entroGiorni {
                    items.append(ScadenzaItem(entitaID: d.id, entitaNome: d.nome, categoria: "Dipendente", titolo: nomeDoc, data: data, giorniRimanenti: diff))
                }
            }
        }
        for sub in subappaltatori {
            for (nomeDoc, data) in sub.scadenze {
                if let diff = Calendar.current.dateComponents([.day], from: now, to: data).day, diff <= entroGiorni {
                    items.append(ScadenzaItem(entitaID: sub.id, entitaNome: sub.ragioneSociale, categoria: "Subappalto", titolo: nomeDoc, data: data, giorniRimanenti: diff))
                }
            }
        }
        for d in dipendenti {
            for dpi in d.registroDPI {
                if let dataRinnovo = dpi.dataScadenzaRinnovo {
                    if let diff = Calendar.current.dateComponents([.day], from: now, to: dataRinnovo).day, diff <= entroGiorni {
                        items.append(ScadenzaItem(entitaID: d.id, entitaNome: d.nome, categoria: "DPI / D.Lgs 81/08", titolo: "Rinnovo DPI: \(dpi.tipologiaDPI)", data: dataRinnovo, giorniRimanenti: diff))
                    }
                }
            }
            for corso in d.corsiFormazione {
                if let dataScad = corso.dataScadenza {
                    if let diff = Calendar.current.dateComponents([.day], from: now, to: dataScad).day, diff <= entroGiorni {
                        items.append(ScadenzaItem(entitaID: d.id, entitaNome: d.nome, categoria: "Formazione Sicurezza", titolo: "Scadenza Attestato: \(corso.titoloCorso)", data: dataScad, giorniRimanenti: diff))
                    }
                }
            }
        }
        for c in cantieri where !c.isTerminato {
            for nolo in c.noleggiAttrezzature where !nolo.isRestituito {
                if let diff = Calendar.current.dateComponents([.day], from: now, to: nolo.dataFinePrevista).day, diff <= entroGiorni {
                    items.append(ScadenzaItem(entitaID: c.id, entitaNome: c.nome, categoria: "Noleggio Attrezzatura", titolo: "Rientro Nolo: \(nolo.descrizione)", data: nolo.dataFinePrevista, giorniRimanenti: diff))
                }
            }
        }
        return items.sorted(by: { $0.giorniRimanenti < $1.giorniRimanenti })
    }
    
    // MARK: - Sincronizzazione Nativa ESCLUSIVAMENTE Google Calendar
    
    private let eventStore = EKEventStore()
    
    func trovaGoogleCalendar() -> EKCalendar? {
        let calendars = eventStore.calendars(for: .event)
        if let googleCal = calendars.first(where: {
            let srcTitle = $0.source.title.lowercased()
            let calTitle = $0.title.lowercased()
            return srcTitle.contains("google") || srcTitle.contains("gmail") || calTitle.contains("google") || calTitle.contains("gmail")
        }) {
            return googleCal
        }
        if let calDav = calendars.first(where: { $0.source.sourceType == .calDAV && !$0.source.title.lowercased().contains("icloud") }) {
            return calDav
        }
        return nil
    }
    
    func sincronizzaScadenzaSuGoogleCalendar(titolo: String, dettagli: String, data: Date) {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                guard granted else { return }
                Task { @MainActor [weak self] in
                    self?.salvaEventoNativoGoogleCalendar(titolo: titolo, dettagli: dettagli, data: data)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                guard granted else { return }
                Task { @MainActor [weak self] in
                    self?.salvaEventoNativoGoogleCalendar(titolo: titolo, dettagli: dettagli, data: data)
                }
            }
        }
    }
    
    private func salvaEventoNativoGoogleCalendar(titolo: String, dettagli: String, data: Date) {
        guard let targetCalendar = trovaGoogleCalendar() else {
            apriGoogleCalendarWeb(titolo: titolo, dettagli: dettagli, data: data)
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.calendar = targetCalendar
        event.title = titolo
        event.notes = dettagli
        event.startDate = data
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: data) ?? data
        event.isAllDay = true
        
        // Promemoria notifica a 3 giorni prima ed a 1 giorno prima
        let alarm3Gg = EKAlarm(relativeOffset: -259200) // 3 giorni prima (3 * 86400 sec)
        let alarm1Gg = EKAlarm(relativeOffset: -86400)  // 1 giorno prima
        event.addAlarm(alarm3Gg)
        event.addAlarm(alarm1Gg)
        
        try? eventStore.save(event, span: .thisEvent)
        showToast(titolo: "Notifica 3gg salvata su Google Calendar 📅", icona: "calendar.badge.plus", tipo: .success)
    }
    
    func apriGoogleCalendarWeb(titolo: String, dettagli: String, data: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dataStr = formatter.string(from: data)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: data) ?? data
        let nextDayStr = formatter.string(from: nextDay)
        
        let titleEnc = titolo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let detailsEnc = dettagli.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlStr = "https://calendar.google.com/calendar/render?action=TEMPLATE&text=\(titleEnc)&details=\(detailsEnc)&dates=\(dataStr)/\(nextDayStr)"
        openBrowser(urlStr: urlStr)
    }
    
    func aggiungiAGoogleCalendar(titolo: String, dettagli: String, data: Date) {
        sincronizzaScadenzaSuGoogleCalendar(titolo: titolo, dettagli: dettagli, data: data)
    }
    
    func eseguiBackupCompleto() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.zip]
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmm"
        savePanel.nameFieldStringValue = "Backup_\(settings.nomeAzienda)_\(df.string(from: Date())).zip"
        
        guard savePanel.runModal() == .OK, let destUrl = savePanel.url else { return }
        
        let coord = NSFileCoordinator()
        var error: NSError?
        let targetBaseDir = self.baseDir
        coord.coordinate(readingItemAt: targetBaseDir, options: .forUploading, error: &error) { zipUrl in
            try? FileManager.default.removeItem(at: destUrl)
            try? FileManager.default.copyItem(at: zipUrl, to: destUrl)
        }
    }
    
    func ripristinaDaBackup() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.zip]
        openPanel.allowsMultipleSelection = false
        guard openPanel.runModal() == .OK, let zipUrl = openPanel.url else { return }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let coord = NSFileCoordinator()
        var error: NSError?
        let targetBaseDir = self.baseDir
        coord.coordinate(readingItemAt: zipUrl, options: .withoutChanges, error: &error) { unzippedFolder in
            if let items = try? FileManager.default.contentsOfDirectory(at: unzippedFolder, includingPropertiesForKeys: nil) {
                for item in items {
                    let dest = targetBaseDir.appendingPathComponent(item.lastPathComponent)
                    try? FileManager.default.removeItem(at: dest)
                    try? FileManager.default.copyItem(at: item, to: dest)
                }
            }
            Task { @MainActor [weak self] in
                self?.load()
                self?.loadLogo()
            }
        }
    }
    
    func esportaRiepilogoPDF(cantiere: Cantiere) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.pdf]
        savePanel.nameFieldStringValue = "Fascicolo_\(cantiere.nome.replacingOccurrences(of: " ", with: "_")).pdf"
        
        guard savePanel.runModal() == .OK, let destUrl = savePanel.url else { return }
        
        let pdfData = creaPDFData(cantiere: cantiere)
        try? pdfData.write(to: destUrl)
    }
    
    func esportaVerbaleInizioLavori(cantiere: Cantiere) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.pdf]
        savePanel.nameFieldStringValue = "Verbale_Inizio_Lavori_\(cantiere.nome.replacingOccurrences(of: " ", with: "_")).pdf"
        guard savePanel.runModal() == .OK, let destUrl = savePanel.url else { return }
        
        let pdfData = creaVerbaleInizioLavoriPDF(cantiere: cantiere)
        try? pdfData.write(to: destUrl)
    }
    
    func esportaVerbaleUltimazioneLavori(cantiere: Cantiere) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.pdf]
        savePanel.nameFieldStringValue = "Verbale_Ultimazione_Lavori_\(cantiere.nome.replacingOccurrences(of: " ", with: "_")).pdf"
        guard savePanel.runModal() == .OK, let destUrl = savePanel.url else { return }
        
        let pdfData = creaVerbaleUltimazioneLavoriPDF(cantiere: cantiere)
        try? pdfData.write(to: destUrl)
    }
    
     private func disegnaLogoSuPDF(context: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        guard let logo = logoImage, let cgImage = logo.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        
        let logoBox = CGRect(x: x, y: y, width: width, height: height)
        context.setFillColor(NSColor.white.cgColor)
        context.fill(logoBox)
        
        let imgW = CGFloat(cgImage.width)
        let imgH = CGFloat(cgImage.height)
        let aspect = imgW / max(1, imgH)
        var drawW = width
        var drawH = height
        if aspect > 1 {
            drawH = width / aspect
        } else {
            drawW = height * aspect
        }
        let drawX = x + (width - drawW) / 2
        let drawY = y + (height - drawH) / 2
        context.draw(cgImage, in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH))
    }
    
    private func creaVerbaleInizioLavoriPDF(cantiere: Cantiere) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Gestore Cantieri Pro",
            kCGPDFContextAuthor: settings.nomeAzienda,
            kCGPDFContextTitle: "Verbale di Inizio Lavori - \(cantiere.nome)"
        ]
        var pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let data = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &pageRect, (pdfMetaData as CFDictionary)) else {
            return Data()
        }
        
        context.beginPage(mediaBox: &pageRect)
        var offsetY: CGFloat = 800
        
        disegnaLogoSuPDF(context: context, x: 40, y: offsetY - 45, width: 45, height: 45)
        
        let titleAttr: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 16), .foregroundColor: NSColor.black]
        let subAttr: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.darkGray]
        let bodyAttr: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let boldAttr: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]
        
        "\(settings.nomeAzienda.uppercased())\nVERBALE DI INIZIO LAVORI E CONSEGNA CANTIERE".draw(at: CGPoint(x: 95, y: offsetY - 35), withAttributes: titleAttr)
        offsetY -= 65
        
        context.setStrokeColor(NSColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 40, y: offsetY))
        context.addLine(to: CGPoint(x: 555, y: offsetY))
        context.strokePath()
        offsetY -= 25
        
        let testoIntro = """
        In data \(Date().formatted(date: .long, time: .omitted)), presso il cantiere denominato "\(cantiere.nome)",
        sito in \(cantiere.indirizzo.isEmpty ? "[Indirizzo non specificato]" : cantiere.indirizzo), tra le parti:
        
        • IMPRESA ESECUTRICE: \(settings.nomeAzienda)
        • COMMITTENTE: \(cantiere.committente.isEmpty ? "[Nome Committente]" : cantiere.committente)
        
        Si dichiara quanto segue:
        1. L'Impresa prende formalmente in consegna l'area di cantiere idonea all'avvio delle lavorazioni.
        2. La data ufficiale di inizio lavori viene stabilita in data \(cantiere.dataInizio.formatted(date: .long, time: .omitted)).
        3. Il termine contrattuale previsto per la fine dei lavori è fissato per il \(cantiere.dataFine.formatted(date: .long, time: .omitted)).
        4. Si dà atto che la documentazione di sicurezza (POS e idoneità professionale) è stata regolarmente predisposta.
        """
        testoIntro.draw(at: CGPoint(x: 40, y: offsetY - 140), withAttributes: bodyAttr)
        offsetY -= 170
        
        "FIRME PER ACCETTAZIONE E CONFERMA".draw(at: CGPoint(x: 40, y: offsetY), withAttributes: boldAttr)
        offsetY -= 60
        
        "L'Impresa Esecutrice\n\n_______________________\n(\(settings.nomeAzienda))".draw(at: CGPoint(x: 40, y: offsetY), withAttributes: bodyAttr)
        "Il Committente / D.L.\n\n_______________________\n(\(cantiere.committente.isEmpty ? "Firma Committente" : cantiere.committente))".draw(at: CGPoint(x: 320, y: offsetY), withAttributes: bodyAttr)
        
        "Generato con Gestore Cantieri Pro il \(Date().formatted(date: .numeric, time: .shortened))".draw(at: CGPoint(x: 40, y: 35), withAttributes: subAttr)
        
        context.endPage()
        context.closePDF()
        return data as Data
    }
    
    private func creaVerbaleUltimazioneLavoriPDF(cantiere: Cantiere) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Gestore Cantieri Pro",
            kCGPDFContextAuthor: settings.nomeAzienda,
            kCGPDFContextTitle: "Verbale di Ultimazione Lavori - \(cantiere.nome)"
        ]
        var pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let data = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &pageRect, (pdfMetaData as CFDictionary)) else {
            return Data()
        }
        
        context.beginPage(mediaBox: &pageRect)
        var offsetY: CGFloat = 800
        
        disegnaLogoSuPDF(context: context, x: 40, y: offsetY - 45, width: 45, height: 45)
        
        let titleAttr: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 16), .foregroundColor: NSColor.black]
        let subAttr: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.darkGray]
        let bodyAttr: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black]
        let boldAttr: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]
        
        "\(settings.nomeAzienda.uppercased())\nVERBALE DI ULTIMAZIONE LAVORI E COLLAUDO".draw(at: CGPoint(x: 95, y: offsetY - 35), withAttributes: titleAttr)
        offsetY -= 65
        
        context.setStrokeColor(NSColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 40, y: offsetY))
        context.addLine(to: CGPoint(x: 555, y: offsetY))
        context.strokePath()
        offsetY -= 25
        
        let testoUltimazione = """
        In data \(Date().formatted(date: .long, time: .omitted)), si attesta la formale ultimazione delle opere presso il cantiere:
        
        • NOME CANTIERE: \(cantiere.nome)
        • UBICAZIONE: \(cantiere.indirizzo.isEmpty ? "[Indirizzo non specificato]" : cantiere.indirizzo)
        • COMMITTENTE: \(cantiere.committente.isEmpty ? "[Nome Committente]" : cantiere.committente)
        • ESECUTORE: \(settings.nomeAzienda)
        
        Dichiarazioni di Ultimazione e Collaudo:
        1. Le opere pattuite sono state eseguite a regola d'arte in conformità al contratto e alle varianti concordate.
        2. L'area di cantiere è stata completamente sgomberata da attrezzature, ponteggi e materiali di scarto.
        3. Il Committente dichiara di aver visionato le opere e di riceverle senza riserve / con perfetto gradimento.
        4. Da oggi decorrono i termini di garanzia di legge per vizi e difetti dell'opera.
        """
        testoUltimazione.draw(at: CGPoint(x: 40, y: offsetY - 150), withAttributes: bodyAttr)
        offsetY -= 180
        
        "FIRME PER ACCETTAZIONE FINALE".draw(at: CGPoint(x: 40, y: offsetY), withAttributes: boldAttr)
        offsetY -= 60
        
        "L'Impresa Esecutrice\n\n_______________________\n(\(settings.nomeAzienda))".draw(at: CGPoint(x: 40, y: offsetY), withAttributes: bodyAttr)
        "Il Committente / D.L.\n\n_______________________\n(\(cantiere.committente.isEmpty ? "Firma Committente" : cantiere.committente))".draw(at: CGPoint(x: 320, y: offsetY), withAttributes: bodyAttr)
        
        "Generato con Gestore Cantieri Pro il \(Date().formatted(date: .numeric, time: .shortened))".draw(at: CGPoint(x: 40, y: 35), withAttributes: subAttr)
        
        context.endPage()
        context.closePDF()
        return data as Data
    }
    
    private func creaPDFData(cantiere: Cantiere) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Gestore Cantieri Pro",
            kCGPDFContextAuthor: settings.nomeAzienda,
            kCGPDFContextTitle: "Fascicolo Cantiere - \(cantiere.nome)"
        ]
        var pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let data = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &pageRect, (pdfMetaData as CFDictionary)) else {
            return Data()
        }
        
        context.beginPage(mediaBox: &pageRect)
        var offsetY: CGFloat = 800
        
        disegnaLogoSuPDF(context: context, x: 40, y: offsetY - 45, width: 45, height: 45)
        
        let titleAttr: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 16), .foregroundColor: NSColor.black]
        let subAttr: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.darkGray]
        let boldSubAttr: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black]
        
        "\(settings.nomeAzienda.uppercased())\nFascicolo Tecnico & Controllo Conformità".draw(at: CGPoint(x: 95, y: offsetY - 35), withAttributes: titleAttr)
        offsetY -= 65
        
        context.setStrokeColor(NSColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 40, y: offsetY))
        context.addLine(to: CGPoint(x: 555, y: offsetY))
        context.strokePath()
        offsetY -= 20
        
        let info = """
        Cantiere: \(cantiere.nome)
        Committente: \(cantiere.committente.isEmpty ? "N.D." : cantiere.committente)
        Indirizzo: \(cantiere.indirizzo.isEmpty ? "N.D." : cantiere.indirizzo)
        Periodo: Dal \(cantiere.dataInizio.formatted(date: .numeric, time: .omitted)) al \(cantiere.dataFine.formatted(date: .numeric, time: .omitted))
        Stato: \(cantiere.isTerminato ? "LAVORI TERMINATI" : "CANTIERE ATTIVO")
        """
        info.draw(at: CGPoint(x: 40, y: offsetY - 55), withAttributes: subAttr)
        offsetY -= 75
        
        "DOCUMENTAZIONE DI SICUREZZA (D.Lgs. 81/08)".draw(at: CGPoint(x: 40, y: offsetY), withAttributes: boldSubAttr)
        offsetY -= 18
        
        for doc in docsObbligatoriCantiere {
            let pres = cantiere.documenti[doc] != nil && FileManager.default.fileExists(atPath: cantiere.documenti[doc]!)
            let sc = cantiere.scadenze[doc]
            var stat = pres ? "✓ PRESENTE" : "✗ ASSENTE"
            if let d = sc, pres {
                let diff = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
                stat += " (Scadenza: \(d.formatted(date: .numeric, time: .omitted)) - \(diff) gg)"
            }
            doc.draw(at: CGPoint(x: 40, y: offsetY), withAttributes: subAttr)
            stat.draw(at: CGPoint(x: 320, y: offsetY), withAttributes: [
                .font: NSFont.boldSystemFont(ofSize: 9),
                .foregroundColor: pres ? NSColor(red: 0.1, green: 0.55, blue: 0.1, alpha: 1) : NSColor.red
            ])
            offsetY -= 16
        }
        
        offsetY -= 10
        
        "DIPENDENTI ASSEGNATI AL CANTIERE".draw(at: CGPoint(x: 40, y: offsetY), withAttributes: boldSubAttr)
        offsetY -= 16
        let assignedDips = dipendenti.filter { cantiere.dipendentiAssegnatiIDs.contains($0.id) }
        if assignedDips.isEmpty {
            "Nessun dipendente associato a questa commessa".draw(at: CGPoint(x: 40, y: offsetY), withAttributes: subAttr)
            offsetY -= 14
        } else {
            for d in assignedDips {
                "• \(d.nome) (\(d.mansione)) - C.F.: \(d.codiceFiscale)".draw(at: CGPoint(x: 40, y: offsetY), withAttributes: subAttr)
                offsetY -= 14
            }
        }
        
        offsetY -= 10
        
        "MEZZI E ATTREZZATURE ASSEGNATE".draw(at: CGPoint(x: 40, y: offsetY), withAttributes: boldSubAttr)
        offsetY -= 16
        let assignedMezzi = mezzi.filter { cantiere.mezziAssegnatiIDs.contains($0.id) }
        if assignedMezzi.isEmpty {
            "Nessun veicolo associato".draw(at: CGPoint(x: 40, y: offsetY), withAttributes: subAttr)
            offsetY -= 14
        } else {
            for m in assignedMezzi {
                "• \(m.modello) [\(m.targa)] - Tipologia: \(m.tipo)".draw(at: CGPoint(x: 40, y: offsetY), withAttributes: subAttr)
                offsetY -= 14
            }
        }
        
        "Generato automaticamente il \(Date().formatted(date: .complete, time: .shortened))".draw(at: CGPoint(x: 40, y: 35), withAttributes: subAttr)
        
        context.endPage()
        context.closePDF()
        return data as Data
    }
    
    func fileNonRegistrati(nella cartella: String, documentiNoti: [String: String]) -> [URL] {
        let folderUrl = URL(fileURLWithPath: cartella)
        guard let contents = try? FileManager.default.contentsOfDirectory(at: folderUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return []
        }
        let percorsiNoti = Set(documentiNoti.values)
        return contents.filter { url in
            !percorsiNoti.contains(url.path) && !url.hasDirectoryPath
        }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge, .list])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}