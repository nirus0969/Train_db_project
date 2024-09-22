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
    mobilnummer        varchar(12),
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
    sengPerKupee       integer,
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
    navn               varchar(40),
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
    dato               varchar(8),
    constraint togruteforekomst_pk primary key (togruteforekomstID),
    constraint togruteforekomst_fk2 foreign key (ruteID) references togrute(ruteID)
        on update cascade
        on delete cascade
);

create table kundeordre (
    ordreID            integer,
    dato               varchar(8),
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
