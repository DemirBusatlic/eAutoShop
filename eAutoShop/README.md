# eAutoShop

eAutoShop je informacioni sistem za upravljanje prodajom automobilskih proizvoda i pružanjem autoservisnih usluga. Sistem se sastoji od ASP.NET Core API-ja, pomoćnog API-ja za generisanje izvještaja, Flutter desktop aplikacije za zaposlenike i Flutter mobilne aplikacije za kupce.

Autor: **Demir Bušatlić (IB190081)**  
Predmet: **Razvoj softvera II**

## Funkcionalnosti

### Desktop aplikacija

- prijava menadžera, prodavača i tehničara;
- upravljanje korisnicima i zaposlenicima;
- upravljanje proizvodima, kategorijama, proizvođačima i modelima vozila;
- upravljanje tipovima i ponudom servisnih usluga;
- pregled i obrada narudžbi;
- pregled, potvrđivanje, odbijanje i obrada rezervacija;
- dodjeljivanje tehničara rezervacijama;
- pregled i moderiranje recenzija;
- generisanje, preuzimanje i ispis PDF izvještaja;
- prijem obavijesti o generisanim izvještajima putem SignalR-a.

### Mobilna aplikacija

- registracija i prijava kupca;
- pregled, pretraga i filtriranje proizvoda;
- prikaz preporučenih proizvoda i razloga preporuke;
- kreiranje narudžbe i Stripe sandbox plaćanje;
- pregled historije i statusa narudžbi;
- pregled usluga i rezervacija termina;
- pregled historije i statusa rezervacija;
- ocjenjivanje proizvoda i zaposlenika;
- pregled i izmjena korisničkog profila;
- promjena lozinke;
- prijem lokalnih SignalR obavijesti o promjenama statusa narudžbi i rezervacija.

## Korištene tehnologije

- ASP.NET Core 8 Web API;
- Entity Framework Core i Microsoft SQL Server 2022;
- Flutter za Android i Windows aplikacije;
- JWT autentifikacija i autorizacija zasnovana na ulogama;
- RabbitMQ za asinhrono generisanje izvještaja;
- SignalR za obavijesti u stvarnom vremenu;
- Stripe sandbox za plaćanje i refundiranje;
- ML.NET Matrix Factorization za preporuke proizvoda;
- Docker i Docker Compose.

## Struktura projekta

```text
eAutoShop/
├── eAutoShop.Api/                  glavni REST API
├── eAutoShop.Worker/               RabbitMQ Worker za obradu i generisanje izvještaja
├── eAutoShop.Model/                modeli, requesti i search objekti
├── eAutoShop.Services/             poslovna logika i pristup podacima
├── eAutoShop.DB/                   SQL skripta 190081.sql
├── eAutoShop.UI/
│   ├── eautoshop_desktop/          Flutter Windows aplikacija
│   └── eautoshop_mobile/           Flutter Android aplikacija
├── docker-compose.yml
├── .env-tajne.zip
└── recommender-dokumentacija.md
```

## Preduslovi

Za pokretanje projekta potrebno je instalirati:

- Git;
- Docker Desktop;
- Flutter SDK;
- Visual Studio s opcijom **Desktop development with C++** za Windows aplikaciju;
- Android Studio i Android emulator za mobilnu aplikaciju.

Ispravnost Flutter okruženja može se provjeriti komandom:

```powershell
flutter doctor
```

## Preuzimanje projekta

```powershell
git clone https://github.com/DemirBusatlic/eAutoShop.git
cd eAutoShop
```

Nakon kloniranja, root GitHub repozitorija sadrži dodatni folder `eAutoShop` u kojem se nalaze backend, Flutter aplikacije i `docker-compose.yml`:

```text
eAutoShop/                  root GitHub repozitorija
├── README.md
├── .gitignore
└── eAutoShop/              aplikacija
    ├── docker-compose.yml
    ├── .env-tajne.zip
    └── eAutoShop.UI/
```

