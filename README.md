# MariaDB mentési script

Ez a Bash script automatizált, tömörített mentést készít a MariaDB adatbázisokról. Az adatbázisokat külön könyvtárba menti, a mentéseket `gzip` segítségével tömöríti, és törli a megadott időnél régebbi fájlokat.

## Funkciók

- A MariaDB-ben található adatbázisok automatikus felismerése.
- Az `_schema` végződésű adatbázisok kihagyása.
- Minden adatbázis külön könyvtárba mentése.
- SQL dump készítése az alábbi elemekkel:
  - táblák és adatok;
  - események (`events`);
  - tárolt eljárások és függvények (`routines`);
  - triggerek (`triggers`);
  - adatbázis törlése és újralétrehozása importáláskor (`--add-drop-database`).
- A dumpok `gzip -9` tömörítéssel való mentése.
- A 7 napnál régebbi mentések automatikus törlése.
- Hibakezelés Bash strict mode használatával (`set -euo pipefail`).

## Követelmények

A futtató gépen az alábbi programoknak elérhetőnek kell lenniük:

- Bash
- MariaDB kliens (`mariadb`)
- `mysqldump`
- `gzip`
- `find`
- `awk`

Ellenőrzés például:

```bash
command -v mariadb mysqldump gzip find awk
```

## Telepítés és konfiguráció

1. Klónozd a repository-t, vagy másold a scriptet a szerverre:

   ```bash
   git clone https://github.com/CsAdika-dev/maraidb_backup.git
   cd maraidb_backup
   ```

2. Töltsd ki a MariaDB kapcsolati adatokat a konfigurációs fájlban:

   ```ini
   [client]
   user="backup_user"
   password="erős-jelszó"
   host="127.0.0.1"
   port="3306"
   ```

3. **Fontos:** a script jelenleg `./mariadb.conf` fájlt keres, miközben a repository-ban található fájl neve `mariadb.cnf`. A script futtatása előtt nevezd át a fájlt:

   ```bash
   mv mariadb.cnf mariadb.conf
   ```

   vagy módosítsd a `backup_mariadb.sh` fájlban ezt a sort:

   ```bash
   MARIADBEXTRAFILE="./mariadb.conf"
   ```

   erre:

   ```bash
   MARIADBEXTRAFILE="./mariadb.cnf"
   ```

4. Védd a konfigurációs fájlt, mert jelszót tartalmazhat:

   ```bash
   chmod 600 mariadb.conf
   ```

5. Tedd futtathatóvá a scriptet:

   ```bash
   chmod +x backup_mariadb.sh
   ```

## Használat

A scriptet abból a könyvtárból futtasd, ahol a konfigurációs fájl található:

```bash
./backup_mariadb.sh
```

A mentések alapértelmezett könyvtárszerkezete:

```text
backup/
├── adatbazis_1/
│   └── 2026-01-01_12-30-00.sql.gz
└── adatbazis_2/
    └── 2026-01-01_12-30-00.sql.gz
```

A fájlnév formátuma:

```text
YYYY-MM-DD_HH-MM-SS.sql.gz
```

## Beállítások módosítása

A `backup_mariadb.sh` elején található változókkal módosítható a működés:

| Változó | Alapérték | Leírás |
|---|---:|---|
| `BACKUP_DIR` | `./backup` | A mentések célkönyvtára. |
| `IGNORE_DB` | `(_schema$)` | A kihagyandó adatbázisok neveit meghatározó reguláris kifejezés. |
| `KEEP_BACKUPS_FOR` | `7` | Ennyi napnál régebbi `.sql.gz` fájlokat töröl a script. |
| `MARIADBEXTRAFILE` | `./mariadb.conf` | A MariaDB kapcsolati konfigurációjának elérési útja. |
| `DUMPOPTIONS` | `--add-drop-database --events --routines --triggers` | A `mysqldump` kapcsolói. |

Például a mentések 30 napig történő megőrzéséhez:

```bash
KEEP_BACKUPS_FOR=30
```

## Automatikus futtatás cron segítségével

Napi futtatáshoz nyisd meg a cron táblát:

```bash
crontab -e
```

Majd adj hozzá egy bejegyzést, például hajnali 02:00 órára:

```cron
0 2 * * * cd /opt/maraidb_backup && /opt/maraidb_backup/backup_mariadb.sh >> /var/log/mariadb-backup.log 2>&1
```

A cron használatakor mindig abszolút elérési utakat használj, mivel a cron munkakönyvtára eltérhet az interaktív shell munkakönyvtárától.

## Visszaállítás

Egy tömörített mentés visszaállítása például így történhet:

```bash
gunzip -c backup/adatbazis_1/2026-01-01_12-30-00.sql.gz | mariadb --defaults-extra-file=./mariadb.conf
```

A visszaállítás előtt ellenőrizd a mentés tartalmát és győződj meg arról, hogy a célkörnyezet megfelelő. A `--add-drop-database` kapcsoló miatt a dump importáláskor törölheti, majd újra létrehozhatja az adatbázist.

## Biztonsági javaslatok

- A konfigurációs fájlt ne tedd nyilvános repository-ba valódi jelszóval.
- Használj kizárólag mentéshez szükséges jogosultságokkal rendelkező MariaDB-felhasználót.
- A mentési könyvtár jogosultságait korlátozd.
- A mentéseket lehetőleg külön lemezen vagy másik gépen is tárold.
- Rendszeresen teszteld a visszaállítást; a sikeresen elkészült dump önmagában nem garantálja a visszaállíthatóságot.

## Licenc

A repository jelenleg nem tartalmaz külön licencfájlt.
