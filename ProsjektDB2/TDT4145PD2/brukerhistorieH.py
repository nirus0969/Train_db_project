from calendar import weekday
import sqlite3 
from datetime import datetime
from tabulate import tabulate
import re
import sys


con = sqlite3.connect("linje5.db")

cursor = con.cursor()
phonePattern = r'^\+47\d{8}$'

while True:
    kundeMobil = input("Vennligst skriv inn ditt mobilnummer (+47XXXXXXXX): ")
    result = re.match(phonePattern, kundeMobil)
    if result:
        break
    print("Ikke riktig format for mobilnummer")


cursor.execute("SELECT * FROM kunde WHERE kunde.mobilnummer = ?", [kundeMobil])
rows = cursor.fetchall()


if rows:
    print("\n")
    print(tabulate(rows, headers=["Kundenummer", "Fornavn", "Etternavn", "Epost", "Mobilnummer" ]))
    print("\n")
    kundenummer = rows[0][0]
else:
    print("\n")
    sys.exit("Du er ikke registrert i kunderegisteret")


""" Ville brukt denne, men siden sensor skal kunne få opp bestilte ruter også etter 04.04.23, velger jeg å bruke 
en statisk dato istedenfor. Dette gjør at man får opp alle billetter etter den statiske datoen, istedenfor å ta
utgangspunkt i datoen som man kjører programmet på."""
#dato = datetime.today().strftime('%Y-%m-%d')  
dato = '2023-03-21'


cursor.execute('SELECT sub.navn, sub.setenummer, sub.vognummer, sub.A, sub.tid, sub.B, togruteStasjoner.tid, sub.dato, sub.dager\
    FROM\
    (SELECT togrute.navn, seteBillett.setenummer, togvogn.vognummer, seteBillett.stasjonA AS A, seteBillett.stasjonB AS B, rutetabell.rutetabellID AS ID, togruteStasjoner.tid, togruteforekomst.dato, (CAST( julianday(togruteforekomst.dato) - julianday(?)  AS INTEGER)) AS dager\
    FROM kunde\
    INNER JOIN kundeordre ON kunde.kundenummer = kundeordre.kundenummer\
    INNER JOIN seteBillett ON seteBillett.ordreID = kundeordre.ordreID\
    INNER JOIN togvogn ON togvogn.togvognID = seteBillett.togvognID\
    INNER JOIN togruteforekomst ON togruteforekomst.togruteforekomstID = kundeordre.togruteforekomstID\
    INNER JOIN rutetabell ON rutetabell.ruteID = togruteforekomst.ruteID\
    INNER JOIN togruteStasjoner ON rutetabell.rutetabellID = togruteStasjoner.rutetabellID\
    INNER JOIN togrute ON togruteforekomst.ruteID = togrute.ruteID\
    WHERE togruteStasjoner.stasjonNavn = A\
    AND togruteStasjoner.rutetabellID = ID\
    AND kunde.kundenummer = ?\
    AND dager >= 0\
    ) AS sub, togruteStasjoner\
    WHERE togruteStasjoner.rutetabellID = sub.ID\
    AND togruteStasjoner.stasjonNavn = sub.B', [dato, kundenummer])

rows = cursor.fetchall()
if len(rows) > 0:
    print("\n")
    print(tabulate(rows, headers= ["Togrute", "Setenummer", "Vognummer", "Start stasjon", "Avgangstid", "Ende stasjon", "Ankomsttid", "Dato avreise", "Dager til avreise"]))
    print("\n")
else:
    print("\nDu har ingen reservasjoner for seter på en togreise i nærmeste fremtid\n")

cursor.execute('SELECT sub.navn, sub.sengnummer, sub.vognummer, sub.A, sub.tid, sub.B, togruteStasjoner.tid, sub.dato, sub.dager\
    FROM\
    (SELECT togrute.navn, sengBillett.sengnummer, togvogn.vognummer, sengBillett.stasjonA AS A, sengBillett.stasjonB AS B, rutetabell.rutetabellID AS ID, togruteStasjoner.tid, togruteforekomst.dato, (CAST( julianday(togruteforekomst.dato) - julianday(?)  AS INTEGER)) AS dager\
    FROM kunde\
    INNER JOIN kundeordre ON kunde.kundenummer = kundeordre.kundenummer\
    INNER JOIN sengBillett ON sengBillett.ordreID = kundeordre.ordreID\
    INNER JOIN togvogn ON togvogn.togvognID = sengBillett.togvognID\
    INNER JOIN togruteforekomst ON togruteforekomst.togruteforekomstID = kundeordre.togruteforekomstID\
    INNER JOIN rutetabell ON rutetabell.ruteID = togruteforekomst.ruteID\
    INNER JOIN togruteStasjoner ON rutetabell.rutetabellID = togruteStasjoner.rutetabellID\
    INNER JOIN togrute ON togruteforekomst.ruteID = togrute.ruteID\
    WHERE togruteStasjoner.stasjonNavn = A\
    AND togruteStasjoner.rutetabellID = ID\
    AND kunde.kundenummer = ?\
    AND dager >= 0\
    AND sengBillett.solgt = 1\
    ) AS sub, togruteStasjoner\
    WHERE togruteStasjoner.rutetabellID = sub.ID\
    AND togruteStasjoner.stasjonNavn = sub.B', [dato, kundenummer])

rows = cursor.fetchall()
if len(rows) > 0:
    print("\n")
    print(tabulate(rows, headers= ["Togrute", "Sengnummer", "Vognummer", "Start stasjon", "Avgangstid", "Ende stasjon", "Ankomsttid", "Dato avreise", "Dager til avreise"]))
    print("\n")
else:
    print("\nDu har ingen reservasjoner for senger på en togreise i nærmeste fremtid\n")


con.close()