from datetime import date
from calendar import weekday
import random
import sqlite3 
from tabulate import tabulate
from datetime import datetime
import sys

#Funksjon som regner ut hvilke sengnummer som blir uledig gitt ett sengnummer som blir bestilt
def sovenummer(sengnummer):
    sengnummer = int(sengnummer)
    if sengnummer%2 == 0:
        return str(sengnummer - 1)
    return str(sengnummer + 1)


con = sqlite3.connect("linje5.db")

cursor = con.cursor()
solgte = [] #Liste som loggfører hvilke sengeplasser som blir solgt for en kundeordre
ikkeLedig = [] #Liste som loggfører hvilke sengeplasser som ikke skal kunne selges videre etter kundeorderen er utført

kundeMobil = input("Vennligst skriv inn ditt mobilnummer: ")

cursor.execute("SELECT * FROM kunde WHERE kunde.mobilnummer = ?", [kundeMobil])
rows = cursor.fetchall()

if rows:
    print("\n")
    print(tabulate(rows, headers=["Kundenummer", "Fornavn", "Etternavn", "Epost", "Mobilnummer" ]))
    print("\n")
    kundenummer = rows[0][0]
else:
    print("\n")
    sys.exit("Du kan dessverre ikke fortsette prossesen av å kjøpe billett,\nfordi du ikke er registrert i kunderegisteret")

startstasjon = input("Vennligst skriv inn din ønskede startstasjon: ")
endestasjon = input("Vennligst skriv inn din ønskede endestasjon: ")
dato = input("Vennligst skriv inn dato for starten av reisen (ÅÅÅÅ-MM-DD): ")

cursor.execute('SELECT sub.tid, stasjonNavn, togrute.navn, togruteforekomst.dato, togruteforekomst.togruteforekomstID\
    FROM (\
    SELECT togruteStasjoner.rutetabellID, count(togruteStasjoner.rutetabellID) AS antall, togruteStasjoner.stasjonNavn, togruteStasjoner.stasjonNr, togruteStasjoner.tid\
    FROM togruteStasjoner\
    WHERE togruteStasjoner.stasjonNavn = ? OR\
    togruteStasjoner.stasjonNavn = ?\
    GROUP BY togruteStasjoner.rutetabellID\
    HAVING antall > 1 AND togruteStasjoner.stasjonNavn = ?) AS sub,  rutetabell, togrute, togruteforekomst\
    WHERE sub.rutetabellID = rutetabell.rutetabellID\
    AND rutetabell.ruteID = togrute.ruteID\
    AND togruteforekomst.dato = ?\
    AND togruteforekomst.ruteID = togrute.ruteID\
    ORDER BY sub.tid', [startstasjon, endestasjon, startstasjon, dato])

rows = cursor.fetchall()
if rows:
    print("\n")
    print(tabulate(rows, headers= ["Tid", "Stasjon", "Togrute", "Dato", "ID"]))
    print("\n")
else:
    print("\n")
    sys.exit("Ingen ruter som oppfyller dine krav,\nvennligst prøv med en annen dato")


forekomstID = input("Vennligst skriv inn ID for ønskede togrute: ")
ordreID = id([kundeMobil, forekomstID])
cursor.execute('INSERT INTO kundeordre VALUES (?, ?, ?, ?, ?)', [ordreID, datetime.today().strftime('%Y-%m-%d'), datetime.today().strftime('%H:%M'), kundenummer, forekomstID])
con.commit()

cursor.execute('SELECT togruteStasjoner.stasjonNr\
    FROM togruteforekomst, rutetabell, togruteStasjoner\
    WHERE togruteforekomst.togruteforekomstID = ?\
    AND togruteforekomst.ruteID = rutetabell.ruteID\
    AND togruteStasjoner.stasjonNavn = ?\
    AND togruteStasjoner.rutetabellID = rutetabell.rutetabellID', [forekomstID, startstasjon])

row = cursor.fetchone()
startstasjonNr = row[0]

