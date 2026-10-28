# Resident Evil Trainer für macOS

Nativer gemeinsamer Launcher für Resident Evil 2, Resident Evil 3, Resident Evil 4, Resident Evil 7 und Resident Evil Village.
Eigenständiges Projekt aus der unveränderten Vorlage mactrainertemplate.
GPL-3.0-only; die ursprünglichen Overlay-Bausteine stammen aus
[darkuser89/Dead-Island-2-MAS-Steam-Trainer](https://github.com/darkuser89/Dead-Island-2-MAS-Steam-Trainer).

[Aktuelle App herunterladen](https://github.com/darkuser89/RE-Mac-Trainer/releases/latest) ·
[Buildstatus](https://github.com/darkuser89/RE-Mac-Trainer/actions/workflows/macos.yml)

Benötigt Apple Silicon und macOS 14 oder neuer sowie eine der unten genannten
Original-Spielversionen. Das ZIP enthält ausschließlich den Trainer.
ZIP entpacken und `Resident Evil Trainer.app` öffnen. Die App ist ad-hoc signiert,
aber nicht mit einem Apple-Developer-Zertifikat signiert oder notarisiert.
macOS kann deshalb beim ersten Öffnen eine Bestätigung in
Systemeinstellungen → Datenschutz & Sicherheit → Dennoch öffnen verlangen.

## Benutzung

Im Launcher RE2, RE3, RE4, RE7 oder RE8 auswählen und „Spiel mit Trainer starten“ drücken.
Die gespeicherte oder installierte Original-App wird erkannt; „Ändern …“ wählt
bei Bedarf eine andere Installation. Eine bereits laufende Spielinstanz zuerst
regulär beenden. „Zurück zum Spiel“ aktiviert das ausgewählte laufende Spiel.
Bei jedem Spielstart bleiben Overlay und Mini-Anzeige verborgen.
Im Launcher kann „Cheat-Auswahl beim nächsten Start laden“ aktiviert werden.
Schalter und Zahlenwerte werden getrennt für RE2/3/4/7/8 gemerkt; ohne die Option
starten alle Cheats aus. Die Auswahl wird erst nach bestätigtem Laden der Spielfigur
angewandt. Einmalaktionen werden niemals automatisch ausgeführt; ihre Zahlenwerte
bleiben zum manuellen Übernehmen erhalten. F12 löscht auch eine noch wartende
Wiederherstellung. Der Launcher speichert Änderungen aus seiner laufenden Spielsitzung;
er sollte dafür geöffnet bleiben.
Beim Öffnen wird die Maus automatisch für das Trainer-UI freigegeben;
beim Schließen erhält das Spiel die Maus zurück. Im Titelmenü und während des Ladens bleiben
Cheats gesperrt, bis die lokale Spielfigur bestätigt ist.

- ⌘ + ^: Overlay samt Mausbedienung öffnen/schließen; ausgewählte Effekte bleiben aktiv.
- F12: alle laufenden Effekte ausschalten; eigene Werte bei gültigem Besitzer zurückstellen.
- Esc: sichtbares Overlay schließen und Maus zurückgeben; beim Bearbeiten einer Zahl zunächst die Eingabe abbrechen.
- Auf Apple-Tastaturen gegebenenfalls zusätzlich Fn verwenden.
- Zahlenfeld anklicken, Wert eingeben, mit Enter übernehmen. Danach den jeweiligen
  Schalter beziehungsweise GO drücken; die Zahleneingabe allein führt keine Einmalaktion aus.

| Taste | RE2 | RE3 |
| --- | --- | --- |
| F1 | Gesundheitsschutz | Lebenspunkte auf Maximum halten |
| F2 | Vorhandene Reservemunition auffüllen | Reservemunition auffüllen und vorhandene Granaten erhalten |
| F3 | Magazin gefüllt halten | Magazin gefüllt halten |
| F4 | Vorhandene Farbbänder auffüllen | Unverwundbarkeit |
| F5 | Zielfokus beschleunigen | Zielfokus beschleunigen |
| F6 | Rückstoß unterdrücken | Rückstoß unterdrücken |
| F7 | Zeitlupe × 0,1–1 | Zeitlupe × 0,1–1 |
| F8 | Lebende geladene Gegner auf 1 HP | Lebende geladene Gegner auf 1 HP |
| F9 | Rucksack einmalig auf 20 Plätze | Rucksack einmalig auf 20 Plätze |
| F10 | Spielzeit einmalig zurücksetzen | Spielzeit einmalig zurücksetzen |
| F11 | Speicherzähler zurücksetzen | Speicherzähler zurücksetzen |
| ⌥ F1 | Aktiven Countdown einfrieren | Todeszähler zurücksetzen |
| ⌥ F2 | Itemboxzähler zurücksetzen | Itemboxzähler zurücksetzen |
| ⌥ F3 | Heilzähler zurücksetzen | Heilzähler zurücksetzen |
| ⌥ F4 | Schritte zurücksetzen | Alle Records abschließen |
| ⌥ F5 | Haltbarkeit vorhandener intakter Messer | Systemweite Gesamtspielzeit zurücksetzen |
| ⌥ F6 | Lokales Bewegungstempo × 1–3 | Lokales Bewegungstempo × 1–3 |
| ⌥ F7 | Patrouillierenden Tyrant unten halten | Humanoiden Nemesis im Verfolgungsmodus unten halten |
| ⌥ F8 | Geladene Objektmarkierungen | Geladene Objektmarkierungen |
| ⌥ F9 | Vorhandene Holzbretter auffüllen | Shop-Punkte einmalig auf eingestellten Wert setzen |
| ⌥ F10 | Geöffneten Mini-Tresor einmalig lösen | — |

RE2: Den tragbaren Mini-Tresor zuerst bis zum Rätsel mit den acht Tasten öffnen, dann einmal ⌥F10 drücken. Die Aktion verwendet die aktuelle Lösung und Eingabeprüfung; der normale Spielablauf öffnet den Tresor und vergibt dessen Inhalt. Diese Einmalaktion wird beim nächsten Start niemals automatisch wiederholt. Bereits gespeicherte RE2-Auswahlen mit 20 Einträgen bleiben kompatibel.

Ein Schalter erscheint erst nach nativer Rückleseprüfung grün. „Wartet“ bedeutet,
dass aktuell keine passende bestätigte Anbindung verfügbar ist, etwa eine Waffe,
ein Gegenstand oder ein geladener Gegner. Hervorhebungen nutzen native weiße
Objektmarkierungen; sie zeigen bis zu 32 unterschiedliche geladene Interaktionen
in Registrierungsreihenfolge. Zeitlupe und Hervorhebungen pausieren in Spielmenüs.
RE3 erkennt vorhandene Hand-/Blendgranaten anhand deutscher oder englischer
nativer Waffennamen. Andere Sprachen sind für diesen Teil nicht abgedeckt.
Hand-/Blendgranaten gehören zu F2; F3 füllt sie nicht auf.

F12 macht Einmalaktionen nicht rückgängig. Records können Freischaltungen auslösen;
Shop-Punkte und die Gesamtspielzeit betreffen die Systemdaten des Spiels.
Das Spiel kann Laufzeitänderungen beim normalen Speichern übernehmen.
Nemesis betrifft ausschließlich seine humanoide Verfolgungsform; andere Bossformen
werden dabei nicht verändert. Reservemunition, Farbbänder und Bretter erzeugen
keine neuen Gegenstände.

## Profile und Architektur

Die Adapter sind an konkrete arm64-Builds gebunden:

| Spiel | Version | Mach-O-UUID |
| --- | --- | --- |
| RE2 | 1.0.2 | 4C4C44ED-5555-3144-A15E-9285028AFD15 |
| RE3 | 1.0.0 | 4C4C4461-5555-3144-A174-EA43301DB10B |
| RE4 | 1.0.7 | 4C4C44CF-5555-3144-A161-D64EFB82E79F |
| RE7 | 1.0.4 | 4C4C4466-5555-3144-A1F6-0D461A1E2960 |
| Village | 1.1.8 | 4C4C44EB-5555-3144-A1A1-B2C9A3FC8945 |

Bundle-IDs, Signatur-Team und ausführbare Dateien stehen in
`Resources/TrainerConfig.json`. Abweichende Builds werden abgelehnt.
Original-Spiel-Apps und Save-Dateien werden nicht bearbeitet.

Launcher → Runtime → GameBridge → eigener Spieladapter → native Engine.
Der normale Start lädt die Bibliothek über NSWorkspaceOpenConfiguration.
GameThread-Zustellung übernimmt einen bereits schreibbaren LateUpdate-Datenzeiger
atomar. Es gibt keine Code-Seiten-Patches, Schutzänderungen oder Live-Debugger-Anbindung.
Die Besitzerprüfung verwendet native schwache GameObject-Handles und behält
benötigte verwaltete Payloads nur für die Bindung. Der gemeinsame Ledger schützt
Originalwerte, sich überlagernde Effekte und nachfolgende fremde Änderungen.
RE2, RE3, RE4, RE7 und Village besitzen getrennte Funktionskataloge und native Datenzuordnungen.
RE4 verwendet seine eigene TDB73-Engine-Anbindung.

## Resident Evil 4

Die automatische Mausfreigabe beim Öffnen des Overlays funktioniert auch im
RE4-Pausemenü. ⌘^ öffnet/schließt das Overlay; beim Schließen erhält das Spiel die Maus zurück.
Der Rückstoßschalter betrifft die Zielbewegung der Kamera; Waffenanimationen
laufen weiter.

Der RE4-Katalog enthält die 36 Optionen der Referenz. Alle 36 Optionen besitzen
konkrete native Datenpfade. Tickets und Jetons benötigen einen vorhandenen
Stapel und beachten das native Stapelmaximum. Ein vorhandener Datenpfad
bedeutet nicht, dass jede Spielsituation bereits praktisch geprüft wurde.
Orange bedeutet ausgewählt, aber aktuell ohne bestätigtes Ziel; grün bedeutet
angewandt und nativ zurückgelesen. Der aktuelle Ingame-Prüfstand steht getrennt
im Prüfbericht außerhalb des Quellcodes.

| Taste | RE4-Funktion |
| --- | --- |
| F1 | Natives Unverwundbarkeitsflag |
| F2 | Positive Lebenspunkte auf Maximum halten |
| F3 | Maximale Gesundheit einstellen |
| F4 | Haltbarkeit einer vorhandenen intakten Rüstung |
| F5 | Vorhandene stapelbare Materialien und Wurfgegenstände auffüllen |
| F6 | Vorhandene Reservemunition auffüllen |
| F7 | Magazin der ausgerüsteten Schusswaffe gefüllt halten |
| F8 | Haltbarkeit vorhandener intakter Messer |
| F9 | Relatives globales Spieltempo |
| F10 | Relatives Motion-Tempo des lokalen Spielers, einschließlich Animationen |
| F11 | Relatives Motion-Tempo geladener Gegner |
| ⌥F1 | Positive HP geladener Gegner auf 1 setzen |
| ⌥F2 | Eingehenden Schadensfaktor geladener Gegner skalieren |
| ⌥F3 | Eingehenden Schadensfaktor des lokalen Spielers teilen |
| ⌥F4 | Peseten einmalig auf den eingegebenen Wert setzen |
| ⌥F5 | Neue positive Peseten-Einnahmen multiplizieren |
| ⌥F6 | Spinelle einmalig einstellen |
| ⌥F7 | Vorhandene normale Spezialupgrade-Tickets einstellen |
| ⌥F8 | CP einmalig einstellen |
| ⌥F9 | Registrierte CP-Bonusshopartikel dauerhaft freischalten |
| ⌥F10 | Materialkosten registrierter Rezepte auf 0 setzen |
| ⌥F11 | Kamerarückstoß beim Schießen unterdrücken |
| ⇧F1 | Nativen Zielfokus beschleunigen und Fokusverluste entfernen |
| ⇧F2 | Sichtfeld der lokalen Kamera in Grad einstellen |
| ⇧F3 | Punkte einer aktiven Schießstandrunde halten |
| ⇧F4 | Vorhandene Goldjetons einstellen |
| ⇧F5 | Vorhandene Silberjetons einstellen |
| ⇧F6 | Kampagnen-Speicherzähler einmalig auf 0 setzen |
| ⇧F7 | Kampagnen-Spielzeitzähler einfrieren |
| ⇧F8 | Kampagnen-Spielzeit einmalig um Minuten korrigieren |
| ⌥⇧F4 | Positiven Söldner-Rundentimer halten |
| ⌥⇧F5 | Laufende Söldner-Kombo offen halten |
| ⌥⇧F6 | Mayhem-Leiste außerhalb eines aktiven Kampfrauschs füllen |
| ⌥⇧F1 | Aktiven Kampfrausch halten |
| ⌥⇧F2 | Söldner-Punktestand auf 9999999 halten |
| ⌥⇧F3 | Neue positive Söldner-Punktegewinne multiplizieren |

F5 erzeugt keine Gegenstände und erhält keine bereits verbrauchten Einzelitems.
Rüstung und Messer werden nicht aus einem kaputten Zustand wiederhergestellt.
F12 nimmt Einmalaktionen wie Peseten, Spinelle, CP, Speicher-/Zeitkorrekturen
und Bonusshop-Freischaltungen nicht zurück. Der Punkte-Multiplikator wartet auf
einen echten Punktegewinn; maximale Söldner-Punkte haben dabei Vorrang.
Andere Spielversionen und
sämtliche Waffen-, Gebiets- und Modusvarianten sind nicht vollständig geprüft.

## Resident Evil 7

RE7 besitzt eine eigene Anbindung für den exakten Mac-Build 1.0.4. Die
GameThread-Zustellung wird erst bei einer vollständig geladenen lokalen Spielfigur
installiert und verwendet einen bereits vorhandenen VM-Thread-Kontext.
Native Guid-Handles sowie die aktuelle Komponenten- und Inventarzuordnung
schützen die Besitzer. Die RE7-Anbindung verändert dafür keine verwalteten
Referenzzähler und erzeugt keine temporären Komponentenarrays.

| Taste | RE7-Funktion |
| --- | --- |
| F1 | Positive lokale Gesundheit auf Maximum halten |
| F2 | Vorhandene Munitions- und stapelbare Wurfwaffen auffüllen |
| F3 | Magazin der ausgerüsteten Schusswaffe halten |
| F4 | Vorhandene stapelbare Verbrauchsgegenstände auffüllen |
| F5 | Native Psychostimulanz-Markierungen mit Anzeigefreigabe; pausiert im Spielmenü |
| F6 | Relatives globales Spieltempo |
| F7 | Relative Zeitlupe; hat Vorrang vor F6 |
| F8 | Spielzeit im Hauptspiel einmalig zurücksetzen |
| F9 | Lokale Geh-, Lauf- und Kriechgeschwindigkeiten skalieren |
| F10 | Positive HP geladener Gegner auf 1 setzen |
| ⌥F1 | Schrottbestand einer aktiven Albtraum-Runde setzen |
| ⌥F2 | Nativen Schrottbonus der Albtraum-Endwertung erhöhen; positiver Schrottbestand erforderlich |
| ⌥F3 | Positiven Sauerstoffvorrat in Not a Hero halten |
| ⌥F4 | Native Stoppuhr einer aktiven Geburtstagsrunde anhalten |
| ⌥F5 | „21“: echte Spielerhand mit zwei bis sechs Karten auf 21 ausrichten |

Der 21-Schalter ordnet die Werte des vorhandenen gemeinsamen Decks neu, damit
die tatsächliche Hand 21 ergibt; auch Gegenkarten können dabei neue Werte erhalten.
Alle elf Kartenwerte bleiben eindeutig im Bereich 1–11. Sieben eindeutige Karten
können bereits rechnerisch keine Summe 21 bilden. Trumpfregeln können außerdem
einen anderen Zielwert vorgeben; der Schalter erzwingt weiterhin 21.
Die DLC-Optionen warten auf ihren jeweiligen tatsächlich geladenen Modus.
Stapeloptionen erzeugen keine neuen Gegenstände und beachten das native Maximum.
F8 und die Schrottaktion sind Einmalaktionen; F12 nimmt sie nicht zurück.
Die Optionen besitzen konkrete native Implementierungen; eine verfügbare
Implementierung ist kein vollständiger Ingame-Nachweis. Der bestätigte
Prüfstand wird separat außerhalb des Quellcodes geführt.

## Resident Evil Village

Village verwendet seine eigene TDB71-Anbindung mit nativer GameThread-Zustellung,
vorhandenem VM-Kontext und Guid-Besitzerprüfung. Waffeneffekte benötigen eine
ausgerüstete Waffe aus dem lokalen Inventar. Fehlende Objekte bleiben wartend.

| Taste | Village-Funktion |
| --- | --- |
| F1 | Unverwundbarkeit und unterdrückte Trefferreaktionen |
| F2 | Positive Gesundheit auf das native Maximum halten |
| F3 | Vorhandene Reservemunition auffüllen |
| F4 | Magazin zwischen abgeschlossenen Schüssen auffüllen; Aus stoppt das Auffüllen |
| F5 | Native Schusssperrzeit verkürzen |
| F6 | Native Rückstoßparameter unterdrücken |
| F7 | Vorhandene stapelbare Verbrauchsgegenstände und Ressourcen auffüllen |
| F8 | Materialanforderungen vorhandener Herstellungsrezepte auf null setzen |
| F9 | Relatives globales Spieltempo; pausiert in Spielmenüs |
| F10 | Hohe Angriffsstärke der ausgerüsteten Waffe |
| F11 | Relative Angriffsstärke; F10 hat Vorrang |
| ⌥F1 | Reichweite vorhandener nativer Fernmarkierungen erweitern; pausiert in Menüs |
| ⌥F2 | Gesamtspielzeit einmalig um bis zu eine Stunde verringern |
| ⌥F3 | Zutatenanforderungen vorhandener Gerichte auf null setzen |
| ⌥F4 | Relatives lokales Bewegungstempo; pausiert in Spielmenüs |
| ⌥F5 | Vorhandenen Lei-Bestand einmalig setzen |
| ⌥F6 | Neue positive Lei-Einnahmen multiplizieren |
| ⌥F7 | CP einmalig setzen |
| ⌥F8 | Registrierte Bonusshop-Sperren dauerhaft aufheben; kein Kauf |

Söldner nutzt ⌥F9 (Zeit), ⌥F10 (hohe Punkte), ⌥F11 (Punktefaktor) und
⇧F1 (vorhandenes Zielportal öffnen). Rose nutzt die gemeinsamen Grundlagen;
waffenabhängige Optionen warten auf eine tatsächlich ausgerüstete Waffe.
Die Zeitaktion wählt im Rose-DLC den laufenden PlayingTime-Zeitgeber.
Die Tabelle beschreibt implementierte native Pfade,
keine vollständige Wirkungsbestätigung. Der jeweilige Ingame-Prüfstand steht
außerhalb des Codes im Audit. Stapeloptionen erzeugen keine neuen Gegenstände;
Fernmarkierungen verändern keine Benutzungsreichweite. F12 nimmt Einmalaktionen
und dauerhafte Freischaltungen nicht zurück.

## Bauen

`./script/build_and_run.sh --build-only` erstellt die App und führt die lokalen
Metadaten-, Bridge-, Ledger-, UI- und Hotkey-Regressionstests aus.
`./script/build_and_run.sh run` öffnet anschließend den Launcher.
Der einzige aktuelle Build liegt außerhalb dieses Codeordners in
`../RE2TrainerBuild/Resident Evil Trainer.app`.
Die Bundle-ID bleibt für vorhandene Einstellungen `local.mactrainer.re2`.

`./script/package_release.sh` verpackt den aktuellen geprüften Build außerhalb
des Codes unter `../RE2TrainerBuild/Release/`. Das Skript prüft die Signatur auch
nach dem Entpacken, startet den Launcher-Selbsttest und erstellt SHA256-Prüfsummen
sowie `release-info.json` mit Version, Buildnummer und Quellcommit.
`MT_TRAINER_BUILD_DIR` wählt bei Bedarf einen anderen externen Buildordner.

## Automatischer Build und Download

GitHub Actions baut und prüft jeden Push auf `main` auf einem nativen arm64-Mac.
Nach erfolgreicher Verpackungsprüfung veröffentlicht es die aktuelle App im
[Latest-Release](https://github.com/darkuser89/RE-Mac-Trainer/releases/latest).
Dieses eine Release samt `latest`-Tag wird auf den erfolgreich gebauten Quellstand
aktualisiert; `main` wird dabei niemals überschrieben. Ein überholter wartender
Workflow darf keinen neueren `main`-Stand ersetzen. Pull Requests bauen und testen
ohne Veröffentlichungsrechte. Der Workflow kann auch auf `main` manuell gestartet werden.

Der Workflow benötigt keine eigenen Zugangsdaten oder Apple-Zertifikate;
für das Release verwendet er den kurzlebigen GitHub-Actions-Token mit
`contents: write` ausschließlich im Veröffentlichungsjob. Downloads enthalten
ZIP, `SHA256SUMS` und Buildinformationen. Temporäre Actions-Artefakte bleiben drei
Tage verfügbar. Spielstarts und echte Ingame-Funktionstests finden auf GitHub
nicht statt; lokale Fixture-Tests ersetzen diese Prüfung nicht.

Diagnoseeinstiege sind ausschließlich CLI-Optionen und keine Launcher-Knöpfe.
`--re3-engine-check` startet ohne Cheats mit GameThread-Metadatenprotokollierung;
`--re3-probe` lädt nur die lesende Metadatenprobe. Keine dieser Diagnosen ersetzt
einen ausgeführten Ingame-Test. Ausgeführte Prüfungen und offene Spieltests stehen
getrennt im Audit-Ordner `../RE2-Pruefung`.


## Direkte lokale Steuerung für RE2/3/4/7/8

Ab Build75 stellt jedes über den Launcher gestartete Spiel eine sitzungsgebundene lokale Steuerung bereit. Das Overlay kann dabei verborgen bleiben. Die CLI im App-Bundle startet kein Spiel und öffnet kein Fenster:

```sh
MacTrainer --control list
MacTrainer --control re2 '{"action":"state"}'
MacTrainer --control re2 '{"action":"set","feature":16,"wanted":false}'
MacTrainer --control re2 '{"action":"value","feature":16,"value":2}'
MacTrainer --control re2 '{"action":"set","feature":16,"wanted":true}'
```

`MacTrainer` liegt unter `Resident Evil Trainer.app/Contents/MacOS/`. Ziel kann `re2`, `re3`, `re4`, `re7`, `re8`, eine exakte Profil-ID oder eine Spiel-PID sein. Bei mehreren passenden Sitzungen muss die PID gewählt werden. `state` liefert den frisch auf dem Spielthread gelesenen Status einschließlich Titel/Hotkey/ID, gewollter Auswahl, tatsächlicher Anwendung, Rücklesenotiz, Zahlenwert und Kontext. RE2 liefert zusätzlich gebundene native Tempowerte. `overlayVisible` und `mouseActive` melden den tatsächlichen Overlayzustand.

`set` setzt ausdrücklich an oder aus und ist wiederholbar, ohne umzuschalten. `value` bearbeitet nur gültige Zahlenwerte. Eine Einmalaktion benötigt ausdrücklich `{"action":"run","feature":ID}`; sie wird weder beim Lesen noch beim Wiederherstellen einer Auswahl ausgeführt. `disable_all` entspricht F12. IDs immer aus dem aktuellen `state` lesen; gleiche IDs können je nach Spiel verschiedene Funktionen bezeichnen. `ok` bestätigt die Befehlsbearbeitung; Wirkung über `active`, `note`, `message` und vorhandene native `diagnostics` prüfen. Bei einer ausgebliebenen Antwort Einmalaktionen nicht automatisch wiederholen.

Die Übertragung läuft über lokale macOS-Benachrichtigungen mit Profil-, PID-, Sitzungs- und Anfragekennung. Es gibt keinen Netzwerk-Listener und keine frei aufrufbaren Speicher-/Native-Befehle. Doppelte aktuelle Anfragekennungen werden nicht erneut ausgeführt. Mutationen bleiben an gültigen Einzelspieler-Kontext, Eigentümer und Spielthread gebunden; abgelaufene und kontextfremde Befehle werden verworfen. ⌘^ sowie die automatische Mausfreigabe bleiben unverändert.
