from calendar import weekday
import sqlite3 
from datetime import date
from tabulate import tabulate
import re


con = sqlite3.connect("linje5.db")

cursor = con.cursor()

datoPattern = r"^\d{4}-\d{2}-\d{2}$" #regex for dato
tidPattern = r"^\d{2}:\d{2}$" #regex for tid
ukedager = {
    "Mandag" : 0,
    "Tirsdag" : 1,
    "Onsdag" : 2,
    "Torsdag" : 3,
    "Fredag" : 4,
    "Lørdag" : 5,
    "Søndag" : 6,
}

startstasjon = input("Vennligst skriv inn din ønskede startstasjon: ")
endestasjon = input("Vennligst skriv inn din ønskede endestasjon: ")
while True:
    dato = input("Vennligst skriv inn dato for starten av reisen (ÅÅÅÅ-MM-DD): ")
    result = re.match(datoPattern, dato)
    if result:
        dag = date(int(dato[:4]),int(dato[5:7]),int(dato[8:])).weekday()
        nesteDag = dag + 1
        if (nesteDag > 6):
            nesteDag = 0
        break

while True:
    tid = input("Vennligst skriv inn tid for starten av reisen (HH:MM): ")
    result = re.match(tidPattern, tid)
    if result:
        break


cursor.execute('SELECT sub.tid, stasjonNavn, togrute.navn, ukedag.dagNavn\
    FROM (\
    SELECT togruteStasjoner.rutetabellID, count(togruteStasjoner.rutetabellID) AS antall, togruteStasjoner.stasjonNavn, togruteStasjoner.stasjonNr, togruteStasjoner.tid\
    FROM togruteStasjoner\
    WHERE togruteStasjoner.stasjonNavn = ? OR\
    togruteStasjoner.stasjonNavn = ?\
    GROUP BY togruteStasjoner.rutetabellID\
    HAVING antall > 1 AND togruteStasjoner.stasjonNavn = ?) AS sub,  rutetabell, togrute, aktiveUkedager, ukedag\
    WHERE sub.rutetabellID = rutetabell.rutetabellID\
    AND sub.tid BETWEEN ? AND "23:59"\
    AND rutetabell.ruteID = togrute.ruteID\
    AND aktiveUkedager.ruteID = togrute.ruteID\
    AND (aktiveUkedager.dagID = ? OR aktiveUkedager.dagID = ?)\
    AND aktiveUkedager.dagID = ukedag.dagID\
    ORDER BY sub.tid', [startstasjon, endestasjon, startstasjon, tid, dag, nesteDag])

rows = cursor.fetchall()

if len(rows) > 0:
    print("\n")
    print(tabulate(rows, headers= ["Tid","Stasjon","Togrute","Ukedag"]))
    print("\n")
else:
    print("\n")
    print("Ingen ruter som tilfredstiller dine behov\nVennligst prøv ett annet tidspunkt, evt. en annen dato")
    print("\n")


con.close()

