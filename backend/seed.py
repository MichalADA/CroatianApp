import models

ROOMS = [
    {"id": 1, "name": "Korytarz", "description": "Pierwszy krok w nauce. 100 słów i 100 czasowników — fundament języka chorwackiego.", "emoji": "🚪", "color": "#e8c07d"},
    {"id": 2, "name": "Kuchnia", "description": "Kolejny etap nauki. 200 nowych słów związanych z codziennym życiem.", "emoji": "🍳", "color": "#7dc5e8"},
    {"id": 3, "name": "Salon", "description": "Zaawansowane słownictwo. 300 słów do swobodnej rozmowy.", "emoji": "🛋️", "color": "#7de8a8"},
    {"id": 4, "name": "Sypialnia", "description": "Emocje, relacje i życie prywatne. 300 słów.", "emoji": "🛏️", "color": "#e89f7d"},
    {"id": 5, "name": "Biblioteka", "description": "Mistrzostwo języka. 400 słów na najwyższym poziomie.", "emoji": "📚", "color": "#c07de8"},
    {"id": 6, "name": "Miasto", "description": "Język prawdziwego życia. 600 słów do poruszania się po świecie.", "emoji": "🏙️", "color": "#7d9fe8"},
]

WORDS = [
    # zaimki
    ("ja", "ja", "zaimek", 1), ("ty", "ty", "zaimek", 1), ("on", "on", "zaimek", 1),
    ("ona", "ona", "zaimek", 1), ("mi", "my", "zaimek", 1), ("vi", "wy", "zaimek", 1),
    ("oni", "oni", "zaimek", 1),
    # partykuły
    ("da", "tak", "partykuła", 1), ("ne", "nie", "partykuła", 1),
    # zwroty
    ("molim", "proszę", "zwrot", 1), ("hvala", "dziękuję", "zwrot", 1),
    # powitania
    ("zdravo", "cześć", "powitanie", 1), ("dobar dan", "dzień dobry", "powitanie", 1),
    ("dobro jutro", "dzień dobry (rano)", "powitanie", 1),
    ("laku noć", "dobranoc", "powitanie", 1), ("doviđenja", "do widzenia", "powitanie", 1),
    # liczby
    ("jedan", "jeden", "liczba", 1), ("dva", "dwa", "liczba", 1),
    ("tri", "trzy", "liczba", 1), ("četiri", "cztery", "liczba", 1),
    ("pet", "pięć", "liczba", 1), ("deset", "dziesięć", "liczba", 1),
    ("sto", "sto", "liczba", 1),
    # czas
    ("danas", "dzisiaj", "czas", 1), ("sutra", "jutro", "czas", 1),
    ("jučer", "wczoraj", "czas", 1), ("sada", "teraz", "czas", 1),
    ("uvijek", "zawsze", "czas", 1), ("nikad", "nigdy", "czas", 1),
    ("već", "już", "czas", 1), ("dan", "dzień", "czas", 1),
    ("noć", "noc", "czas", 1), ("tjedan", "tydzień", "czas", 1),
    ("mjesec", "miesiąc", "czas", 1), ("godina", "rok", "czas", 1),
    # miejsce
    ("ovdje", "tutaj", "miejsce", 1), ("tamo", "tam", "miejsce", 1),
    ("gore", "góra", "miejsce", 1), ("dolje", "dół", "miejsce", 1),
    ("lijevo", "lewo", "miejsce", 1), ("desno", "prawo", "miejsce", 1),
    # pytajniki
    ("što", "co", "pytajnik", 1), ("tko", "kto", "pytajnik", 1),
    ("gdje", "gdzie", "pytajnik", 1), ("kada", "kiedy", "pytajnik", 1),
    ("zašto", "dlaczego", "pytajnik", 1), ("kako", "jak", "pytajnik", 1),
    ("koliko", "ile", "pytajnik", 1),
    # jedzenie
    ("voda", "woda", "jedzenie", 1), ("hrana", "jedzenie", "jedzenie", 1),
    ("kruh", "chleb", "jedzenie", 1), ("meso", "mięso", "jedzenie", 1),
    ("voće", "owoce", "jedzenie", 1), ("povrće", "warzywa", "jedzenie", 1),
    ("mlijeko", "mleko", "jedzenie", 1), ("kava", "kawa", "jedzenie", 1),
    # dom
    ("kuća", "dom", "dom", 1), ("soba", "pokój", "dom", 1),
    ("vrata", "drzwi", "dom", 1), ("prozor", "okno", "dom", 1),
    ("stol", "stół", "dom", 1), ("stolica", "krzesło", "dom", 1),
    ("krevet", "łóżko", "dom", 1),
    # ludzie
    ("čovjek", "człowiek", "rzeczownik", 1), ("žena", "kobieta", "rzeczownik", 1),
    ("dijete", "dziecko", "rzeczownik", 1), ("prijatelj", "przyjaciel", "rzeczownik", 1),
    ("obitelj", "rodzina", "rzeczownik", 1), ("majka", "mama", "rzeczownik", 1),
    ("otac", "tata", "rzeczownik", 1),
    # transport
    ("auto", "samochód", "transport", 1), ("vlak", "pociąg", "transport", 1),
    ("avion", "samolot", "transport", 1), ("put", "droga", "transport", 1),
    ("grad", "miasto", "transport", 1), ("ulica", "ulica", "transport", 1),
    ("bolnica", "szpital", "rzeczownik", 1), ("škola", "szkoła", "rzeczownik", 1),
    # przymiotniki
    ("dobar", "dobry", "przymiotnik", 1), ("loš", "zły", "przymiotnik", 1),
    ("veliki", "duży", "przymiotnik", 1), ("mali", "mały", "przymiotnik", 1),
    ("nov", "nowy", "przymiotnik", 1), ("star", "stary", "przymiotnik", 1),
    ("lijep", "piękny", "przymiotnik", 1), ("brz", "szybki", "przymiotnik", 1),
    ("spor", "wolny", "przymiotnik", 1), ("važan", "ważny", "przymiotnik", 1),
    # spójniki
    ("i", "i", "spójnik", 1), ("ili", "lub", "spójnik", 1),
    ("ali", "ale", "spójnik", 1), ("jer", "bo", "spójnik", 1),
    ("ako", "jeśli", "spójnik", 1), ("kad", "gdy", "spójnik", 1),
    # inne rzeczowniki
    ("novac", "pieniądze", "rzeczownik", 1), ("posao", "praca", "rzeczownik", 1),
    ("broj", "numer", "rzeczownik", 1), ("ime", "imię", "rzeczownik", 1),
    ("jezik", "język", "rzeczownik", 1), ("zemlja", "kraj", "rzeczownik", 1),
    ("more", "morze", "rzeczownik", 1), ("sunce", "słońce", "rzeczownik", 1),
    ("vrijeme", "pogoda / czas", "rzeczownik", 1), ("knjiga", "książka", "rzeczownik", 1),
]

