# Dokumentacija sistema preporuke proizvoda

## 1. Namjena sistema

Sistem preporuke u aplikaciji eAutoShop prikazuje personalizovane preporuke na osnovu historije kupovine prijavljenog kupca.

Početni proizvod ne određuje se prema proizvodu koji je trenutno otvoren u mobilnoj aplikaciji. Sistem iz završenih narudžbi prijavljenog kupca nasumično bira jedan prethodno kupljeni proizvod, a zatim pronalazi proizvode koji su se s njim najčešće kupovali.

Osnovni kriterij rangiranja predstavlja stvarni broj zajedničkih kupovina. ML.NET model koristi se kao dopuna kada na osnovu direktnih zajedničkih kupovina nije moguće pronaći tri preporuke.

## 2. Izvor podataka

Sistem koristi podatke iz tabela `Orders` i `OrderItems`.

U obzir se uzimaju samo narudžbe čije je stanje `completed`. Otkazane, odbijene i nezavršene narudžbe ne učestvuju u formiranju preporuka niti u treniranju modela.

Za personalizaciju se prvo pronalaze jedinstveni identifikatori proizvoda iz završenih narudžbi prijavljenog kupca.

Za treniranje ML.NET modela iz svake završene narudžbe izdvajaju se različiti proizvodi i formiraju usmjereni parovi zajedničke kupovine.

Ako narudžba sadrži proizvode A, B i C, formiraju se parovi A-B, A-C, B-A, B-C, C-A i C-B.

Količina istog proizvoda unutar jedne narudžbe ne stvara dodatne parove jer se identifikatori proizvoda filtriraju operacijom `Distinct`.

## 3. Izbor početnog proizvoda

Prijavljeni kupac identifikuje se pomoću identifikatora iz JWT tokena. Klijent ne šalje ID kupca niti ID otvorenog proizvoda.

Iz završenih narudžbi tog kupca učitavaju se svi jedinstveni kupljeni proizvodi. Sistem zatim nasumično bira jedan proizvod koji predstavlja početni kontekst preporuke.

Ako kupac nema nijednu završenu narudžbu ili nema proizvoda u historiji kupovine, sistem vraća praznu listu preporuka.

## 4. Direktne preporuke prema zajedničkim kupovinama

Nakon izbora početnog proizvoda sistem pronalazi sve završene narudžbe koje sadrže taj proizvod.

Za svaki drugi aktivni proizvod računa se broj različitih završenih narudžbi u kojima se pojavio zajedno s početnim proizvodom.

Rezultati se sortiraju:

1. opadajuće prema broju zajedničkih kupovina;
2. prema identifikatoru proizvoda kada više proizvoda ima isti broj zajedničkih kupovina.

Početni proizvod isključuje se iz rezultata. Drugi proizvodi koje je kupac ranije kupio mogu se pojaviti u preporukama ako su se često kupovali zajedno s početnim proizvodom.

Sistem vraća najviše tri preporučena proizvoda.

## 5. ML.NET dopuna preporuka

Ako direktne zajedničke kupovine daju manje od tri rezultata, preostala mjesta dopunjavaju se pomoću ML.NET modela.

Podaci za treniranje predstavljeni su objektima `ProductEntry`, koji sadrže:

- `ProductId` – identifikator početnog proizvoda;
- `CoPurchaseProductId` – identifikator proizvoda kupljenog zajedno s početnim proizvodom;
- `Label` – vrijednost `1`, koja označava evidentiranu zajedničku kupovinu.

Model se trenira pomoću algoritma `MatrixFactorizationTrainer` i funkcije gubitka `SquareLossOneClass`.

Konfiguracija treniranja:

| Parametar | Vrijednost |
|---|---:|
| Alpha | 0.01 |
| Lambda | 0.025 |
| NumberOfIterations | 100 |
| C | 0.00001 |

ML.NET kandidati sortiraju se prema predviđenoj ocjeni. Proizvodi koji su već izabrani direktnim brojanjem ne mogu se ponovo dodati.

Ako ML.NET model nije moguće učitati, greška se evidentira u API logovima, dok direktne preporuke ostaju dostupne.

## 6. Treniranje i čuvanje modela

Treniranje modela zaštićeno je statičkim `SemaphoreSlim` mehanizmom kako se više procesa treniranja ne bi izvršavalo istovremeno.