cursor.execute('SELECT togruteStasjoner.stasjonNr\
    FROM togruteforekomst, rutetabell, togruteStasjoner\
    WHERE togruteforekomst.togruteforekomstID = ?\
    AND togruteforekomst.ruteID = rutetabell.ruteID\
    AND togruteStasjoner.stasjonNavn = ?\
    AND togruteStasjoner.rutetabellID = rutetabell.rutetabellID', [forekomstID, endestasjon])

row = cursor.fetchone()
endestasjonNr = row[0]

while True:

    plasstype = input("Vennligst skriv inn ønsket plasstype(sete/seng): ")
    if plasstype == 'sete':
        cursor.execute('SELECT togvogn.vognummer, sete.setenummer\
            FROM togrute, vognoppsett, togvogn, sete, togruteforekomst\
            WHERE  togruteforekomst.togruteforekomstID = ?\
            AND togruteforekomst.ruteID = togrute.ruteID\
            AND togrute.ruteID = vognoppsett.ruteID\
            AND togvogn.vognoppsettID = vognoppsett.vognoppsettID\
            AND togvogn.vogntypeID = sete.vogntypeID\
            EXCEPT\
            SELECT sub.vognummer, sub.setenummer\
            FROM(\
            SELECT togvogn.vognummer, seteBillett.setenummer, seteBillett.stasjonA AS A, seteBillett.stasjonB AS B, rutetabell.rutetabellID AS ID\
            FROM seteBillett, togvogn, kundeordre, togruteforekomst, rutetabell\
            WHERE seteBillett.togvognID = togvogn.togvognID\
            AND seteBillett.ordreID = kundeordre.ordreID\
            AND kundeordre.togruteforekomstID = togruteforekomst.togruteforekomstID\
            AND togruteforekomst.togruteforekomstID = ?\
            AND togruteforekomst.ruteID = rutetabell.ruteID\
            AND ((SELECT stasjonNr FROM togruteStasjoner WHERE stasjonNavn = A AND rutetabellID = ID) <= ?\
            AND ((SELECT stasjonNr FROM togruteStasjoner WHERE stasjonNavn = B AND rutetabellID = ID) > ?)\
            OR \
            ((SELECT stasjonNr FROM togruteStasjoner WHERE stasjonNavn = B AND rutetabellID = ID) >= ?\
            AND (SELECT stasjonNr FROM togruteStasjoner WHERE stasjonNavn = A AND rutetabellID = ID) < ?)\
            OR\
            ((SELECT stasjonNr FROM togruteStasjoner WHERE stasjonNavn = A AND rutetabellID = ID)  >  ?\
            AND (SELECT stasjonNr FROM togruteStasjoner WHERE stasjonNavn = B AND rutetabellID = ID)  <  ?))) AS sub', [forekomstID, forekomstID, startstasjonNr, startstasjonNr,endestasjonNr, endestasjonNr, startstasjonNr, endestasjonNr])

        rows = cursor.fetchall()
        if rows:
            print("\n")
            print(tabulate(rows, headers= ["Vognnummer", "Setenummer"]))
            print("\n")

            vognummer = input("Vennligst skriv inn ønskede vognnummer: ")
            setenummer = input("Vennligst skriv inn din ønskede setenummer: ")

            cursor.execute('SELECT togvogn.togvognID\
                FROM togruteforekomst, togrute, vognoppsett, togvogn\
                WHERE togruteforekomst.togruteforekomstID = ?\
                AND togruteforekomst.ruteID = togrute.ruteID\
                AND vognoppsett.ruteID = togrute.ruteID \
                AND togvogn.vognoppsettID = vognoppsett.vognoppsettID\
                AND togvogn.vognummer =  ?', [forekomstID, vognummer])

            row = cursor.fetchone()
            vognID = row[0]

            billettID = id([vognummer, setenummer, forekomstID, kundeMobil])

            cursor.execute('INSERT INTO seteBillett VALUES (?, ?, ?, ?, ?, ?, ?)', [billettID, setenummer, vognID, ordreID, startstasjon, endestasjon, 1])

            con.commit()
        else:
            print("\nDessverre ingen flere ledige seter på denne togruten\n")

    else:
        cursor.execute('SELECT togvogn.vognummer, seng.sengnummer\
            FROM togrute, vognoppsett, togvogn, seng, togruteforekomst\
            WHERE  togruteforekomst.togruteforekomstID = ?\
            AND togruteforekomst.ruteID = togrute.ruteID\
            AND togrute.ruteID = vognoppsett.ruteID\
            AND togvogn.vognoppsettID = vognoppsett.vognoppsettID\
            AND togvogn.vogntypeID = seng.vogntypeID\
            EXCEPT\
            SELECT  togvogn.vognummer, sengBillett.sengnummer\
            FROM sengBillett\
            INNER JOIN togvogn ON sengBillett.togvognID = togvogn.togvognID\
            INNER JOIN kundeordre ON kundeordre.ordreID = sengBillett.ordreID\
            INNER JOIN togruteforekomst ON togruteforekomst.togruteforekomstID = kundeordre.togruteforekomstID\
            WHERE togruteforekomst.togruteforekomstID = ?\
            UNION\
            SELECT togvogn.vognummer, sengBillett.sengnummer\
            FROM sengBillett\
            INNER JOIN togvogn ON togvogn.togvognID = sengBillett.togvognID\
            INNER JOIN kundeordre ON sengBillett.ordreID = kundeordre.ordreID\
            INNER JOIN kunde ON kundeordre.kundenummer = kunde.kundenummer\
            WHERE kunde.kundenummer = ?\
            AND sengBillett.solgt = 0', [forekomstID, forekomstID, kundenummer])
                    
        rows = cursor.fetchall()

        if len(rows) > 0:
            print("\n")
            print(tabulate(rows, headers= ["Vognnummer", "Sengnummer"]))
            print("\n")

            vognummer = input("Vennligst skriv inn ønskede vognnummer: ")
            sengnummer = input("Vennligst skriv inn din ønskede sengnummer: ")

            solgte.append((vognummer, sengnummer))
            ikkeLedig.append((vognummer, sovenummer(int(sengnummer))))

            cursor.execute('SELECT togvogn.togvognID\
                FROM togruteforekomst, togrute, vognoppsett, togvogn\
                WHERE togruteforekomst.togruteforekomstID = ?\
                AND togruteforekomst.ruteID = togrute.ruteID\
                AND vognoppsett.ruteID = togrute.ruteID \
                AND togvogn.vognoppsettID = vognoppsett.vognoppsettID\
                AND togvogn.vognummer =  ?', [forekomstID, vognummer])

            row = cursor.fetchone()
            vognID = row[0]

            billettID = id([vognummer, sengnummer, forekomstID, kundeMobil])

            cursor.execute('INSERT INTO sengBillett VALUES (?, ?, ?, ?, ?, ?, ?)', [billettID, sengnummer, vognID, ordreID, startstasjon, endestasjon, 1])
            con.commit()
        else:
            print("\nDessverre ingen flere ledige senger på denne togruten\n")


    vilFortsette = input("Har du lyst til å kjøpe flere billetter (Ja/Nei): ")
    if (vilFortsette == "Nei"):
        uledigeSenger = [t for t in ikkeLedig if t not in solgte]

        for el in uledigeSenger:

            cursor.execute('SELECT togvogn.togvognID\
                FROM togruteforekomst, togrute, vognoppsett, togvogn\
                WHERE togruteforekomst.togruteforekomstID = ?\
                AND togruteforekomst.ruteID = togrute.ruteID\
                AND vognoppsett.ruteID = togrute.ruteID \
                AND togvogn.vognoppsettID = vognoppsett.vognoppsettID\
                AND togvogn.vognummer =  ?', [forekomstID, el[0]])

            row = cursor.fetchone()
            vognID = row[0]

            #Legger inn hvilke senger som ikke kan selges videre med solgt verdi 0
            cursor.execute('INSERT INTO sengBillett VALUES (?, ?, ?, ?, ?, ?, ?)', [random.randint(1000000000, 9999999999), el[1], vognID, ordreID, startstasjon, endestasjon, 0]) 
            con.commit()
        break

con.close()