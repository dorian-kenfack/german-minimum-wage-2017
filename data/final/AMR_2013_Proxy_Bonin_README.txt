AMR_2013_Proxy_Bonin.csv

Basis: AMR_2013_Proxy.csv. Alle bisherigen Variablen und Werte unverändert.
Ergänzung: mw_luecke aus der vom Nutzer bereitgestellten mlkamrpanel.csv
im Ordner Replikation. Verbindung ausschließlich über den numerischen Schlüssel amr.
257 Regionen, eine Zeile je AMR, keine fehlenden Werte und keine entfernten Regionen.
mw_luecke ist innerhalb jeder AMR über alle Panelzeitpunkte konstant.
Je Region wurde dieser konstante Wert einmal übernommen, nicht zeitlich gemittelt.
Originalskalierung beibehalten, keine Umrechnung in Prozent.

Wichtig: Lohnproxy zum 31.12.2013; mw_luecke ist Bonins bereits für den
2014er Proxy-Abgleich verwendeter Wage Gap. Es ist kein neu berechneter Wage Gap
für 2013. Lohnabgrenzung und Gewichtungsmethode stehen in README_2013.txt.

CSV: UTF-8, Komma als Feldtrenner, Dezimalpunkt.
daten2013 <- read.csv("AMR_2013_Proxy_Bonin.csv", fileEncoding = "UTF-8")