VERBS = [
    ("biti", "być", "sam", "si", "je", "smo", "ste", "su"),
    ("imati", "mieć", "imam", "imaš", "ima", "imamo", "imate", "imaju"),
    ("ići", "iść", "idem", "ideš", "ide", "idemo", "idete", "idu"),
    ("doći", "przyjść", "dođem", "dođeš", "dođe", "dođemo", "dođete", "dođu"),
    ("vidjeti", "widzieć", "vidim", "vidiš", "vidi", "vidimo", "vidite", "vide"),
    ("govoriti", "mówić", "govorim", "govoriš", "govori", "govorimo", "govorite", "govore"),
    ("znati", "wiedzieć / znać", "znam", "znaš", "zna", "znamo", "znate", "znaju"),
    ("htjeti", "chcieć", "hoću", "hoćeš", "hoće", "hoćemo", "hoćete", "hoće"),
    ("moći", "móc", "mogu", "možeš", "može", "možemo", "možete", "mogu"),
    ("trebati", "potrzebować", "trebam", "trebaš", "treba", "trebamo", "trebate", "trebaju"),
    ("raditi", "pracować / robić", "radim", "radiš", "radi", "radimo", "radite", "rade"),
    ("jesti", "jeść", "jedem", "jedeš", "jede", "jedemo", "jedete", "jedu"),
    ("piti", "pić", "pijem", "piješ", "pije", "pijemo", "pijete", "piju"),
    ("spavati", "spać", "spavam", "spavaš", "spava", "spavamo", "spavate", "spavaju"),
    ("živjeti", "żyć / mieszkać", "živim", "živiš", "živi", "živimo", "živite", "žive"),
    ("kupiti", "kupić", "kupim", "kupiš", "kupi", "kupimo", "kupite", "kupe"),
    ("prodati", "sprzedać", "prodam", "prodaš", "proda", "prodamo", "prodate", "prodaju"),
    ("čitati", "czytać", "čitam", "čitaš", "čita", "čitamo", "čitate", "čitaju"),
    ("pisati", "pisać", "pišem", "pišeš", "piše", "pišemo", "pišete", "pišu"),
    ("slušati", "słuchać", "slušam", "slušaš", "sluša", "slušamo", "slušate", "slušaju"),
    ("gledati", "oglądać / patrzeć", "gledam", "gledaš", "gleda", "gledamo", "gledate", "gledaju"),
    ("učiti", "uczyć się", "učim", "učiš", "uči", "učimo", "učite", "uče"),
    ("putovati", "podróżować", "putujem", "putuješ", "putuje", "putujemo", "putujete", "putuju"),
    ("voziti", "jechać / prowadzić", "vozim", "voziš", "vozi", "vozimo", "vozite", "voze"),
    ("letjeti", "lecieć", "letim", "letiš", "leti", "letimo", "letite", "lete"),
    ("trčati", "biegać", "trčim", "trčiš", "trči", "trčimo", "trčite", "trče"),
    ("hodati", "chodzić", "hodam", "hodaš", "hoda", "hodamo", "hodate", "hodaju"),
    ("sjediti", "siedzieć", "sjedim", "sjediš", "sjedi", "sjedimo", "sjedite", "sjede"),
    ("stajati", "stać", "stojim", "stojiš", "stoji", "stojimo", "stojite", "stoje"),
    ("ležati", "leżeć", "ležim", "ležiš", "leži", "ležimo", "ležite", "leže"),
    ("otvoriti", "otworzyć", "otvorim", "otvoriš", "otvori", "otvorimo", "otvorite", "otvore"),
    ("zatvoriti", "zamknąć", "zatvorim", "zatvoriš", "zatvori", "zatvorimo", "zatvorite", "zatvore"),
    ("uzeti", "wziąć", "uzmem", "uzmeš", "uzme", "uzmemo", "uzmete", "uzmu"),
    ("dati", "dać", "dam", "daš", "da", "damo", "date", "daju"),
    ("primiti", "przyjąć / otrzymać", "primim", "primiš", "primi", "primimo", "primite", "prime"),
    ("naći", "znaleźć", "nađem", "nađeš", "nađe", "nađemo", "nađete", "nađu"),
    ("izgubiti", "zgubić", "izgubim", "izgubiš", "izgubi", "izgubimo", "izgubite", "izgube"),
    ("platiti", "zapłacić", "platim", "platiš", "plati", "platimo", "platite", "plate"),
    ("pitati", "pytać", "pitam", "pitaš", "pita", "pitamo", "pitate", "pitaju"),
    ("odgovoriti", "odpowiedzieć", "odgovorim", "odgovoriš", "odgovori", "odgovorimo", "odgovorite", "odgovore"),
    ("reći", "powiedzieć", "rečem", "rečeš", "reče", "rečemo", "rečete", "reku"),
    ("čuti", "słyszeć", "čujem", "čuješ", "čuje", "čujemo", "čujete", "čuju"),
    ("razumjeti", "rozumieć", "razumijem", "razumiješ", "razumije", "razumijemo", "razumijete", "razumiju"),
    ("misliti", "myśleć", "mislim", "misliš", "misli", "mislimo", "mislite", "misle"),
    ("vjerovati", "wierzyć", "vjerujem", "vjeruješ", "vjeruje", "vjerujemo", "vjerujete", "vjeruju"),
    ("željeti", "pragnąć / chcieć", "želim", "želiš", "želi", "želimo", "želite", "žele"),
    ("voljeti", "kochać / lubić", "volim", "voliš", "voli", "volimo", "volite", "vole"),
    ("mrziti", "nienawidzić", "mrzim", "mrziš", "mrzi", "mrzimo", "mrzite", "mrze"),
    ("početi", "zacząć", "počnem", "počneš", "počne", "počnemo", "počnete", "počnu"),
    ("završiti", "skończyć", "završim", "završiš", "završi", "završimo", "završite", "završe"),
    ("doručkovati", "jeść śniadanie", "doručkujem", "doručkuješ", "doručkuje", "doručkujemo", "doručkujete", "doručkuju"),
    ("ručati", "jeść obiad", "ručam", "ručaš", "ruča", "ručamo", "ručate", "ručaju"),
    ("večerati", "jeść kolację", "večeram", "večeraš", "večera", "večeramo", "večerate", "večeraju"),
    ("kuhati", "gotować", "kuham", "kuhaš", "kuha", "kuhamo", "kuhate", "kuhaju"),
    ("prati", "prać / myć", "perem", "pereš", "pere", "peremo", "perete", "peru"),
    ("čistiti", "czyścić / sprzątać", "čistim", "čistiš", "čisti", "čistimo", "čistite", "čiste"),
    ("kupovati", "kupować", "kupujem", "kupuješ", "kupuje", "kupujemo", "kupujete", "kupuju"),
    ("prodavati", "sprzedawać", "prodajem", "prodaješ", "prodaje", "prodajemo", "prodajete", "prodaju"),
    ("pomagati", "pomagać", "pomažem", "pomažeš", "pomaže", "pomažemo", "pomažete", "pomažu"),
    ("čekati", "czekać", "čekam", "čekaš", "čeka", "čekamo", "čekate", "čekaju"),
    ("dolaziti", "przychodzić", "dolazim", "dolaziš", "dolazi", "dolazimo", "dolazite", "dolaze"),
    ("odlaziti", "odchodzić", "odlazim", "odlaziš", "odlazi", "odlazimo", "odlazite", "odlaze"),
    ("ostati", "zostać", "ostanem", "ostaneš", "ostane", "ostanemo", "ostanete", "ostanu"),
    ("vraćati se", "wracać", "vraćam se", "vraćaš se", "vraća se", "vraćamo se", "vraćate se", "vraćaju se"),
    ("sjećati se", "pamiętać", "sjećam se", "sjećaš se", "sjeća se", "sjećamo se", "sjećate se", "sjećaju se"),
    ("zaboraviti", "zapomnieć", "zaboravim", "zaboraviš", "zaboravi", "zaboravimo", "zaboravite", "zaborave"),
    ("naučiti", "nauczyć się", "naučim", "naučiš", "nauči", "naučimo", "naučite", "nauče"),
    ("objasniti", "wyjaśnić", "objasnim", "objasniš", "objasni", "objasnimo", "objasnite", "objasne"),
    ("pokazati", "pokazać", "pokažem", "pokažeš", "pokaže", "pokažemo", "pokažete", "pokažu"),
    ("čuvati", "dbać / przechowywać", "čuvam", "čuvaš", "čuva", "čuvamo", "čuvate", "čuvaju"),
    ("brinuti se", "martwić się", "brinem se", "brineš se", "brine se", "brinemo se", "brinete se", "brinu se"),
    ("smijati se", "śmiać się", "smijem se", "smiješ se", "smije se", "smijemo se", "smijete se", "smiju se"),
    ("plakati", "płakać", "plačem", "plačeš", "plače", "plačemo", "plačete", "plaču"),
    ("pjevati", "śpiewać", "pjevam", "pjevaš", "pjeva", "pjevamo", "pjevate", "pjevaju"),
    ("plesati", "tańczyć", "plešem", "plešeš", "pleše", "plešemo", "plešete", "plešu"),
    ("igrati", "grać / bawić się", "igram", "igraš", "igra", "igramo", "igrate", "igraju"),
    ("spremati", "przygotowywać / sprzątać", "spreman", "spremaš", "sprema", "spremamo", "spremate", "spremaju"),
    ("otputovati", "wyjechać", "otputujem", "otputuješ", "otputuje", "otputujemo", "otputujete", "otputuju"),
    ("rezervirati", "rezerwować", "rezerviram", "rezerviraš", "rezervira", "rezerviramo", "rezervirate", "rezerviraju"),
    ("posjetiti", "odwiedzić", "posjetim", "posjetiš", "posjeti", "posjetimo", "posjetite", "posjete"),
    ("bolovati", "chorować", "bolujem", "boluješ", "boluje", "bolujemo", "bolujete", "boluju"),
    ("liječiti", "leczyć", "liječim", "liječiš", "liječi", "liječimo", "liječite", "liječe"),
    ("zvati", "dzwonić / wołać", "zovem", "zoveš", "zove", "zovemo", "zovete", "zovu"),
    ("slati", "wysyłać", "šaljem", "šalješ", "šalje", "šaljemo", "šaljete", "šalju"),
    ("primati", "otrzymywać", "primam", "primaš", "prima", "primamo", "primate", "primaju"),
    ("otkazati", "odwołać", "otkažem", "otkažeš", "otkaže", "otkažemo", "otkažete", "otkaže"),
    ("naručiti", "zamówić", "naručim", "naručiš", "naruči", "naručimo", "naručite", "naruče"),
    ("tražiti", "szukać / prosić", "tražim", "tražiš", "traži", "tražimo", "tražite", "traže"),
    ("nalaziti se", "znajdować się", "nalazim se", "nalaziš se", "nalazi se", "nalazimo se", "nalazite se", "nalaze se"),
    ("sviđati se", "podobać się", "sviđa mi se", "sviđa ti se", "sviđa mu se", "sviđa nam se", "sviđa vam se", "sviđa im se"),
    ("radovati se", "cieszyć się", "radujem se", "raduješ se", "raduje se", "radujemo se", "radujete se", "raduju se"),
    ("birati", "wybierać", "biram", "biraš", "bira", "biramo", "birate", "biraju"),
    ("mijenjati", "zmieniać", "mijenjam", "mijenjaaš", "mijenja", "mijenjamo", "mijenjate", "mijenjaju"),
    ("roditi se", "urodzić się", "rodim se", "rodiš se", "rodi se", "rodimo se", "rodite se", "rode se"),
    ("vjenčati se", "pobrać się", "vjenčam se", "vjenčaš se", "vjenča se", "vjenčamo se", "vjenčate se", "vjenčaju se"),
    ("biti gladan", "być głodnym", "gladan sam", "gladan si", "gladan je", "gladni smo", "gladni ste", "gladni su"),
    ("biti žedan", "być spragnionym", "žedan sam", "žedan si", "žedan je", "žedni smo", "žedni ste", "žedni su"),
    ("zvučati", "brzmieć", "zvučim", "zvučiš", "zvuči", "zvučimo", "zvučite", "zvuče"),
]


def run(db):
    for r in ROOMS:
        room = models.Room(**r)
        db.add(room)
    db.flush()

    for (cr, pl, cat, diff) in WORDS:
        db.add(models.Word(room_id=1, croatian=cr, polish=pl, category=cat, difficulty=diff))

    for v in VERBS:
        db.add(models.Verb(
            room_id=1,
            infinitive=v[0], polish=v[1],
            conj_ja=v[2], conj_ti=v[3], conj_on=v[4],
            conj_mi=v[5], conj_vi=v[6], conj_oni=v[7],
        ))

    db.commit()
    print("✅ Seed loaded: 4 rooms, 100 words, 100 verbs")
