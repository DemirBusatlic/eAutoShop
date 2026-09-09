Dokumentacija sistema preporuke proizvoda

1. Namjena sistema

Sistem preporuke u aplikaciji eAutoShop korisniku prikazuje proizvode koji se često pojavljuju u zajedničkim kupovinama s trenutno odabranim proizvodom. Cilj je olakšati pronalazak povezanih proizvoda i unaprijediti korisničko iskustvo mobilne aplikacije.

Sistem je implementiran korištenjem ML.NET biblioteke i algoritma matrične faktorizacije. Preporuke nisu zasnovane na ručno definisanim vezama između proizvoda, nego na stvarnim podacima iz završenih narudžbi.

2. Izvor podataka

Za treniranje modela koriste se podaci iz tabela Orders i OrderItems.

U obzir se uzimaju samo narudžbe čije je stanje completed. Narudžbe koje su odbijene, otkazane, nisu plaćene ili još nisu završene ne učestvuju u treniranju modela.

Za svaku završenu narudžbu izdvajaju se jedinstveni identifikatori kupljenih proizvoda. Ako narudžba sadrži najmanje dva različita proizvoda, od njih se formiraju parovi zajedničke kupovine.

Primjer: ako jedna završena narudžba sadrži proizvode A, B i C, formiraju se parovi A-B, A-C, B-A, B-C, C-A i C-B. Svaki par predstavlja pozitivan primjer zajedničke kupovine.

Količina istog proizvoda unutar jedne narudžbe ne stvara duplikate jer se identifikatori proizvoda prije formiranja parova filtriraju korištenjem operacije Distinct.

3. Treniranje modela

Podaci za treniranje predstavljeni su objektima ProductEntry, koji sadrže:

ProductId - identifikator početnog proizvoda;

CoPurchaseProductId - identifikator proizvoda kupljenog zajedno s početnim proizvodom;

Label - vrijednost 1, koja označava zabilježenu zajedničku kupovinu.

Model se trenira pomoću ML.NET MatrixFactorizationTrainer algoritma. Koristi se SquareLossOneClass funkcija gubitka, pogodna za podatke u kojima su evidentirane pozitivne interakcije, odnosno zajedničke kupovine.

Konfiguracija algoritma u implementaciji koristi sljedeće vrijednosti:

Parametar

Vrijednost

Alpha

0.01

Lambda

0.025

NumberOfIterations

100

C

0.00001

Treniranje je zaštićeno statičkim SemaphoreSlim mehanizmom kako se više procesa treniranja ne bi izvršavalo istovremeno.

Ako ne postoji nijedna završena narudžba ili nema narudžbi s najmanje dva različita proizvoda, model se ne može trenirati i aplikacija vraća odgovarajuću korisničku poruku.

4. Čuvanje i pokretanje modela

Nakon uspješnog treniranja ML.NET model se čuva u fajlu:

RecommenderModels/productsmodel.zip

Direktorij se automatski kreira ako ne postoji.

Prilikom pokretanja glavnog API-ja sistem automatski pokušava trenirati novi model koristeći trenutne podatke iz baze. Ako treniranje ne uspije, greška se evidentira putem loggera, a API nastavlja s radom kako nedostupan recommender ne bi onemogućio ostale funkcionalnosti aplikacije.

Docker konfiguracija mapira direktorij RecommenderModels, čime se omogućava čuvanje generisanog modela izvan životnog ciklusa pojedinačnog kontejnera.

5. Generisanje preporuka

Mobilna aplikacija traži preporuke za konkretan proizvod putem endpointa:

GET /Recommender/RecommendProducts/{productId}

Prije predikcije provjerava se da traženi proizvod postoji i da je u aktivnom stanju. Nakon toga se učitava sačuvani ML.NET model i svi ostali aktivni proizvodi.

Za svaki aktivni proizvod, osim trenutno odabranog, model izračunava rezultat povezanosti sa početnim proizvodom. Kandidati se sortiraju opadajuće prema izračunatom rezultatu, nakon čega se vraćaju najviše tri najbolje preporuke.

Neaktivni proizvodi i proizvod za koji se preporuke traže ne mogu se pojaviti među rezultatima.

6. Objašnjivost preporuka

Svaki preporučeni proizvod sadrži polje RecommendationReason. Korisniku se u mobilnoj aplikaciji prikazuje poruka:

Preporučeno na osnovu obrazaca zajedničke kupovine sa proizvodom „Naziv proizvoda“.

Na taj način korisnik dobija jasno objašnjenje zbog čega je određeni proizvod preporučen. Preporuka se ne prikazuje kao proizvoljan rezultat, nego se direktno povezuje s obrascima stvarnih završenih kupovina.

7. Integracija s mobilnom aplikacijom

Preporuke se učitavaju prilikom prikaza detalja proizvoda. Mobilni provider poziva recommender endpoint i rezultat sprema kao listu preporučenih proizvoda.

Za svaki rezultat prikazuju se:

slika proizvoda;

naziv proizvoda;

redovna ili snižena cijena;

razlog preporuke.

Ako preporuke nisu dostupne ili lista nema rezultata, korisniku se prikazuje informativna poruka da trenutno nema preporučenih proizvoda.

8. Ograničenja sistema

Kvalitet preporuka zavisi od broja i raznovrsnosti završenih narudžbi. Kod manjeg broja podataka rezultati mogu biti manje precizni. Novi proizvodi koji se još nisu pojavljivali u zajedničkim kupovinama nemaju dovoljno historijskih podataka za kvalitetno rangiranje.

Trenutna implementacija predstavlja item-to-item sistem zasnovan na zajedničkim kupovinama. Model ne koristi lične karakteristike korisnika, historiju pretrage, demografske podatke niti ručno definisane kategorijske veze.

Sistem trenutno nema poseban fallback algoritam zasnovan na popularnosti. Ako model nije moguće učitati ili predikcija ne uspije, korisniku se vraća kontrolisana poruka da sistem preporuke trenutno nije dostupan.

9. Privatnost i sigurnost

Za treniranje se koriste identifikatori proizvoda i veze nastale iz završenih narudžbi. Model ne obrađuje lozinke, podatke o plaćanju niti druge osjetljive korisničke podatke.

Endpointi recommender sistema zahtijevaju autentifikovanog korisnika. Greške pri učitavanju ili korištenju modela pretvaraju se u kontrolisane korisničke poruke, bez izlaganja internih detalja sistema.

10. Zaključak

Recommender sistem aplikacije eAutoShop koristi stvarne završene narudžbe kako bi naučio obrasce zajedničke kupovine proizvoda. ML.NET model matrične faktorizacije rangira aktivne proizvode i vraća tri najrelevantnija rezultata. Mobilna aplikacija uz svaki rezultat prikazuje i objašnjenje preporuke, čime je korisniku jasno predstavljen razlog izbora proizvoda.