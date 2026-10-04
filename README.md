# mastro 🏗️
> **Il Software Nativo per macOS per Cantieri, Mezzi e Scadenze**

![macOS Native App](https://img.shields.io/badge/Platform-macOS%2013%2B-blue?style=for-the-badge&logo=apple)
![SwiftUI](https://img.shields.io/badge/Built%20With-SwiftUI%20%2F%20AppKit-orange?style=for-the-badge&logo=swift)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**mastro** è un'applicazione desktop nativa per macOS progettata per imprese edili, geometri e direttori di cantiere. Consente di gestire cantieri, parco mezzi, scadenze di sicurezza DPI/revisioni, lavoratori e subappaltatori con salvataggio locale dei dati ed esportazione di report PDF con logo aziendale.

---

## 🌟 Funzionalità di mastro

- 🏗️ **Gestione Cantieri**: Scheda cantiere con stato (In Corso, In Attesa, Terminato), committente, valore complessivo, progresso %, date inizio/fine, note ed allegati PDF.
- 🚛 **Registro Mezzi & Scadenze**: Gestione parco mezzi con targa, modello, anno, documenti ed avvisi visivi di scadenza per revisioni, assicurazioni, tagliandi e DPI.
- 👷 **Anagrafica Dipendenti**: Registro lavoratori con mansioni, contatti (telefono, email), note e scadenze attestati di formazione/sicurezza.
- 🤝 **Registro Subappaltatori**: Schede imprese esterne con ragione sociale, referente, specializzazione e contratti allegati.
- 🔔 **Notifiche Native macOS**: Integrazione nativa con `UNUserNotificationCenter` che avvisa automaticamente 30, 15 e 3 giorni prima delle scadenze nel Centro Notifiche del Mac.
- 📄 **Esportazione Report PDF**: Generazione automatica di un report PDF riassuntivo del cantiere con l'intestazione del **Logo Aziendale**.
- 📁 **Archivio Desktop Automatico**: Creazione e gestione automatica della cartella `~/Desktop/mastro_archivio/` con sottocartelle ordinate.
- 🏢 **Setup Guidato Iniziale**: Configurazione della Ragione Sociale, del Logo aziendale o icona predefinita con il quadrato nero su bianco.

---

## 🚀 Download & Installazione

1. Scarica l'ultimo file installatore **`mastro_installer.dmg`** dalla sezione [Releases](https://github.com/zjncoo/mastro/releases).
2. Apri il file `.dmg`.
3. Trascina l'icona **mastro** nella cartella **Applicazioni** del tuo Mac.
4. Avvia l'applicazione e completa la procedura guidata di setup iniziale!

---

## 🛠️ Requisiti di Sistema e Compilazione

- **Sistema Operativo**: macOS 13.0 (Ventura) o superiore (compatibile con Apple Silicon M1/M2/M3/M4 ed Intel).
- **Ambiente di Sviluppo**: Xcode 15+ / Swift 5.9+.

### Compilazione da Sorgente:

```bash
git clone https://github.com/zjncoo/mastro.git
cd mastro
open mastro.xcodeproj
```

---

## ⚠️ Avvertenza Legale, Sicurezza & Esclusione di Responsabilità

- **Natura del Software:** `mastro` è uno strumento gestionale ed organizzativo per uso personale o aziendale interno. **Non sostituisce in alcun modo gli obblighi legali, di sorveglianza e di conformità imposti dalla normativa vigente in materia di salute e sicurezza sul lavoro (incluso il D.Lgs. 81/2008 e s.m.i. — Testo Unico sulla Sicurezza).**
- **Responsabilità dell'Utente:** L'imprenditore, il direttore tecnico, il coordinatore per la sicurezza e l'utente rimangono gli unici ed esclusivi responsabili della verifica effettiva delle scadenze dei mezzi, dei collaudi, delle revisioni obbligatorie del Codice della Strada, dell'idoneità sanitaria dei lavoratori e della validità degli attestati formativi e dei DPI.
- **Esclusione di Garanzie ("AS IS"):** IL SOFTWARE VIENE FORNITO "COSÌ COM'È" ("AS IS"), SENZA ALCUNA GARANZIA ESPRESSA O IMPLICITA. IN NESSUN CASO GLI AUTORI O IL TITOLARE DEL COPYRIGHT POTRANNO ESSERE RITENUTI RESPONSABILI PER DANNI DIRETTI, INDIRETTI, INCIDENTALI O CONSEQUENZIALI (INCLUSE SANZIONI AMMINISTRATIVE, INFORTUNI SUL LAVORO O FERMO CANTIERE) DERIVANTI DALL'USO DEL PROGRAMMA.

---

## 📄 Licenza & Note Legali

- **Licenza Software:** Rilasciato sotto licenza [MIT](LICENSE). Copyright © 2026 [zinco.cc](https://zinco.cc).
- **Marchi Registrati:** Apple, macOS, SwiftUI e AppKit sono marchi registrati di Apple Inc. L'uso di tali denominazioni è a mero scopo descrittivo e di compatibilità tecnica (*Nominative Fair Use*).

Designed & developed by [zinco.cc](https://zinco.cc).
