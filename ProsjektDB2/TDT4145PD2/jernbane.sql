--delete already existing tables

drop table jernbanestasjon;
drop table banestrekning;
drop table delstrekning;
drop table delstrekningTilhørendeBanestrekning;
drop table operatør;
drop table kunde;
drop table vogntype;
drop table sittevogn;
drop table sete;
drop table sovevogn;
drop table seng;
drop table togrute;
drop table togvogn;
drop table vognoppsett;
drop table ukedag;
drop table aktiveUkedager;
drop table rutetabell;
drop table togruteStasjoner;
drop table togruteforekomst;
drop table kundeordre;
drop table sengBillett;
drop table seteBillett;


--create tables

create table jernbanestasjon (
    navn               varchar(40),
    moh                float CHECK (moh > 0),
    constraint jernbanestasjon_pk primary key (navn)
);

create table banestrekning (
    banestrekningID    integer,
    navn               varchar(40),
    fremdriftsenergi   varchar(9) CHECK (fremdriftsenergi = "Elektrisk" OR fremdriftsenergi = "Diesel"),
    startStasjon       varchar(40),
    endeStasjon        varchar(40),
    constraint banestrekning_pk primary key (banestrekningID)
    constraint banestrekning_fk1 foreign key (startStasjon) references jernbanestasjon(navn)
        on update cascade
        on delete cascade,
    constraint banestrekning_fk2 foreign key (endeStasjon) references jernbanestasjon(navn)
        on update cascade
        on delete cascade
);


create table delstrekning (
    stasjonA           varchar(40),
    stasjonB           varchar(40),
    lengde             integer CHECK (lengde > 0),
    sportype           varchar(6) CHECK (sportype = "Enkel" OR sportype = "Dobbel"),
    constraint delstrekning_pk primary key (stasjonA, stasjonB),
    constraint delstrekning_fk1 foreign key (stasjonA) references jernbanestasjon(navn)
        on update cascade
        on delete cascade,
    constraint delstrekning_fk2 foreign key (stasjonB) references jernbanestasjon(navn)
        on update cascade
        on delete cascade
);

create table delstrekningTilhørendeBanestrekning (
    stasjonA           varchar(40),
    stasjonB           varchar(40),
    banestrekningID    integer,
    constraint delstrekningTilhørendeBanestrekning_pk primary key (stasjonA, stasjonB, banestrekningID),
    constraint delstrekningTilhørendeBanestrekning_fk1 foreign key (stasjonA) references delstrekning(stasjonA)
        on update cascade
        on delete cascade,
    constraint delstrekningTilhørendeBanestrekning_fk1 foreign key (stasjonB) references delstrekning(stasjonB)
        on update cascade
        on delete cascade,
    constraint delstrekningTilhørendeBanestrekning_fk2 foreign key (banestrekningID) references banestrekning(banestrekningID)
        on update cascade
        on delete cascade
);

create table operatør (
    operatørID         integer,
    navn               varchar(40),
    constraint operatør_pk primary key (operatørID)
);

create table kunde (
    kundenummer        integer,
    fornavn            varchar(40),
    etternavn          varchar(40),
    epost              varchar(40),
    mobilnummer        varchar(12) UNIQUE,
    constraint kunde_pk primary key (kundenummer)
);

create table vogntype (
    vogntypeID         integer,
    navn               varchar(40),
    type               varchar(9) CHECK (type = "Sittevogn" OR type = "Sovevogn"),
    operatørID         integer,
    constraint vogntype_pk primary key (vogntypeID),
    constraint vogntype_fk foreign key (operatørID) references operatør(operatørID)
        on update cascade
        on delete cascade
);

create table sittevogn (
    vogntypeID         integer,
    stolrader          integer,
    seterPerRad        integer,
    constraint sittevogn_pk primary key (vogntypeID),
    constraint sittevogn_fk foreign key (vogntypeID) references vogntype(vogntypeID)
        on update cascade
        on delete cascade
);

create table sete (
    vogntypeID         integer,
    setenummer         integer,
    constraint sete_pk primary key (vogntypeID, setenummer),
    constraint sete_fk foreign key (vogntypeID) references vogntype(vogntypeID)
        on update cascade
        on delete cascade
);

create table sovevogn (
    vogntypeID         integer,
    sovekupeer         integer,
    constraint sovevogn_pk primary key (vogntypeID),
    constraint sovevogn_fk foreign key (vogntypeID) references vogntype(vogntypeID)
        on update cascade
        on delete cascade
);

