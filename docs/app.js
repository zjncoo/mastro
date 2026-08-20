/**
 * mastro Studio — Motion Primitives & Interactive Canvas Script
 */

document.addEventListener('DOMContentLoaded', () => {

    // 1. Motion Primitives Scroll Observer (Stagger Reveal)
    const revealElements = document.querySelectorAll('.motion-reveal');

    const observerOptions = {
        root: null,
        rootMargin: '0px 0px -50px 0px',
        threshold: 0.15
    };

    const revealObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                // Motion stagger delay based on index
                setTimeout(() => {
                    entry.target.classList.add('visible');
                }, index * 60);
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    revealElements.forEach(el => revealObserver.observe(el));


    // 2. Interactive macOS App Window Tab Switcher
    const navItems = document.querySelectorAll('.app-nav li');
    const tabTitle = document.getElementById('tab-title');
    const tabSub = document.getElementById('tab-sub');
    const tabContent = document.getElementById('tab-content');

    const tabData = {
        cantieri: {
            title: "Gestione Cantieri in Corso",
            sub: "Panoramica dello stato di avanzamento e dei mezzi assegnati",
            html: `
                <div class="app-card">
                    <div class="app-card-top">
                        <span class="badge-status status-active">🟢 In Corso</span>
                        <span class="card-date">Scadenza: 15/10/2026</span>
                    </div>
                    <h4>Residenza Il Parco</h4>
                    <p class="card-client">Cliente: Rossi Costruzioni Srl</p>
                    
                    <div class="meter-wrap">
                        <div class="meter-text">Avanzamento Lavori: 65%</div>
                        <div class="meter-track"><div class="meter-fill" style="width: 65%;"></div></div>
                    </div>

                    <div class="card-tags">
                        <span class="tag-item">🚚 3 Mezzi Assegnati</span>
                        <span class="tag-item">📄 Genera Report PDF</span>
                    </div>
                </div>

                <div class="app-card warning-border">
                    <div class="app-card-top">
                        <span class="badge-status status-warn">⚠️ Scadenza Imminente</span>
                        <span class="card-date">Scadenza: 28/08/2026</span>
                    </div>
                    <h4>Ristrutturazione Villa Flora</h4>
                    <p class="card-client">Cliente: Immobiliare Nord S.p.A.</p>
                    
                    <div class="meter-wrap">
                        <div class="meter-text">Avanzamento Lavori: 88%</div>
                        <div class="meter-track"><div class="meter-fill warn" style="width: 88%;"></div></div>
                    </div>

                    <div class="card-tags">
                        <span class="tag-item alert-tag">⚠️ Revisione DPI tra 5 giorni</span>
                        <span class="tag-item">🚚 2 Mezzi</span>
                    </div>
                </div>
            `
        },
        mezzi: {
            title: "Registro Parco Mezzi & Scadenze DPI",
            sub: "Monitoraggio scadenze revisioni ministeriali, assicurazioni e tagliandi",
            html: `
                <div class="app-card">
                    <div class="app-card-top">
                        <span class="badge-status status-active">🟢 Regolare</span>
                        <span class="card-date">Targa: EV 892 AB</span>
                    </div>
                    <h4>Autocarro Iveco Daily 35C</h4>
                    <p class="card-client">Anno: 2022 • Tagliando ok</p>
                    <div class="card-tags">
                        <span class="tag-item">Revisione: 12/11/2026</span>
                        <span class="tag-item">DPI Operatore: OK</span>
                    </div>
                </div>

                <div class="app-card warning-border">
                    <div class="app-card-top">
                        <span class="badge-status status-warn">⚠️ In Scadenza</span>
                        <span class="card-date">Targa: GB 410 FK</span>
                    </div>
                    <h4>Escavatore Caterpillar 320</h4>
                    <p class="card-client">Assegnato a: Residenza Il Parco</p>
                    <div class="card-tags">
                        <span class="tag-item alert-tag">⚠️ Assicurazione tra 12 giorni</span>
                    </div>
                </div>
            `
        },
        dipendenti: {
            title: "Anagrafica Dipendenti & Formazione",
            sub: "Registro lavoratori e tracciamento scadenze attestati di sicurezza",
            html: `
                <div class="app-card">
                    <div class="app-card-top">
                        <span class="badge-status status-active">🟢 Attivo</span>
                        <span class="card-date">Mansione: Capocantiere</span>
                    </div>
                    <h4>Marco Benetti</h4>
                    <p class="card-client">Tel: 339 1234567 • marco@ediliziarnod.it</p>
                    <div class="card-tags">
                        <span class="tag-item">Attestato Sicurezza: Valido</span>
                    </div>
                </div>

                <div class="app-card">
                    <div class="app-card-top">
                        <span class="badge-status status-active">🟢 Attivo</span>
                        <span class="card-date">Mansione: Operatore Macchine</span>
                    </div>
                    <h4>Luca Fumagalli</h4>
                    <p class="card-client">Tel: 340 7654321 • luca@ediliziarnod.it</p>
                    <div class="card-tags">
                        <span class="tag-item">Patentino Escavatore: OK</span>
                    </div>
                </div>
            `
        },
        subappalti: {
            title: "Registro Subappaltatori Esterni",
            sub: "Elenco imprese esterne, contatti e contratti per cantiere",
            html: `
                <div class="app-card">
                    <div class="app-card-top">
                        <span class="badge-status status-active">🟢 Contratto Attivo</span>
                        <span class="card-date">Spec: Impianti Elettrici</span>
                    </div>
                    <h4>ElettroEdile S.n.c.</h4>
                    <p class="card-client">Referente: Ing. Roberto Serra</p>
                    <div class="card-tags">
                        <span class="tag-item">Cantiere: Residenza Il Parco</span>
                    </div>
                </div>
            `
        },
        notifiche: {
            title: "Centro Notifiche Native macOS",
            sub: "Alert programmati automatici a 30, 15 e 3 giorni prima",
            html: `
                <div class="app-card">
                    <div class="app-card-top">
                        <span class="badge-status status-active">🔔 UNUserNotificationCenter</span>
                    </div>
                    <h4>Notifiche di Sistema Attive</h4>
                    <p class="card-client">Ricevi avvisi automatici con banner e suono sul Mac.</p>
                    <div class="card-tags">
                        <span class="tag-item">Banner & Suono Nativo</span>
                    </div>
                </div>
            `
        },
        settings: {
            title: "Impostazioni App & Setup Azienda",
            sub: "Personalizzazione Ragione Sociale, Logo Aziendale e Cartella Desktop",
            html: `
                <div class="app-card">
                    <div class="app-card-top">
                        <span class="badge-status status-active">⚙️ Configurato</span>
                    </div>
                    <h4>Edilizia Modern Srl</h4>
                    <p class="card-client">Cartella: ~/Desktop/mastro_archivio/</p>
                    <div class="card-tags">
                        <span class="tag-item">Logo: Caricato</span>
                        <span class="tag-item">Icona Dock: Quadrato Nero/Bianco 🔲</span>
                    </div>
                </div>
            `
        }
    };

    navItems.forEach(item => {
        item.addEventListener('click', () => {
            navItems.forEach(i => i.classList.remove('active'));
            item.classList.add('active');

            const tabKey = item.getAttribute('data-tab');
            const data = tabData[tabKey];

            if (data && tabTitle && tabSub && tabContent) {
                // Smooth transition
                tabContent.style.opacity = '0';
                tabContent.style.transform = 'translateY(10px)';

                setTimeout(() => {
                    tabTitle.textContent = data.title;
                    tabSub.textContent = data.sub;
                    tabContent.innerHTML = data.html;
                    tabContent.style.opacity = '1';
                    tabContent.style.transform = 'translateY(0)';
                }, 150);
            }
        });
    });

});
