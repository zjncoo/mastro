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

1. Scarica l'ultimo file installatore **`mastro_installer.dmg`** dalla sezione [Releases](https://github.com/tuonome/mastro/releases).
2. Apri il file `.dmg`.
3. Trascina l'icona **mastro** nella cartella **Applicazioni** del tuo Mac.
4. Avvia l'applicazione e completa la procedura guidata di setup iniziale!

---

## 🛠️ Requisiti di Sistema e Compilazione

- **Sistema Operativo**: macOS 13.0 (Ventura) o superiore (compatibile con Apple Silicon M1/M2/M3/M4 ed Intel).
- **Ambiente di Sviluppo**: Xcode 15+ / Swift 5.9+.

### Compilazione da Sorgente:

```bash
git clone https://github.com/tuonome/mastro.git
cd mastro
open GestoreCantieri.xcodeproj
```

---

## 📄 Licenza

Rilasciato sotto licenza MIT. Consulta il file `LICENSE` per maggiori dettagli.