create table seng (
    vogntypeID         integer,
    sengnummer         integer,
    constraint sete_pk primary key (vogntypeID, sengnummer),
    constraint sete_fk foreign key (vogntypeID) references vogntype(vogntypeID)
        on update cascade
        on delete cascade
);

create table togrute (
    ruteID             integer,
    retning            varchar(3) CHECK (retning = "Mot" OR retning= "Med"),
    navn               varchar(40) UNIQUE,
    banestrekningID    integer,
    operatørID         integer,
    constraint togrute_pk primary key (ruteID),
    constraint togrute_fk1 foreign key (banestrekningID) references banestrekning(banestrekningID)
        on update cascade
        on delete cascade,
    constraint togrute_fk2 foreign key (operatørID) references operatør(operatørID)
        on update cascade
        on delete cascade
);

create table togvogn (
    togvognID          integer,
    vogntypeID         integer,
    vognoppsettID      integer,
    vognummer          integer,
    constraint togvogn_pk primary key (togvognID),
    constraint togvogn_fk1 foreign key (vogntypeID) references vogntype(vogntypeID)
        on update cascade
        on delete cascade,
    constraint togvogn_fk2 foreign key (vognoppsettID) references vognoppsett(vognoppsettID)
        on update cascade
        on delete cascade,
    constraint togvogn_cs UNIQUE (vognoppsettID, vognummer) /* Sørger for at ett vognoppsett ikke har flere togvogner med samme vognummer */
);   

create table vognoppsett (
    vognoppsettID      integer,
    ruteID             integer UNIQUE, /* Sørger for at en togrute ikke kan ha flere vognoppsett */
    constraint vognoppsett_pk primary key (vognoppsettID),
    constraint vognoppsett_fk foreign key (ruteID) references togrute(ruteID)
        on update cascade
        on delete cascade
);

create table ukedag (
    dagID              integer CHECK (dagID >= 0 AND dagID <= 6),
    dagNavn            varchar(7),
    constraint ukedager_pk primary key (dagID)
);

create table aktiveUkedager (
    ruteID             integer,
    dagID              integer,
    constraint aktiveUkedager_pk primary key (dagID, ruteID),
    constraint aktiveUkedager_fk1 foreign key (dagID) references ukedag(dagID)
        on update cascade
        on delete cascade,
    constraint aktiveUkedager_fk2 foreign key (ruteID) references togrute(ruteID)
        on update cascade
        on delete cascade
);

create table rutetabell (
    rutetabellID       integer,
    ruteID             integer UNIQUE, /* Sørger for at en togrute ikke kan ha flere rutetabeller */
    constraint rutetabell_pk primary key (rutetabellID),
    constraint rutetabell_fk1 foreign key (ruteID) references togrute(ruteID)
        on update cascade
        on delete cascade
);

create table togruteStasjoner (
    rutetabellID       integer,
    stasjonNavn        varchar(40),
    tid                varchar(5),
    stasjonNr          integer,
    constraint togruteStasjoner_pk primary key (rutetabellID, stasjonNavn),
    constraint togruteStasjoner_fk1 foreign key (rutetabellID) references rutetabell(rutetabellID)
        on update cascade
        on delete cascade,
    constraint togruteStasjoner_fk2 foreign key (stasjonNavn) references jernbanestasjon(navn)
        on update cascade
        on delete cascade,
    constraint togruteStasjoner_cs UNIQUE (rutetabellID, stasjonNr) /* Sørger for at en rutetabell ikke har flere stasjoner med samme stasjonnummer*/
);

create table togruteforekomst (
    togruteforekomstID integer,
    ruteID             integer,
    dato               varchar(10),
    constraint togruteforekomst_pk primary key (togruteforekomstID),
    constraint togruteforekomst_fk2 foreign key (ruteID) references togrute(ruteID)
        on update cascade
        on delete cascade
    constraint togruteforekomst_cs UNIQUE (ruteID, dato) /* Sørger for at en togrute ikke kan kjøres flere ganger per dato */
);

create table kundeordre (
    ordreID            integer,
    dato               varchar(10),
    tid                varchar(5),
    kundenummer        integer,
    togruteforekomstID integer,
    constraint kundeordre_pk primary key (ordreID),
    constraint kundeordre_fk1 foreign key (kundenummer) references kunde(kundenummer)
        on update cascade
        on delete cascade,
    constraint kundeordre_fk2 foreign key (togruteforekomstID) references togruteforekomst(togruteforekomstID)
        on update cascade
        on delete cascade
);

