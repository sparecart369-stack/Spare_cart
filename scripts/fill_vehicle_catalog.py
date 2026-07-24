#!/usr/bin/env python3
"""Fill missing vehicle models in vehicle_catalog.json from Wikipedia."""

from __future__ import annotations

import json
import re
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "assets/data/vehicle_catalog.json"
API = "https://en.wikipedia.org/w/api.php"

MANUAL_MODELS: dict[str, list[str]] = {
    "Maruti Suzuki": [
        "800", "1000", "Alto", "Alto 800", "Alto K10", "A-Star", "Baleno", "Baleno Altura",
        "Baleno RS", "Brezza", "Celerio", "Ciaz", "Dzire", "Eeco", "Ertiga", "Esteem",
        "Estilo", "e Vitara", "Fronx", "Grand Vitara", "Grand Vitara XL-7", "Gypsy",
        "Gypsy E", "Gypsy King", "Ignis", "Invicto", "Jimny", "Kizashi", "Omni", "Ritz",
        "S-Cross", "S-Presso", "Stingray", "Super Carry", "Swift", "Swift Dzire", "SX4",
        "Versa", "Victoris", "Vitara Brezza", "Wagon R", "XL6", "Zen", "Zen Estilo",
    ],
    "Maruti": ["Maruti prototype"],
    "Tata Motors": [
        "Altroz", "Aria", "Bolt", "Curvv", "Curvv.ev", "Estate", "Harrier", "Harrier.ev",
        "Hexa", "Indica", "Indigo", "Indigo Marina", "Manza", "Nano", "Nexon", "Nexon.ev",
        "Punch", "Punch.ev", "Safari", "Sierra", "Sierra.ev", "Spacio", "Sumo",
        "Sumo Grande", "Telcoline", "Tiago", "Tiago.ev", "Tigor", "Tigor.ev", "Venture",
        "Vista", "Xenon", "Zest",
    ],
    "Mahindra & Mahindra": [
        "Alturas G4", "BE 6", "Bolero", "Bolero Neo", "KUV100", "Marazzo", "Quanto",
        "Roxor", "Scorpio", "Scorpio Classic", "Scorpio Getaway", "Scorpio-N", "Thar",
        "Thar Roxx", "TUV300", "Verito", "XEV 9e", "XEV 9S", "XUV300", "XUV 3XO",
        "XUV 3XO EV", "XUV500", "XUV700", "XUV 7XO",
    ],
    "Mahindra": [
        "Alturas G4", "BE 6", "Bolero", "Bolero Neo", "KUV100", "Marazzo", "Quanto",
        "Roxor", "Scorpio", "Scorpio Classic", "Scorpio Getaway", "Scorpio-N", "Thar",
        "Thar Roxx", "TUV300", "Verito", "XEV 9e", "XEV 9S", "XUV300", "XUV3OO",
        "XUV 3XO", "XUV 3XO EV", "XUV500", "XUV700", "XUV 7XO",
    ],
    "Tesla": [
        "Cybertruck", "Model 3", "Model S", "Model X", "Model Y", "Roadster", "Semi",
    ],
    "Land Rover": [
        "Defender", "Discovery", "Discovery Sport", "Freelander", "Freelander 2",
        "Range Rover", "Range Rover Classic", "Range Rover Evoque", "Range Rover Sport",
        "Range Rover Velar", "Series I", "Series II", "Series III",
    ],
    "Jaguar": [
        "E-Pace", "F-Pace", "F-Type", "I-Pace", "S-Type", "X-Type", "XE", "XF", "XJ", "XK",
    ],
    "Jeep": [
        "Cherokee", "Commander", "Compass", "Gladiator", "Grand Cherokee", "Grand Wagoneer",
        "Liberty", "Patriot", "Renegade", "Wagoneer", "Wrangler",
    ],
    "Mini": [
        "Clubman", "Convertible", "Cooper", "Countryman", "Coupe", "Paceman", "Roadster",
    ],
    "Bentley": [
        "Arnage", "Azure", "Bentayga", "Brooklands", "Continental", "Continental Flying Spur",
        "Continental GT", "Flying Spur", "Mulsanne", "Turbo R",
    ],
    "Rolls-Royce": [
        "Corniche", "Cullinan", "Dawn", "Ghost", "Phantom", "Silver Cloud", "Silver Shadow",
        "Silver Spirit", "Silver Spur", "Spectre", "Wraith",
    ],
    "McLaren": [
        "540C", "570GT", "570S", "600LT", "620R", "650S", "675LT", "720S", "765LT", "Artura",
        "Elva", "F1", "GT", "MP4-12C", "P1", "Senna", "Speedtail",
    ],
    "Bugatti": [
        "Chiron", "Divo", "EB 110", "Type 35", "Type 57", "Veyron",
    ],
    "Lotus": [
        "Elan", "Elise", "Emira", "Esprit", "Europa", "Evija", "Evora", "Exige",
    ],
    "Peugeot": [
        "104", "106", "107", "108", "2008", "205", "206", "207", "208", "3008", "301", "306",
        "307", "308", "309", "4007", "4008", "405", "406", "407", "408", "5008", "504", "505",
        "508", "604", "605", "607", "806", "807", "Partner", "RCZ", "Rifter", "Traveller",
    ],
    "Proton": [
        "Arena", "Exora", "Gen-2", "Inspira", "Iriz", "Perdana", "Persona", "Preve", "Putra",
        "Saga", "Satria", "Savvy", "Tiara", "Waja", "Wira", "X50", "X70",
    ],
    "Perodua": [
        "Alza", "Aruz", "Ativa", "Axia", "Bezza", "Kancil", "Kelisa", "Kembara", "Kenari",
        "Myvi", "Nautica", "Rusa", "Viva",
    ],
    "Datsun": [
        "1000", "1200", "1600", "200B", "240Z", "260Z", "280Z", "280ZX", "510", "620", "720",
        "Bluebird", "Go", "Go+", "Laurel", "Mi-Do", "on-DO", "Stanza", "Sunny", "Urvan",
    ],
    "Smart": [
        "Forfour", "Fortwo", "Roadster",
    ],
    "Alpine": [
        "A110", "A310", "A610", "GTA",
    ],
    "Abarth": [
        "500", "595", "695", "Grande Punto", "Punto", "Punto Evo", "Ritmo", "Seicento",
    ],
    "Aston Martin": [
        "DB1", "DB2", "DB2/4", "DB4", "DB4 GT Zagato", "DB5", "DB6", "DB7", "DB9", "DB11", "DB12",
        "DBS", "DBS Superleggera", "DBX", "Lagonda", "One-77", "Rapide", "V8", "V8 Vantage",
        "V12 Vanquish", "Vanquish", "Vantage", "Virage", "Cygnet", "Valkyrie", "Valhalla", "Vulcan",
    ],
    "Force Motors": [
        "Citiline", "Gurkha", "Kargo King", "Matador", "Minidor", "Monobus", "Shaktiman", "Tempo Hanseat",
        "Tempo Traveller", "Trax", "Trax Cruiser", "Trax Delivery Van", "Traveller", "Urbania",
    ],
    "Hindustan Motors": [
        "Ambassador", "Baby Hindustan", "Contessa", "Deluxe", "Landmaster", "Lavender", "MASCOT",
        "Porter", "Pushpak", "RTV Ranger", "Trekker", "Winner", "10", "14", "122",
    ],
    "Premier": [
        "118NE", "Padmini", "RiO", "Sigma",
    ],
    "Ashok Leyland": [
        "Boss", "Captain", "Dost", "Ecomet", "Guru", "JanBus", "MiTR", "Partner", "Stile", "U-Truck",
    ],
    "Fiat": [
        "1100", "124", "124 Spider", "126", "127", "128", "130", "131", "132", "500",
        "500L", "500X", "600", "850", "Albea", "Argenta", "Barchetta", "Brava", "Bravo",
        "Cinquecento", "Coupe", "Croma", "Doblo", "Ducato", "Duna", "Fiorino", "Freemont",
        "Fullback", "Grande Punto", "Idea", "Linea", "Marea", "Multipla", "Palio", "Panda",
        "Punto", "Qubo", "Regata", "Ritmo", "Scudo", "Sedici", "Seicento", "Siena",
        "Stilo", "Strada", "Talento", "Tempra", "Tipo", "Ulysse", "Uno", "X1/9",
    ],
}