## Konfiguracijski fajlovi

Projekat koristi dva odvojena `.env` fajla. Zbog zaštite osjetljivih podataka oni su dostavljeni kao šifrovane ZIP arhive. Šifra za arhive dostavlja se putem DLWMS-a.

### Backend konfiguracija

Arhiva se nalazi na lokaciji:

```text
eAutoShop/.env-tajne.zip
```

Arhivu treba raspakovati u isti folder u kojem se nalazi `docker-compose.yml`. Nakon raspakivanja struktura treba izgledati ovako:

```text
eAutoShop/
├── .env
└── docker-compose.yml
```

Backend `.env` sadrži SQL Server, RabbitMQ, JWT i Stripe konfiguraciju.

### Mobilna konfiguracija

Arhiva se nalazi na lokaciji:

```text
eAutoShop/eAutoShop.UI/eautoshop_mobile/.env-tajne.zip
```

Arhivu treba raspakovati u isti folder. Nakon raspakivanja treba postojati:

```text
eAutoShop/eAutoShop.UI/eautoshop_mobile/.env
```

Mobilni `.env` sadrži Stripe publishable key.

## Pokretanje aplikacije iz izvornog koda

### Pokretanje backenda

Iz root foldera kloniranog GitHub repozitorija otvoriti folder u kojem se nalazi `docker-compose.yml`:

```powershell
cd eAutoShop
docker compose up --build
```

Terminal u kojem je pokrenut Docker Compose treba ostaviti otvoren. Desktop i mobilnu aplikaciju pokrenuti u zasebnim terminalima.

Prvo pokretanje može trajati nekoliko minuta. Docker Compose pokreće:

| Servis | Adresa/port |
|---|---|
| Glavni API | `http://localhost:5236` |
| Swagger | `http://localhost:5236/swagger` |
| Worker | Nema HTTP endpoint; komunicira preko RabbitMQ-a |
| SQL Server | `localhost:1401` |
| RabbitMQ | `localhost:5672` |
| RabbitMQ Management | `http://localhost:15672` |

Status servisa može se provjeriti komandom:

```powershell
docker compose ps
```

SQL Server i RabbitMQ trebaju imati status `healthy`, dok API i Helper API trebaju biti pokrenuti.

Za zaustavljanje sistema koristiti:

```powershell
docker compose down
```

Za potpuno brisanje Docker baze i ponovno izvršavanje SQL skripte koristiti:

```powershell
docker compose down -v
docker compose up --build
```

Ova komanda briše podatke iz postojećeg Docker volumena.

### Pokretanje desktop aplikacije

Backend mora biti pokrenut prije desktop aplikacije. Otvoriti novi terminal u root folderu kloniranog repozitorija i pokrenuti:

```powershell
cd eAutoShop\eAutoShop.UI\eautoshop_desktop
flutter pub get
flutter run -d windows
```

Desktop aplikacija podrazumijevano pristupa API-ju na adresi `http://localhost:5236`.

Druga adresa ili port mogu se proslijediti prilikom pokretanja:

```powershell
flutter run -d windows --dart-define=API_HOST=localhost --dart-define=API_PORT=5236
```

### Pokretanje mobilne aplikacije

Backend i Android emulator moraju biti pokrenuti prije mobilne aplikacije. Otvoriti novi terminal.

Pregled dostupnih emulatora:

```powershell
flutter emulators
```

Pokretanje emulatora:

```powershell
flutter emulators --launch Pixel_9_Pro_XL
```

Ako emulator ima drugačiji ID, koristiti ID prikazan komandom `flutter emulators`.

Pokretanje aplikacije:

```powershell
cd eAutoShop\eAutoShop.UI\eautoshop_mobile
flutter pub get
flutter run
```

Mobilna aplikacija podrazumijevano koristi `10.0.2.2:5236`, standardnu adresu kojom Android emulator pristupa API-ju na računaru.