create table sengBillett (
    billettID          integer,
    sengnummer         integer,
    togvognID          integer,
    ordreID            integer,
    stasjonA           varchar(40),
    stasjonB           varchar(40),
    solgt              integer CHECK (solgt = 0 OR solgt = 1),
    constraint sengBillett_pk primary key (billettID),
    constraint sengBillett_fk1 foreign key (togvognID) references togvogn(togvognID)
        on update cascade
        on delete cascade,
    constraint sengBillett_fk2 foreign key (ordreID) references kundeordre(ordreID)
        on update cascade
        on delete cascade
    constraint sengBillett_fk3 foreign key (stasjonA) references jernbanestasjon(navn)
        on update cascade
        on delete cascade,
    constraint sengBillett_fk4 foreign key (stasjonB) references jernbanestasjon(navn)
        on update cascade
        on delete cascade
);

create table seteBillett (
    billettID          integer,
    setenummer         integer,
    togvognID          integer,
    ordreID            integer,
    stasjonA           varchar(40),
    stasjonB           varchar(40),
    solgt              integer CHECK (solgt = 0 OR solgt = 1),
    constraint seteBillett_pk primary key (billettID),
    constraint seteBillett_fk1 foreign key (togvognID) references togvogn(togvognID)
        on update cascade
        on delete cascade,
    constraint seteBillett_fk2 foreign key (ordreID) references kundeordre(ordreID)
        on update cascade
        on delete cascade,
    constraint seteBillett_fk3 foreign key (stasjonA) references jernbanestasjon(navn)
        on update cascade
        on delete cascade,
    constraint seteBillett_fk4 foreign key (stasjonB) references jernbanestasjon(navn)
        on update cascade
        on delete cascade
);




--brukerhistorie a

--insert values for ukedag
insert into ukedag values (0, "Mandag");
insert into ukedag values (1, "Tirsdag");
insert into ukedag values (2, "Onsdag");
insert into ukedag values (3, "Torsdag");
insert into ukedag values (4, "Fredag");
insert into ukedag values (5, "Lørdag");
insert into ukedag values (6, "Søndag");

--insert values for jernbanestasjoner
insert into jernbanestasjon values ("Trondheim S", 5.1);
insert into jernbanestasjon values ("Steinkjer", 3.6);
insert into jernbanestasjon values ("Mosjøen", 6.8);
insert into jernbanestasjon values ("Mo i Rana", 3.5);
insert into jernbanestasjon values ("Fauske", 34.0);
insert into jernbanestasjon values ("Bodø", 4.1);

--insert values for delstrekning
insert into delstrekning values ("Trondheim S", "Steinkjer", 120, "Dobbel");
insert into delstrekning values ("Steinkjer", "Mosjøen", 280, "Enkel");
insert into delstrekning values ("Mosøjen", "Mo i Rana", 90, "Enkel");
insert into delstrekning values ("Mo i Rana", "Fauske", 170, "Enkel");
insert into delstrekning values ("Fauske", "Bodø", 70, "Enkel");

--insert values for banestrekning
insert into banestrekning values (0, "Nordlandsbanen", "Diesel", "Trondheim S", "Bodø");

--insert values for delstrekningTilhørendeBanestrekning
insert into delstrekningTilhørendeBanestrekning values ("Trondheim S", "Steinkjer", 0);
insert into delstrekningTilhørendeBanestrekning values ("Steinkjer", "Mosjøen", 0);
insert into delstrekningTilhørendeBanestrekning values ("Mosøjen", "Mo i Rana", 0);
insert into delstrekningTilhørendeBanestrekning values ("Mo i Rana", "Fauske", 0);
insert into delstrekningTilhørendeBanestrekning values ("Fauske", "Bodø", 0);


--brukerhistorie b

--insert values for operatør
insert into operatør values (0, "SJ");

--insert values for vogntype
insert into vogntype values (0, "SJ-sittevogn-1", "Sittevogn", 0);
insert into vogntype values (1, "SJ-sovevogn-1", "Sovevogn", 0);

--insert values for sittevogn
insert into sittevogn values (0, 3, 4);

--insert values for sovevogn
insert into sovevogn values (1, 4); 