PAGE_OVERRIDES: dict[str, str] = {
    "Tata Motors": "Tata Motors Passenger Vehicles",
    "Tata": "Tata Motors Passenger Vehicles",
    "Mahindra": "Mahindra & Mahindra",
    "Maruti Suzuki": "Maruti Suzuki",
    "Tesla": "Tesla, Inc.",
    "Land Rover": "Land Rover",
    "Jaguar": "Jaguar Cars",
    "Mini": "Mini (marque)",
    "Smart": "Smart (marque)",
    "Alpine": "Alpine (automobile)",
    "Rolls-Royce": "Rolls-Royce Motor Cars",
    "McLaren": "McLaren Automotive",
    "Lotus": "Lotus Cars",
    "Lucid": "Lucid Motors",
    "Polestar": "Polestar",
    "Proton": "Proton Holdings",
    "Perodua": "Perodua",
    "Datsun": "Datsun",
    "Force": "Force Motors",
    "Bajaj": "Bajaj Auto",
    "Jeep": "Jeep",
    "Peugeot": "Peugeot",
    "Bentley": "Bentley",
    "Bugatti": "Bugatti",
    "Lamborghini": "Lamborghini",
    "Ferrari": "Ferrari",
    "Aston Martin": "Aston Martin",
    "Alfa Romeo": "Alfa Romeo",
    "Abarth": "Abarth",
    "Lancia": "Lancía",
    "Maserati": "Maserati",
    "Renault": "Renault",
    "Citroën": "Citroën",
    "DS Automobiles": "DS Automobiles",
    "Opel": "Opel",
    "Vauxhall": "Vauxhall",
    "SEAT": "SEAT",
    "Cupra": "Cupra (marque)",
    "Skoda": "Škoda Auto",
    "Volkswagen": "Volkswagen",
    "Audi": "Audi",
    "Porsche": "Porsche",
    "BMW": "BMW",
    "Mercedes-Benz": "Mercedes-Benz",
    "Volvo": "Volvo Cars",
    "Saab": "Saab Automobile",
    "Genesis": "Genesis Motor",
    "Hyundai": "Hyundai Motor Company",
    "Kia": "Kia",
    "Honda": "Honda",
    "Toyota": "Toyota",
    "Nissan": "Nissan",
    "Mazda": "Mazda",
    "Mitsubishi": "Mitsubishi Motors",
    "Mitsubishi Motors": "Mitsubishi Motors",
    "Subaru": "Subaru",
    "Suzuki": "Suzuki",
    "Isuzu": "Isuzu",
    "Daihatsu": "Daihatsu",
    "Lexus": "Lexus",
    "Infiniti": "Infiniti",
    "Acura": "Acura",
    "Cadillac": "Cadillac",
    "Chevrolet": "Chevrolet",
    "GMC": "GMC",
    "Buick": "Buick",
    "Ford": "Ford Motor Company",
    "Chrysler": "Chrysler",
    "Dodge": "Dodge",
    "Ram": "Ram Trucks",
    "Jeep": "Jeep",
    "Rivian": "Rivian",
    "Lucid": "Lucid Motors",
    "BYD Auto": "BYD Auto",
    "Geely": "Geely",
    "Chery": "Chery",
    "Great Wall Motor": "Great Wall Motor",
    "Haval": "Haval (marque)",
    "MG": "MG Motor",
    "BAIC": "BAIC Group",
    "Nio": "Nio Inc.",
    "Xpeng": "XPeng",
    "Li Auto": "Li Auto",
    "Zeekr": "Zeekr",
    "Tata": "Tata Motors Passenger Vehicles",
}

