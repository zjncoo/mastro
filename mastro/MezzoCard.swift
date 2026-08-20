import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - Card Mezzo
struct MezzoCard: View {
    @Binding var mezzo: Mezzo
    @ObservedObject var manager: AppDataManager
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Menu {
                    ForEach(manager.availableEmojis, id: \.self) { emoji in
                        Button("\(emoji) Seleziona") {
                            mezzo.emoji = emoji
                            manager.save()
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.green.opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.green.opacity(0.25), lineWidth: 1))
                        Text(mezzo.emoji).font(.title3)
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(mezzo.modello.isEmpty ? "Veicolo" : mezzo.modello)
                            .font(.manrope(15, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(mezzo.targa)
                            .font(.manrope(11, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .foregroundColor(Color(red: 0.0, green: 0.40, blue: 0.85))
                            .cornerRadius(4)
                    }
                    
                    Text("Tipologia: \(mezzo.tipo) • Referente: \(mezzo.referente.isEmpty ? "Nessuno" : mezzo.referente)")
                        .font(.manrope(12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.manrope(13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color.primary.opacity(0.05), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Modifica Scheda Mezzo")
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.manrope(12, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Divider().opacity(0.4)
                    
                    HStack {
                        Button(action: { manager.openFolder(path: mezzo.cartellaPath) }) {
                            Label("Cartella Mezzo", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        Button(role: .destructive, action: onDelete) {
                            Label("Elimina Mezzo", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(manager.docsObbligatoriMezzo, id: \.self) { scName in
                            DocDropRowLiquid(
                                title: scName,
                                filePath: mezzo.documenti[scName],
                                expirationDate: Binding(
                                    get: { mezzo.scadenze[scName] ?? Date() },
                                    set: { mezzo.scadenze[scName] = $0; manager.save() }
                                ),
                                targetFolder: mezzo.cartellaPath,
                                onSyncCalendar: {
                                    if let d = mezzo.scadenze[scName] {
                                        manager.aggiungiAGoogleCalendar(
                                            titolo: "Scadenza \(scName): \(mezzo.modello) [\(mezzo.targa)]",
                                            dettagli: "Autista/Referente: \(mezzo.referente)",
                                            data: d
                                        )
                                    }
                                },
                                onFileAssigned: { originalPath in
                                    mezzo.documenti[scName] = originalPath
                                    manager.save()
                                },
                                onRemove: {
                                    mezzo.documenti.removeValue(forKey: scName)
                                    manager.save()
                                }
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 5)
    }
}

// MARK: - Card Dipendente
struct DipendenteCard: View {
    @Binding var dipendente: Dipendente
    @ObservedObject var manager: AppDataManager
    let isDarkMode: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isExpanded: Bool = false
    @State private var showingConsegnaDPISheet: Bool = false
    @State private var showingFormazioneSheet: Bool = false
    
    var progressCount: (Int, Int) {
        let present = manager.docsObbligatoriDipendente.filter {
            guard let path = dipendente.documenti[$0] else { return false }
            return FileManager.default.fileExists(atPath: path)
        }.count
        return (present, manager.docsObbligatoriDipendente.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                if let img = manager.getDipendenteFoto(fileName: dipendente.fotoFileName) {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.orange.opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.orange.opacity(0.25), lineWidth: 1))
                        Text("👷").font(.title3)
                    }
                    .frame(width: 44, height: 44)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(dipendente.nome.isEmpty ? "Dipendente" : dipendente.nome)
                            .font(.manrope(15, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(dipendente.mansione)
                            .font(.manrope(11, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.14))
                            .foregroundColor(Color(red: 0.85, green: 0.40, blue: 0))
                            .cornerRadius(4)
                    }
                    
                    HStack(spacing: 8) {
                        Text("C.F.: \(dipendente.codiceFiscale.isEmpty ? "Nessuno" : dipendente.codiceFiscale)")
                            .font(.manrope(12, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        let cantieriAssegnati = manager.cantieriAttiviPerDipendente(dipendente.id)
                        if cantieriAssegnati.isEmpty {
                            Text("🟢 Disponibile")
                                .font(.manrope(10, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.green.opacity(0.12))
                                .foregroundColor(Color(red: 0.05, green: 0.55, blue: 0.15))
                                .cornerRadius(4)
                        } else {
                            Text("🏗️ Assegnato a: \(cantieriAssegnati.map { $0.nome }.joined(separator: ", "))")
                                .font(.manrope(10, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.12))
                                .foregroundColor(.blue)
                                .lineLimit(1)
                                .cornerRadius(4)
                        }
                    }
                    
                    if !dipendente.noteDescrizione.isEmpty {
                        Text("📝 \(dipendente.noteDescrizione)")
                            .font(.manrope(11, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.manrope(13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color.primary.opacity(0.05), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Modifica Dipendente & Foto")
                
                let (present, total) = progressCount
                Text("\(present)/\(total) Documenti")
                    .font(.manrope(11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(present == total ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .foregroundColor(present == total ? Color(red: 0.05, green: 0.55, blue: 0.15) : Color(red: 0.85, green: 0.40, blue: 0.0))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(present == total ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1))
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.manrope(12, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Divider().opacity(0.4)
                    
                    HStack {
                        Button(action: { manager.openFolder(path: dipendente.cartellaPath) }) {
                            Label("Fascicolo Personale", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: { showingConsegnaDPISheet = true }) {
                            Label("Registro DPI (\(dipendente.registroDPI.count))", systemImage: "shield.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: { showingFormazioneSheet = true }) {
                            Label("Attestati Sicurezza (\(dipendente.corsiFormazione.count))", systemImage: "cross.case.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        Button(role: .destructive, action: onDelete) {
                            Label("Elimina Dipendente", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(manager.docsObbligatoriDipendente, id: \.self) { docName in
                            DocDropRowLiquid(
                                title: docName,
                                filePath: dipendente.documenti[docName],
                                expirationDate: Binding(
                                    get: { dipendente.scadenze[docName] ?? Date() },
                                    set: { dipendente.scadenze[docName] = $0; manager.save() }
                                ),
                                targetFolder: dipendente.cartellaPath,
                                onSyncCalendar: {
                                    if let d = dipendente.scadenze[docName] {
                                        manager.aggiungiAGoogleCalendar(
                                            titolo: "Scadenza \(docName): \(dipendente.nome)",
                                            dettagli: "Mansione: \(dipendente.mansione)\nC.F.: \(dipendente.codiceFiscale)",
                                            data: d
                                        )
                                    }
                                },
                                onFileAssigned: { originalPath in
                                    dipendente.documenti[docName] = originalPath
                                    manager.save()
                                },
                                onRemove: {
                                    dipendente.documenti.removeValue(forKey: docName)
                                    manager.save()
                                }
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 5)
        .sheet(isPresented: $showingConsegnaDPISheet) {
            ConsegnaDPISheet(dipendente: $dipendente, manager: manager)
        }
        .sheet(isPresented: $showingFormazioneSheet) {
            GestioneFormazioneSheet(dipendente: $dipendente, manager: manager)
        }
    }
}

// MARK: - Consegna DPI Sheet

struct ConsegnaDPISheet: View {
    @Binding var dipendente: Dipendente
    @ObservedObject var manager: AppDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var tipologiaDPI: String = "Scarpe Antinfortunistiche (S3)"
    @State private var dataConsegna: Date = Date()
    @State private var haScadenza: Bool = true
    @State private var dataScadenzaRinnovo: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
    @State private var noteDPI: String = ""
    
    let dpiPredefiniti = [
        "Scarpe Antinfortunistiche (S3)",
        "Casco di Protezione Cantiere",
        "Imbracatura di Sicurezza Anti-Caduta",
        "Mascherine FFP3 / Esercizio Polveri",
        "Guanti da Lavoro Alta Resistenza",
        "Cuffie / Tappi Anti-Rumore",
        "Occhiali / Visiera Protettiva"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Registro Consegna DPI (D.Lgs. 81/08) - \(dipendente.nome)").font(.headline)
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Registra Nuova Consegna DPI").font(.subheadline).bold()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dispositivo di Protezione (DPI):").font(.caption).bold().foregroundColor(.secondary)
                            Picker("", selection: $tipologiaDPI) {
                                ForEach(dpiPredefiniti, id: \.self) { item in Text(item).tag(item) }
                            }
                            .labelsHidden()
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Data Consegna all'Operaio:").font(.caption).bold().foregroundColor(.secondary)
                                DatePicker("", selection: $dataConsegna, displayedComponents: .date).labelsHidden()
                            }
                            
                            Toggle("Imposta Scadenza / Rinnovo Obbligatorio", isOn: $haScadenza)
                        }
                        
                        if haScadenza {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Data Scadenza / Rinnovo:").font(.caption).bold().foregroundColor(.secondary)
                                DatePicker("", selection: $dataScadenzaRinnovo, displayedComponents: .date).labelsHidden()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Note / Marca / Taglia:").font(.caption).bold().foregroundColor(.secondary)
                            TextField("Marca, modello o taglia...", text: $noteDPI).textFieldStyle(.roundedBorder)
                        }
                        
                        Button(action: {
                            let dpi = ConsegnaDPI(tipologiaDPI: tipologiaDPI, dataConsegna: dataConsegna, dataScadenzaRinnovo: haScadenza ? dataScadenzaRinnovo : nil, note: noteDPI)
                            dipendente.registroDPI.append(dpi)
                            manager.save()
                            noteDPI = ""
                        }) {
                            Label("Registra Consegna DPI", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(14)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
                    .padding(4)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DPI Consegnati all'Operaio:").font(.caption).bold().foregroundColor(.secondary)
                        
                        if dipendente.registroDPI.isEmpty {
                            Text("Nessun DPI consegnato registrato.").font(.caption).foregroundColor(.secondary).padding(.vertical, 10)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(dipendente.registroDPI) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("🦺 \(item.tipologiaDPI)").font(.manrope(12, weight: .bold))
                                            Text("Consegnato il \(item.dataConsegna.formatted(date: .numeric, time: .omitted)) • \(item.note)")
                                                .font(.manrope(10)).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        HStack(spacing: 8) {
                                            if let d = item.dataScadenzaRinnovo {
                                                let diff = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
                                                Text("Rinnovo: \(d.formatted(date: .numeric, time: .omitted)) (\(diff) gg)")
                                                    .font(.manrope(10, weight: .semibold))
                                                    .foregroundColor(diff <= 30 ? .red : .green)
                                            } else {
                                                Text("Nessuna Scadenza").font(.manrope(10)).foregroundColor(.secondary)
                                            }
                                            
                                            Button(action: {
                                                dipendente.registroDPI.removeAll(where: { $0.id == item.id })
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

// MARK: - Gestione Formazione & Sicurezza Sheet (Accordo Stato-Regioni)

struct GestioneFormazioneSheet: View {
    @Binding var dipendente: Dipendente
    @ObservedObject var manager: AppDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var titoloCorso: String = "Formazione Generale e Specifica (Rischio Alto)"
    @State private var enteFormatore: String = "Scuola Edile / Ente Accreditato"
    @State private var dataRilascio: Date = Date()
    @State private var haScadenza: Bool = true
    @State private var dataScadenza: Date = Calendar.current.date(byAdding: .year, value: 5, to: Date())!
    @State private var noteCorso: String = ""
    
    let corsiPredefiniti = [
        "Formazione Generale e Specifica (Rischio Alto)",
        "Primo Soccorso (Gruppo A)",
        "Addetto Antincendio (Livello 2)",
        "Patentino Gru a Torre & Autogru",
        "Patentino Escavatore e MMT",
        "Montaggio/Smontaggio Ponteggi (PIMUS)",
        "Lavori in Quota & Uso DPI 3° Categoria",
        "RLS (Rappresentante Lavoratori Sicurezza)",
        "Preposto di Cantiere"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Attestati Formazione Sicurezza - \(dipendente.nome)").font(.headline)
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Registra Nuovo Attestato / Corso").font(.subheadline).bold()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Corso di Formazione:").font(.caption).bold().foregroundColor(.secondary)
                            Picker("", selection: $titoloCorso) {
                                ForEach(corsiPredefiniti, id: \.self) { item in Text(item).tag(item) }
                            }
                            .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ente Formatore / Scuola Edile:").font(.caption).bold().foregroundColor(.secondary)
                            TextField("es. Scuola Edile / Ente Accreditato", text: $enteFormatore).textFieldStyle(.roundedBorder)
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Data Rilascio Attestato:").font(.caption).bold().foregroundColor(.secondary)
                                DatePicker("", selection: $dataRilascio, displayedComponents: .date).labelsHidden()
                            }
                            
                            Toggle("Imposta Scadenza Periodicita", isOn: $haScadenza)
                        }
                        
                        if haScadenza {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Data Scadenza Attestato:").font(.caption).bold().foregroundColor(.secondary)
                                DatePicker("", selection: $dataScadenza, displayedComponents: .date).labelsHidden()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Note / Numero Protocollo:").font(.caption).bold().foregroundColor(.secondary)
                            TextField("Note o numero protocollo...", text: $noteCorso).textFieldStyle(.roundedBorder)
                        }
                        
                        Button(action: {
                            let corso = AttestatoFormazione(titoloCorso: titoloCorso, enteFormatore: enteFormatore, dataRilascio: dataRilascio, dataScadenza: haScadenza ? dataScadenza : nil, note: noteCorso)
                            dipendente.corsiFormazione.append(corso)
                            manager.save()
                            noteCorso = ""
                        }) {
                            Label("Registra Attestato", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(14)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
                    .padding(4)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Attestati Registrati in Anagrafica:").font(.caption).bold().foregroundColor(.secondary)
                        
                        if dipendente.corsiFormazione.isEmpty {
                            Text("Nessun attestato di formazione registrato.").font(.caption).foregroundColor(.secondary).padding(.vertical, 10)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(dipendente.corsiFormazione) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("🎓 \(item.titoloCorso)").font(.manrope(12, weight: .bold))
                                            Text("Ente: \(item.enteFormatore.isEmpty ? "N.D." : item.enteFormatore) • Rilasciato: \(item.dataRilascio.formatted(date: .numeric, time: .omitted))")
                                                .font(.manrope(10)).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        HStack(spacing: 8) {
                                            if let d = item.dataScadenza {
                                                let diff = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
                                                Text("Scadenza: \(d.formatted(date: .numeric, time: .omitted)) (\(diff) gg)")
                                                    .font(.manrope(10, weight: .semibold))
                                                    .foregroundColor(diff <= 30 ? .red : .green)
                                            } else {
                                                Text("Senza Scadenza").font(.manrope(10)).foregroundColor(.secondary)
                                            }
                                            
                                            Button(action: {
                                                dipendente.corsiFormazione.removeAll(where: { $0.id == item.id })
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