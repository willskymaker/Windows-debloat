# windows-debloat

Una raccolta di script PowerShell e batch per ripulire Windows 11 in ambienti di lavoro tecnici: CAD, stampa 3D, strumenti di ingegneria.

## Script

| Script | Tipo | Funzione |
|---|---|---|
| `debloat-windows.ps1` | PowerShell | Rimuove bloatware, disabilita telemetria, blocca reinstallazione silenziosa |
| `rendering-optimizer.bat` | Batch | Ottimizza il sistema prima di una sessione di rendering con slicer 3D |
| `rendering-restore.bat` | Batch | Ripristina le impostazioni di sessione al termine del rendering |

---

## debloat-windows.ps1

### Funzionalità

- Rimuove app Microsoft e OEM preinstallate e inutilizzate
- Disabilita telemetria e raccolta dati diagnostici
- Rimuove Bing dalla ricerca del menu Start
- Disabilita Copilot e Widget
- Blocca la reinstallazione silenziosa delle app rimosse dopo gli aggiornamenti Windows
- Abilita la disinstallazione ufficiale di Edge tramite la policy DMA (Digital Markets Act)
- Crea un Punto di Ripristino prima di qualsiasi modifica

### Cosa viene preservato

| Componente | Motivo |
|---|---|
| Windows Defender | Sicurezza |
| Windows Update | Aggiornamenti di sicurezza |
| Esplora file | Shell di sistema |
| Microsoft Photos | Visualizzatore immagini leggero |
| Blocco note | Usato da alcuni installer CAD e driver |
| Orologio / Sveglie | Utilità di sistema |
| Strumento di cattura | Richiesto dalla scorciatoia Win+Shift+S |
| Assistente vocale / Lente di ingrandimento | Accessibilità |
| Windows Media Player (legacy) | Alcuni driver audio dipendono da esso |
| Edge WebView2 Runtime | Motore condiviso usato da molte app di terze parti |
| DirectX | Richiesto per il rendering 3D |
| .NET Runtime | Richiesto dalla maggior parte delle app moderne |
| Visual C++ Redistributables | Richiesto dalla maggior parte dei software di terze parti |

### Cosa viene rimosso

| Categoria | App |
|---|---|
| Media (Store) | Groove Music, Film e TV, Lettore multimediale (Store) |
| Produttività | Paint, Paint 3D, Visualizzatore 3D, Sticky Notes, To Do, Calcolatrice |
| Comunicazione | Skype, Microsoft Teams, Mail e Calendario, Outlook (Store) |
| Cloud | OneDrive |
| Gaming | Xbox App, Xbox Game Bar, Xbox Identity Provider, Gaming App |
| Microsoft consumer | Cortana, Bing News/Meteo/Finanza/Sport, Mappe, Solitario, Hub di Feedback, Suggerimenti, Realtà mista, Collegamento a telefono, Power Automate, Clipchamp, Assistenza rapida, Registratore |
| AI / UI | Copilot, Widget |
| OEM / terze parti | Candy Crush, Spotify, Disney+, Netflix, Amazon Video, Facebook, Twitter, TikTok, WhatsApp (se preinstallati) |

### Requisiti

- Windows 11 (testato su 22H2, 23H2, 24H2)
- PowerShell 5.1 o successivo
- Privilegi di amministratore

### Utilizzo

**Opzione 1 — Tasto destro**

Tasto destro su `debloat-windows.ps1` → **Esegui con PowerShell**

**Opzione 2 — Bypass della policy di esecuzione per la sessione corrente**

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\debloat-windows.ps1
```

### Rimozione di Edge

Lo script applica la Group Policy di EdgeUpdate che abilita l'opzione di disinstallazione ufficiale di Microsoft Edge sui dispositivi della regione SEE (conformità al Digital Markets Act).

Dopo il riavvio, completare la rimozione manualmente:

> **Impostazioni → App → App installate → Microsoft Edge → ⋯ → Disinstalla**

> ⚠️ **Non rimuovere** **Microsoft Edge WebView2 Runtime**. È un motore browser condiviso usato internamente da molte applicazioni di terze parti ed è indipendente dal browser Edge.

### Ripristino delle modifiche

Un Punto di Ripristino viene creato automaticamente all'avvio dello script.

Per ripristinare:

```
Win + R → sysdm.cpl → Protezione sistema → Ripristino configurazione di sistema
```

Le app rimosse tramite `Remove-AppxPackage` possono generalmente essere reinstallate dal Microsoft Store.

---

## rendering-optimizer.bat / rendering-restore.bat

Script complementari per sessioni di rendering con slicer 3D su sistemi **senza GPU dedicata**.

Sui sistemi con GPU integrata (iGPU), CPU e GPU condividono la stessa RAM di sistema. Il piano energetico predefinito di Windows riduce le prestazioni di entrambe, e il timeout GPU predefinito di 2 secondi causa spesso il reset del driver durante sessioni di rendering pesanti con slicer come BambuStudio o Chitubox.

### Cosa fa rendering-optimizer.bat

| Passo | Azione | Persistente |
|---|---|---|
| 1 | Attiva il piano energetico Prestazioni Elevate | Solo sessione |
| 2 | Porta il timeout TDR della GPU a 60 secondi | Sì (richiede riavvio al primo utilizzo) |
| 3 | Libera RAM (aumenta la memoria disponibile alla iGPU) | Solo sessione |
| 4 | Sospende Windows Search e SysMain | Solo sessione |
| 5 | Avvia lo slicer selezionato con priorità Alta | — |

### Cosa fa rendering-restore.bat

- Ripristina il piano energetico Bilanciato
- Riavvia solo i servizi che erano attivi prima dell'optimizer
- Lascia il timeout TDR a 60 secondi (impostazione sicura e conveniente da mantenere)

> Per ripristinare manualmente il timeout TDR al valore predefinito di Windows:
> ```
> reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDelay /t REG_DWORD /d 2 /f
> ```

### Utilizzo

1. Prima di iniziare una sessione di rendering, eseguire `rendering-optimizer.bat` come Amministratore
2. Selezionare lo slicer da avviare (BambuStudio, Chitubox, entrambi, o nessuno)
3. Al termine, eseguire `rendering-restore.bat` come Amministratore

> ⚠️ Modificare i percorsi di installazione all'interno di `rendering-optimizer.bat` se lo slicer è installato in una posizione non predefinita.

### Requisiti

- Windows 10 / 11
- Privilegi di amministratore
- Slicer supportati: BambuStudio, Chitubox (percorsi modificabili nello script)

---

## Disclaimer

Questi script modificano le impostazioni di sistema e rimuovono applicazioni integrate. Sono forniti così come sono, senza alcuna garanzia. Leggere sempre gli script prima di eseguirli e assicurarsi di disporre di un backup o un punto di ripristino.

La rimozione dei componenti dall'elenco preservato in `debloat-windows.ps1` non è raccomandata e potrebbe compromettere la stabilità del sistema o la compatibilità con software di terze parti.

## Licenza

GPL-3.0 — vedere [LICENSE](LICENSE)