MAKE_ALIASES: dict[str, str] = {
    "Great Wall Motor": "Great Wall Motor",
    "Skoda": "Škoda",
    "BAIC": "BAIC Group",
}

SKIP_TITLES = {
    "List of car brands", "List of best-selling automobiles", "List of badge-engineered vehicles",
    "List of fictional cars", "List of fictional vehicles", "List of sport utility vehicles",
    "List of sports cars", "List of rally cars", "List of diesel automobiles",
    "List of battery electric vehicles", "List of fuel cell vehicles", "List of fastback automobiles",
    "List of prototype solar-powered cars", "List of carbon fiber monocoque cars",
    "List of hydrogen internal combustion engine vehicles", "List of production cars by power output",
    "List of fastest production cars by acceleration", "List of most expensive cars sold at auction",
    "List of longest consumer road vehicles", "List of automobiles notable for negative reception",
    "List of the United States military vehicles by model number",
    "List of countries and territories by motor vehicles per capita",
    "List of automobile sales by model", "List of automobile drag coefficients",
    "List of automobile manufacturers of Europe", "List of cars with non-standard door designs",
    "List of coupé convertibles", "List of vans", "List of steam car makers",
    "List of Mini-based cars", "Car collection of the 29th Sultan of Brunei", "Toyota Fine",
}