Adresa se po potrebi može proslijediti komandno:

```powershell
flutter run --dart-define=API_HOST=10.0.2.2 --dart-define=API_PORT=5236
```

## Pokretanje gotovih buildova

ZIP arhivu s build fajlovima treba preuzeti iz tačnog GitHub Releasea i raspakovati na računar. Backend se i u ovom slučaju prethodno pokreće iz izvornog koda komandom:

```powershell
cd eAutoShop
docker compose up --build
```

### Windows build

U raspakovanoj build arhivi otvoriti Windows `Release` folder i pokrenuti:

```text
eautoshop_desktop.exe
```

Potrebno je zadržati sve fajlove iz `Release` foldera; nije dovoljno izdvojiti samo `.exe` fajl.

### Android build

U raspakovanoj build arhivi pronaći:

```text
app-release.apk
```

APK se može instalirati prevlačenjem fajla na pokrenuti Android emulator ili korištenjem Android alata za instalaciju. Nakon instalacije aplikaciju pokrenuti na emulatoru. Mobilna aplikacija koristi adresu `10.0.2.2:5236` za pristup API-ju na računaru.

## Korisnički podaci

Lozinka za sve testne korisnike je:

```text
korisnik
```

| Aplikacija | Uloga | Korisničko ime | Lozinka |
|---|---|---|---|
| Desktop | Menadžer | `manager.admin` | `korisnik` |
| Desktop | Prodavač | `sales.amir` | `korisnik` |
| Desktop | Prodavač | `sales.adnan` | `korisnik` |
| Desktop | Tehničar | `tech.jasna` | `korisnik` |
| Desktop | Tehničar | `tech.lejla` | `korisnik` |
| Desktop | Tehničar | `tech.armin` | `korisnik` |
| Mobilna | Kupac | `customer.selma` | `korisnik` |
| Mobilna | Kupac | `customer.emina` | `korisnik` |
| Mobilna | Kupac | `customer.tarik` | `korisnik` |

Desktop aplikacija prihvata račune zaposlenika, dok je mobilna aplikacija namijenjena korisnicima s ulogom kupca.

## Stripe testno plaćanje

Za testiranje plaćanja koristi se Stripe sandbox okruženje.

| Polje | Vrijednost |
|---|---|
| Broj kartice | `4242 4242 4242 4242` |
| Datum isteka | 12/34 |
| CVC | 123 |
| Poštanski broj | bilo koja validna vrijednost |

Ne koristiti stvarne podatke platne kartice.

## Izvještaji

Desktop aplikacija omogućava generisanje izvještaja prema izabranim parametrima. Zahtjev se šalje putem RabbitMQ-a, Helper API generiše izvještaj, a desktop aplikacija dobija obavijest o završetku putem SignalR-a.

Izvještaji se mogu pregledati, preuzeti kao PDF dokument i poslati na ispis. Generisani podaci se spremaju u zajednički direktorij:

```text
eAutoShop.Worker/Reports
```

## Sistem preporuke

Sistem preporuke koristi završene narudžbe i obrasce zajedničke kupovine proizvoda. ML.NET model se pokušava trenirati prilikom pokretanja API-ja, a mobilna aplikacija prikazuje do tri povezana proizvoda i razlog svake preporuke.

Detaljan opis nalazi se u dokumentu:

```text
eAutoShop/recommender-dokumentacija.md
```

## Napomene

- Backend mora biti pokrenut prije desktop i mobilne aplikacije.
- `.env` fajlovi se ne smiju commitovati u Git historiju.
- Šifrovane `.env-tajne.zip` arhive raspakuju se na lokacijama na kojima se nalaze.
- Za potpuno ponovno kreiranje baze potrebno je ukloniti SQL Docker volume.
- Nakon promjene JWT ključa potrebno je ponovo izvršiti prijavu u aplikaciju.
