import sqlite3 
from tabulate import tabulate

con = sqlite3.connect("linje5.db")

cursor = con.cursor()

ukedager = {
    "Mandag" : 0,
    "Tirsdag" : 1,
    "Onsdag" : 2,
    "Torsdag" : 3,
    "Fredag" : 4,
    "Lørdag" : 5,
    "Søndag" : 6,
}

jernbanestasjon = input("Vennligst skriv inn din ønskede jernbanestasjon: ")
while True:
    ukedag = input("Vennligst skriv inn ukedag for togreisen: ")
    if ukedag in ukedager:
        break
    else:
        print("Gyldige verdier er: Mandag, Tirsdag, Onsdag, Torsdag, Fredag, Lørdag og Søndag\n")

cursor.execute('SELECT togrute.navn, togruteStasjoner.stasjonNavn, togruteStasjoner.tid, ukedag.dagNavn\
    FROM  togruteStasjoner\
    INNER JOIN rutetabell ON togruteStasjoner.rutetabellID = rutetabell.rutetabellID\
    INNER JOIN togrute ON rutetabell.ruteID = togrute.ruteID\
    INNER JOIN aktiveUkedager ON togrute.ruteID = aktiveUkedager.ruteID\
    INNER JOIN ukedag ON aktiveUkedager.dagID = ukedag.dagID\
    WHERE  togruteStasjoner.stasjonNavn = ?\
    AND aktiveUkedager.dagID = ?', [jernbanestasjon, ukedager[ukedag]])
rows = cursor.fetchall()

if len(rows) > 0:
    print("\n")
    print(tabulate(rows, headers=["Togrute", "Stasjon", "Tid", "Dag" ]))
    print("\n")
else:
    print("\n")
    print("Ingen ruter som tilfredstiller dine behov\nVennligst prøv ett annet tidspunkt, evt. en annen dato")
    print("\n")


con.close()