NOISE_WORDS = {
    "Automotive", "Automobile", "Vehicle", "Vehicles", "Cars", "Companies", "Company",
    "Motors", "Motor", "Group", "Limited", "Ltd", "Inc", "Pvt", "Commercial", "Passenger",
    "Hatchback", "Sedan", "SUV", "Crossover", "MPV", "Van", "Pickup", "Truck", "Wagon",
    "City car", "Subcompact", "Compact", "Mid-size", "Full-size", "Microvan", "Timeline",
    "Models", "Current models", "Discontinued models", "Former models", "Concept cars",
    "Production", "Introduction", "Overview", "Manufacturer", "Assembly", "Global", "Entry",
    "Off", "Japan", "India", "China", "Europe", "Asia", "Africa", "Australia", "Canada",
    "Brazil", "Mexico", "Taiwan", "Pakistan", "Indonesia", "Philippines", "Thailand",
    "Malaysia", "Vietnam", "Uzbekistan", "Nepal", "Sri Lanka", "Kenya", "Tunisia",
    "Algeria", "Benin", "Gambia", "Ghana", "Nigeria", "Chad", "Mali", "South Africa",
    "Detroit", "Brisbane", "Houston", "California", "Pennsylvania", "Small commercial vehicles",
    "Passenger cars", "CKD kits", "Automotive parts", "multinational", "Aerostructures",
    "Armoured", "Division", "Auto Show", "cherry picker", "hydraulic platforms",
}

CATEGORY_LINE = re.compile(
    r"^(Hatchback|Sedan|Wagon|Estate|Coupe|Coupé|Convertible|Roadster|SUV|Crossover|"
    r"MPV|Van|Pickup|Truck|City car|Subcompact|Compact|Mid-size|Full-size|"
    r"Microvan|Off-Road SUV|Electric vehicles|ICE vehicles|Current models|"
    r"Discontinued models|Historic models|Concept cars|Production models|"
    r"Current production models|Former production models|Automobiles|Models|SUV/ crossover)$",
    re.I,
)

TABLE_MODEL_ROW = re.compile(
    r"^\|\s*(?:\[\[[^\]|]+\|([^\]|]+)\]\]|([^|\n]+?))\s*\|\s*\d{4}",
    re.M,
)

TABLE_DISCONTINUED_ROW = re.compile(
    r"^\|\s*(?:\[\[[^\]|]+\|([^\]|]+)\]\]|([^|\n]+?))\s*\|\s*\d{4}\s*\|\s*\d{4}",
    re.M,
)

TABLE_CURRENT_ROW = re.compile(
    r"^\|\s*\|\s*(?:\[\[[^\]|]+\|([^\]|]+)\]\]|([^|\n]+?))\s*\|\s*\d{4}",
    re.M,
)

TIMELINE_LINK = re.compile(r"\[\[[^\]|]+?\|([^\]|#]+?)\]\]")

IMAGE_NOISE = re.compile(r"\d+\s*px|\d+x\d+px|^\d{4,}$")


def api_get(params: dict, retries: int = 6) -> dict | None:
    query = urllib.parse.urlencode(params)
    url = f"{API}?{query}"
    req = urllib.request.Request(url, headers={"User-Agent": "SpareKartCatalogBot/1.0"})
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                time.sleep(0.2)
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as exc:
            if exc.code == 429 and attempt < retries - 1:
                time.sleep(min(30, 2 ** (attempt + 2)))
                continue
            print(f"  API error {exc.code} for {params.get('page', params)}", flush=True)
            return None
        except urllib.error.URLError as exc:
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
                continue
            print(f"  Network error: {exc}", flush=True)
            return None
    return None


def fetch_wikitext(title: str, section: int | None = None) -> str | None:
    params = {
        "action": "parse",
        "page": title,
        "prop": "wikitext",
        "format": "json",
        "redirects": 1,
    }
    if section is not None:
        params["section"] = section
    data = api_get(params)
    if not data or "error" in data:
        return None
    return data["parse"]["wikitext"]["*"]


def fetch_sections(title: str) -> list[dict]:
    data = api_get({"action": "parse", "page": title, "prop": "sections", "format": "json"})
    if not data or "error" in data:
        return []
    return data["parse"].get("sections", [])


def search_page(query: str) -> str | None:
    data = api_get(
        {
            "action": "query",
            "list": "search",
            "srsearch": query,
            "srlimit": 5,
            "format": "json",
        }
    )
    if not data:
        return None
    for item in data.get("query", {}).get("search", []):
        return item["title"]
    return None


