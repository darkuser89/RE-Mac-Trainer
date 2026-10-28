// SPDX-License-Identifier: GPL-3.0-only
#import "RE7Features.h"
static const RE2FeatureInfo catalog7[RE7FeatureCount]={
 {@"Unbegrenzte Gesundheit",@"F1",@"Füllt die Lebenspunkte deiner lebenden Spielfigur laufend bis zum Maximum auf.",YES,NO,NO,NO,0,0,0,0,122,0},
 {@"Unbegrenzte Munition & Granaten",@"F2",@"Füllt vorhandene Munitions- und Granatenstapel bis zur Höchstmenge auf. Erzeugt keine neuen Gegenstände.",YES,NO,NO,NO,0,0,0,0,120,0},
 {@"Kein Nachladen",@"F3",@"Hält das Magazin der ausgerüsteten Schusswaffe gefüllt, damit du ohne Nachladen weiterschießen kannst.",YES,NO,NO,NO,0,0,0,0,99,0},
 {@"Unbegrenzte Gegenstände",@"F4",@"Füllt vorhandene stapelbare Verbrauchsgegenstände auf. Schlüssel und Questgegenstände sind ausgenommen.",YES,NO,NO,NO,0,0,0,0,118,0},
 {@"Gegenstände aus der Ferne markieren",@"F5",@"Zeigt zusätzliche Gegenstandsmarkierungen wie durch Psychostimulanzien. Pausiert in Menüs; die Aufhebereichweite bleibt gleich.",YES,NO,NO,NO,0,0,0,0,96,0},
 {@"Spielgeschwindigkeit ×",@"F6",@"Beschleunigt das gesamte Spiel: 2 bedeutet doppelte Geschwindigkeit. Zeitlupe hat Vorrang; pausiert in Menüs.",YES,YES,NO,NO,2,1,3,0.25,97,0},
 {@"Zeitlupen-Faktor",@"F7",@"Verlangsamt das gesamte Spiel: 0,5 bedeutet halbe Geschwindigkeit. Pausiert in Menüs.",YES,YES,NO,NO,0.5,0.1,1,0.1,98,0},
 {@"Hauptspielzeit zurücksetzen",@"F8",@"Setzt die laufende Spielzeit im Hauptspiel einmalig auf 0. Gilt nicht für DLC-Zeitgeber. Keine F12-Rücknahme.",YES,NO,YES,NO,0,0,0,0,100,0},
 {@"Geschwindigkeit der Spielfigur ×",@"F9",@"Ändert deine Geh-, Lauf- und Kriechgeschwindigkeit. 2 bedeutet doppelte Geschwindigkeit.",YES,YES,NO,NO,2,0.25,3,0.25,101,0},
 {@"Mit einem Treffer töten",@"F10",@"Senkt die Lebenspunkte lebender Gegner auf 1, damit ein wirksamer Treffer genügt. Skriptphasen und Schadenssperren bleiben bestehen.",YES,NO,NO,NO,0,0,0,0,109,0},
 {@"Albtraum: Schrott bearbeiten",@"⌥ F1",@"Setzt den Schrottbestand einer laufenden Albtraum-Runde einmalig auf den gewählten Wert. Keine F12-Rücknahme.",YES,YES,YES,YES,999999,0,9999999,1000,122,2},
 {@"Albtraum: Endwertung erhöhen",@"⌥ F2",@"Erhöht die Endwertung über den Schrottbonus. Benötigt vorhandenen Schrott; Bestand und Kaufpreise bleiben unverändert.",YES,NO,NO,NO,0,0,0,0,120,2},
 {@"Not a Hero: Unbegrenzter Sauerstoff",@"⌥ F3",@"Verhindert den Verbrauch vorhandenen Sauerstoffs in Not a Hero. Füllt einen bereits leeren Vorrat nicht auf.",YES,NO,NO,NO,0,0,0,0,99,2},
 {@"Jacks 55. Geburtstag: Zeit anhalten",@"⌥ F4",@"Hält die verbleibende Zeit einer laufenden Runde von Jacks 55. Geburtstag an.",YES,NO,NO,NO,0,0,0,0,118,2},
 {@"21: Eigene Hand auf 21 setzen",@"⌥ F5",@"Bringt deine Hand mit zwei bis sechs Karten auf genau 21 und verteilt das übrige gemeinsame Deck passend um. Gilt auch bei geändertem Trumpf-Ziel.",YES,NO,NO,NO,0,0,0,0,96,2},
};
const RE2FeatureInfo *RE7FeatureInfoAt(NSInteger f){return f>=0 && f<RE7FeatureCount ? &catalog7[f] : NULL;}
