import sqlite3 
from tabulate import tabulate
import re

con = sqlite3.connect("linje5.db")

cursor = con.cursor()

customerInfo = []
pattern = r'^[a-zA-Z]+$' #regex for å sjekke at det kun blir gitt bokstaver
emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' #regex for å sjekke mail
phonePattern = r'^\+47\d{8}$' #regex for å sjekke mobilnummer

while True:
    fornavn = input("Vennligst skriv inn ditt fornavn: ")
    result = re.match(pattern, fornavn)
    if result:
        customerInfo.append(fornavn)
        break

while True:
    etternavn = input("Vennligst skriv inn ditt etternavn: ")
    result = re.match(pattern, etternavn)
    if result:
        customerInfo.append(etternavn)
        break

while True:
    epost = input("Vennligst skriv inn ditt epost: ")
    result = re.match(emailPattern, epost)
    if result:
        customerInfo.append(epost)
        break

while True:
    mobilnummer = input("Vennligst skriv inn ditt mobilnummer (+47XXXXXXXX): ")
    result = re.match(phonePattern, mobilnummer)
    if result:
        customerInfo.append(mobilnummer)
        break


id = id(customerInfo)

try:
    cursor.execute("INSERT INTO kunde VALUES (?, ?, ?, ?, ?)", (id, customerInfo[0], customerInfo[1], customerInfo[2], customerInfo[3]))
    con.commit()

    cursor.execute("SELECT * FROM kunde WHERE kundenummer = ?", [str(id)])
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["Kundenummer", "Fornavn", "Etternavn", "Epost", "Mobilnummer" ]))
    print("\n")
except sqlite3.IntegrityError as e:
    print("\nDette mobilnummeret er allerede registrert i vårt kunderegister\n")



con.close()