def clean_raw_name(raw: str) -> str:
    name = raw.strip()
    name = re.sub(r"\s+", " ", name)
    name = name.replace("'''", "").replace("''", "")
    name = re.sub(r"<[^>]+>", "", name)
    name = re.sub(r"\s*\([^)]*\)\s*$", "", name).strip()
    return name


def normalize_model(name: str, make: str) -> str | None:
    name = clean_raw_name(name)
    if not name or len(name) < 2 or len(name) > 60:
        return None
    if CATEGORY_LINE.match(name) or name in NOISE_WORDS:
        return None
    if IMAGE_NOISE.search(name):
        return None
    if re.search(r"\b(version|only|market|produced|did not|etc|show|division)\b", name, re.I):
        return None
    if not re.search(r"[A-Za-z]", name):
        return None
    if re.fullmatch(r"\d+", name) and name not in {"800", "1000", "124", "126", "127", "128", "130", "131", "132", "500", "600", "850"}:
        return None

    if " – " in name or " - " in name:
        name = re.split(r"\s[–-]\s", name, maxsplit=1)[0].strip()

    for prefix in (make, make.replace("-", " "), make.split()[0] if make else ""):
        if prefix and name.lower().startswith(prefix.lower() + " "):
            name = name[len(prefix) :].strip()
            break

    if name.lower() in {"car", "timeline", "models", "automobile", "vehicle", "sport"}:
        return None
    return name


def extract_from_tables(wikitext: str, make: str) -> set[str]:
    models: set[str] = set()
    for pattern in (TABLE_CURRENT_ROW, TABLE_DISCONTINUED_ROW, TABLE_MODEL_ROW):
        for match in pattern.finditer(wikitext):
            raw = match.group(1) or match.group(2)
            model = normalize_model(raw, make)
            if model:
                models.add(model)
    return models


def extract_from_timeline(wikitext: str, make: str) -> set[str]:
    models: set[str] = set()
    for match in TIMELINE_LINK.finditer(wikitext):
        model = normalize_model(match.group(1), make)
        if model:
            models.add(model)
    return models


def extract_from_gallery(wikitext: str, make: str) -> set[str]:
    models: set[str] = set()
    for match in re.finditer(r"\[\[[^\]|]+?\|([^\]|#]+?)\]\]\s*\(", wikitext):
        model = normalize_model(match.group(1), make)
        if model:
            models.add(model)
    return models


def extract_from_list_tables(wikitext: str, make: str) -> set[str]:
    models: set[str] = set()
    for match in re.finditer(r"!\s*\[\[[^\]|]+?\|([^\]|#]+?)\]\]", wikitext):
        model = normalize_model(match.group(1), make)
        if model:
            models.add(model)
    for match in re.finditer(r"!\s*\[\[([^\]|#]+?)\]\]", wikitext):
        model = normalize_model(match.group(1), make)
        if model:
            models.add(model)
    return models


def extract_all(wikitext: str, make: str) -> set[str]:
    models = set()
    models |= extract_from_tables(wikitext, make)
    models |= extract_from_timeline(wikitext, make)
    models |= extract_from_gallery(wikitext, make)
    models |= extract_from_list_tables(wikitext, make)
    return models


def list_page_candidates(make: str) -> list[str]:
    wiki_make = MAKE_ALIASES.get(make, make)
    return [
        f"List of {wiki_make} vehicles",
        f"List of {wiki_make} automobiles",
        f"List of {wiki_make} cars",
        f"List of {wiki_make} road cars",
        f"List of {wiki_make} passenger cars",
        f"List of {wiki_make} motor vehicles",
    ]


def timeline_candidates(make: str) -> list[str]:
    slug = make.replace(" ", "_")
    return [
        f"Template:{make} timeline",
        f"Template:{make} road car timeline",
        f"Template:{slug} timeline",
        f"Template:{slug} road car timeline",
    ]


def model_section_indices(title: str) -> list[int]:
    sections = fetch_sections(title)
    indices: list[int] = []
    for section in sections:
        line = section.get("line", "")
        if re.search(
            r"(current models|discontinued models|former models|list of .* models|"
            r"production models|automobiles|vehicle lineup|model range|passenger cars|"
            r"automotive products|available products|discontinued vehicles|products)",
            line,
            re.I,
        ):
            indices.append(int(section["index"]))
    return indices