Ako nema završenih narudžbi s najmanje dva različita proizvoda, model nije moguće trenirati.

Nakon uspješnog treniranja model se čuva u datoteci:

`RecommenderModels/productsmodel.zip`

Direktorij se automatski kreira ako ne postoji.

Prilikom pokretanja glavnog API-ja sistem pokušava trenirati model koristeći trenutne podatke iz baze. Eventualna greška evidentira se u logovima, a ostatak API-ja nastavlja raditi.

Docker konfiguracija mapira direktorij `RecommenderModels`, čime se generisani model čuva izvan životnog ciklusa pojedinačnog kontejnera.

Ručno pokretanje treniranja dostupno je samo korisniku s ulogom menadžera.

## 7. Recommender endpoint

Mobilna aplikacija učitava preporuke putem endpointa:

`GET /Recommender/RecommendProducts`

Endpoint ne prima `productId` ni `customerId`.

Identifikator prijavljenog kupca preuzima se iz JWT tokena. Endpoint je dostupan samo autentifikovanom korisniku s ulogom kupca.

Ovim se sprječava da korisnik zatraži preporuke u ime drugog kupca.

## 8. Objašnjivost preporuka

Svaki preporučeni proizvod sadrži polje `RecommendationReason`.

Za direktne zajedničke kupovine prikazuje se poruka koja navodi:

- naziv preporučenog proizvoda;
- broj zajedničkih kupovina;
- naziv početnog proizvoda iz historije kupca.

Primjer:

> Proizvod „205/55R16 Ljetna Guma“ kupljen je 3 puta zajedno sa proizvodom „5W30 Sintetičko Ulje 1L“ iz vaše historije kupovine.

Za ML.NET dopunu prikazuje se korisniku razumljiva poruka:

> Preporučeno na osnovu proizvoda „Naziv proizvoda“ iz vaše historije kupovine i sličnih kupovina drugih kupaca.

Tehnički naziv ML.NET ne prikazuje se korisniku.

## 9. Integracija s mobilnom aplikacijom

Preporuke se učitavaju prilikom prikaza detalja proizvoda, ali otvoreni proizvod ne utiče na njihov izbor.

Mobilni provider poziva endpoint bez slanja `productId`. Rezultat se prikazuje u sekciji **„Preporučeno za vas“**.

Za svaki rezultat prikazuju se:

- slika proizvoda;
- naziv proizvoda;
- redovna ili snižena cijena;
- razlog preporuke.

Ako kupac nema historiju završenih kupovina ili nema dostupnih kandidata, prikazuje se informativna poruka da trenutno nema preporučenih proizvoda.

## 10. Ograničenja sistema

Kvalitet preporuka zavisi od broja i raznovrsnosti završenih narudžbi.

Kod manjeg broja podataka više proizvoda može imati isti ili veoma mali broj zajedničkih kupovina. ML.NET dopuna u takvim slučajevima može biti manje precizna.

Nasumičan izbor početnog proizvoda znači da isti kupac pri različitim pozivima može dobiti različite preporuke. To je očekivano ponašanje i odgovara algoritmu opisanom u prijavi teme.

Sistem ne koristi historiju pretrage, demografske podatke, podatke o plaćanju niti ručno definisane veze između kategorija proizvoda.

## 11. Privatnost i sigurnost

Za preporuke se koristi samo identifikator prijavljenog kupca kako bi se pronašle njegove završene narudžbe.

Sistem ne obrađuje lozinke, podatke kartice niti druge osjetljive podatke.

Kupac se identifikuje iz važećeg JWT tokena i ne može kroz recommender endpoint poslati proizvoljan identifikator drugog korisnika.

Endpoint za preporuke ograničen je na kupce, dok je endpoint za ručno treniranje modela ograničen na menadžera.

## 12. Zaključak

Recommender sistem aplikacije eAutoShop koristi historiju kupovine prijavljenog kupca kao početni signal.

Iz historije se nasumično bira jedan proizvod, nakon čega se ostali proizvodi prvenstveno rangiraju prema stvarnom broju zajedničkih kupovina u završenim narudžbama.

Ako nema dovoljno direktnih rezultata, lista se dopunjava postojećim ML.NET modelom matrične faktorizacije.