--insert values for sete
insert into sete values (0, 1);
insert into sete values (0, 2);
insert into sete values (0, 3);
insert into sete values (0, 4);
insert into sete values (0, 5);
insert into sete values (0, 6);
insert into sete values (0, 7);
insert into sete values (0, 8);
insert into sete values (0, 9);
insert into sete values (0, 10);
insert into sete values (0, 11);
insert into sete values (0, 12);

--insert values for seng
insert into seng values (1, 1);
insert into seng values (1, 2);
insert into seng values (1, 3);
insert into seng values (1, 4);
insert into seng values (1, 5);
insert into seng values (1, 6);
insert into seng values (1, 7);
insert into seng values (1, 8);

--insert values for togrute
insert into togrute values (0, "Med","Trondheim-Bodø dagtog", 0, 0);
insert into togrute values (1, "Med","Trondheim-Bodø nattog", 0, 0);
insert into togrute values (2, "Mot","Mo i Rana-Trondheim morgentog", 0, 0);

--insert values for vognoppsett
insert into vognoppsett values (0, 0);
insert into vognoppsett values (1, 1);
insert into vognoppsett values (2, 2);

--insert values for togvogn    
insert into togvogn values (0, 0, 0, 1);
insert into togvogn values (1, 0, 0, 2);
insert into togvogn values (2, 0, 1, 1);
insert into togvogn values (3, 1, 1, 2);
insert into togvogn values (4, 0, 2, 1);


--insert values for togruteAktiveUkedager
insert into aktiveUkedager values (0, 0);
insert into aktiveUkedager values (0, 1);
insert into aktiveUkedager values (0, 2);
insert into aktiveUkedager values (0, 3);
insert into aktiveUkedager values (0, 4);
insert into aktiveUkedager values (1, 0);
insert into aktiveUkedager values (1, 1);
insert into aktiveUkedager values (1, 2);
insert into aktiveUkedager values (1, 3);
insert into aktiveUkedager values (1, 4);
insert into aktiveUkedager values (1, 5);
insert into aktiveUkedager values (1, 6);
insert into aktiveUkedager values (2, 0);
insert into aktiveUkedager values (2, 1);
insert into aktiveUkedager values (2, 2);
insert into aktiveUkedager values (2, 3);
insert into aktiveUkedager values (2, 4);

--insert values for rutetabell          
insert into rutetabell values (0, 0);
insert into rutetabell values (1, 1);
insert into rutetabell values (2, 2);

--insert values for togruteMellomStasjoner
insert into togruteStasjoner values (0, "Trondheim S", "07:49", 1);
insert into togruteStasjoner values (0, "Steinkjer", "09:51", 2);
insert into togruteStasjoner values (0, "Mosjøen", "13:20", 3);
insert into togruteStasjoner values (0, "Mo i Rana", "14:31", 4);
insert into togruteStasjoner values (0, "Fauske", "16:49", 5);
insert into togruteStasjoner values (0, "Bodø", "17:34", 6);
insert into togruteStasjoner values (1, "Trondheim S", "23:05", 1);
insert into togruteStasjoner values (1, "Steinkjer", "00:57", 2);
insert into togruteStasjoner values (1, "Mosjøen", "04:41", 3);
insert into togruteStasjoner values (1, "Mo i Rana", "05:55", 4);
insert into togruteStasjoner values (1, "Fauske", "08:19", 5);
insert into togruteStasjoner values (1, "Bodø", "09:05", 6);
insert into togruteStasjoner values (2, "Mo i Rana", "08:11", 1);
insert into togruteStasjoner values (2, "Mosjøen", "09:14", 2);
insert into togruteStasjoner values (2, "Steinkjer", "12:31", 3);
insert into togruteStasjoner values (2, "Trondheim S", "14:12", 4);

--brukerhistorie f

--insert values for togruteforekomst
insert into togruteforekomst values (0, 0, "2023-04-03");
insert into togruteforekomst values (1, 0, "2023-04-04");
insert into togruteforekomst values (2, 1, "2023-04-03");
insert into togruteforekomst values (3, 1, "2023-04-04");
insert into togruteforekomst values (4, 2, "2023-04-03");
insert into togruteforekomst values (5, 2, "2023-04-04");

--insert values for kunde
insert into kunde values (0, "Ryan", "Garcia", "ryan@gmail.com", "+4793070707");
insert into kunde values (1, "Gervonta", "Davis", "tank@gmail.com", "+4793070704");