def resolve_redirect(title: str) -> str:
    wikitext = fetch_wikitext(title)
    if wikitext and wikitext.startswith("#REDIRECT"):
        target = re.search(r"#REDIRECT\s*\[\[([^\]|#]+)", wikitext)
        if target:
            return target.group(1)
    return title


def fetch_models_for_make(make: str, list_pages: dict[str, str]) -> list[str]:
    if make in MANUAL_MODELS:
        return sorted(set(MANUAL_MODELS[make]), key=str.lower)

    models: set[str] = set()

    def ingest(title: str, section: int | None = None) -> None:
        wikitext = fetch_wikitext(title, section=section)
        if wikitext:
            models.update(extract_all(wikitext, make))

    # 1) Dedicated page override (best quality).
    if make in PAGE_OVERRIDES:
        page = resolve_redirect(PAGE_OVERRIDES[make])
        sections = model_section_indices(page)
        if sections:
            for index in sections[:3]:
                ingest(page, index)
        else:
            ingest(page)
        if len(models) >= 2:
            return sorted(models, key=str.lower)

    # 2) Known Wikipedia list page.
    if make in list_pages:
        ingest(resolve_redirect(list_pages[make]))
        if len(models) >= 2:
            return sorted(models, key=str.lower)

    # 3) One list-page title guess.
    for candidate in list_page_candidates(make)[:2]:
        wikitext = fetch_wikitext(candidate)
        if wikitext and not wikitext.startswith("#REDIRECT [[Category:"):
            found = extract_all(wikitext, make)
            if len(found) >= 2:
                models.update(found)
                break

    # 4) One timeline template guess.
    if len(models) < 2:
        for candidate in timeline_candidates(make)[:1]:
            wikitext = fetch_wikitext(candidate)
            if wikitext:
                models.update(extract_from_timeline(wikitext, make))
                break

    # 5) Manufacturer page, first model section only.
    if len(models) < 2:
        page = resolve_redirect(make)
        sections = model_section_indices(page)
        if sections:
            ingest(page, sections[0])
        else:
            ingest(page)

    return sorted({m for m in models if m}, key=str.lower)


def build_list_page_mapping() -> dict[str, str]:
    mapping: dict[str, str] = {}
    continue_token: str | None = None

    while True:
        params = {
            "action": "query",
            "list": "categorymembers",
            "cmtitle": "Category:Lists_of_cars",
            "cmlimit": "500",
            "format": "json",
        }
        if continue_token:
            params["cmcontinue"] = continue_token

        data = api_get(params)
        for member in data.get("query", {}).get("categorymembers", []):
            title = member["title"]
            if title in SKIP_TITLES:
                continue
            match = re.match(
                r"List of (.+?) (?:vehicles|automobiles|cars|road cars|passenger cars|motor vehicles)",
                title,
                re.I,
            )
            if match:
                make = match.group(1).strip()
                mapping.setdefault(make, title)

        continue_token = data.get("continue", {}).get("cmcontinue")
        if not continue_token:
            break

    return mapping


def save_catalog(catalog: dict) -> None:
    catalog["generatedAt"] = time.strftime("%Y-%m-%d")
    with CATALOG_PATH.open("w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
        f.write("\n")


def main() -> None:
    with CATALOG_PATH.open(encoding="utf-8") as f:
        catalog = json.load(f)

    list_pages = build_list_page_mapping()
    updated = 0
    still_empty: list[str] = []

    for i, entry in enumerate(catalog["makes"], start=1):
        make = entry["name"]
        if entry["models"]:
            continue

        print(f"[{i}/{len(catalog['makes'])}] Fetching models for {make}...", flush=True)
        models = fetch_models_for_make(make, list_pages)
        if models:
            entry["models"] = models
            updated += 1
            print(f"  -> {len(models)} models", flush=True)
        else:
            still_empty.append(make)
            print("  -> no models found", flush=True)

        if updated and updated % 25 == 0:
            save_catalog(catalog)
            print(f"  (checkpoint saved after {updated} updates)", flush=True)

        time.sleep(0.15)

    save_catalog(catalog)

    total = len(catalog["makes"])
    filled = sum(1 for m in catalog["makes"] if m["models"])
    print(f"\nUpdated {updated} makes.")
    print(f"Filled: {filled}/{total}. Still empty: {total - filled}.")
    if still_empty[:40]:
        print("Sample still empty:", ", ".join(still_empty[:40]))


if __name__ == "__main__":
    main()
