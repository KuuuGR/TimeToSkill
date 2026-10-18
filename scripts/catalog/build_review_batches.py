#!/usr/bin/env python3
"""Build the first editorial review wave. Does not modify source candidate files."""

from __future__ import annotations

import hashlib
import json
import re
import unicodedata
from collections import Counter, defaultdict
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from layout import BATCHES, DOCS, RESEARCH, check_only

DATA = RESEARCH
DOC_DIR = DOCS
BATCH_DIR = BATCHES
TODAY = "2026-10-18"
MAX_BATCH = 150
PROTECTED = (
    "candidates-raw.jsonl",
    "candidates-normalized.jsonl",
    "sources.json",
    "candidate-triage.jsonl",
    "duplicate-clusters.json",
    "catalog-profile.json",
)

DOMAINS = [
    "tworczosc-sztuka-rzemioslo",
    "praktyka-naprawa-samodzielnosc",
    "ruch-sport-taniec",
    "przyroda-nawigacja-obserwacja",
    "komunikacja-pisanie-spoleczne",
    "myslenie-pamiec-uczenie",
    "kuchnia-finanse-codziennosc",
    "technologia-nauka-nisze",
]
DOMAIN_LABELS = {
    "tworczosc-sztuka-rzemioslo": "Twórczość, sztuka i rzemiosło",
    "praktyka-naprawa-samodzielnosc": "Umiejętności praktyczne, naprawy i samodzielność",
    "ruch-sport-taniec": "Ruch, koordynacja, sport i taniec",
    "przyroda-nawigacja-obserwacja": "Przyroda, nawigacja, obserwacja i astronomia",
    "komunikacja-pisanie-spoleczne": "Komunikacja, pisanie i umiejętności społeczne",
    "myslenie-pamiec-uczenie": "Myślenie, pamięć i strategie uczenia się",
    "kuchnia-finanse-codziennosc": "Kuchnia, finanse osobiste i życie codzienne",
    "technologia-nauka-nisze": "Technologia, nauka i niszowe zainteresowania",
}
SOURCE_DOMAIN = {
    "usgs-map-and-compass": "przyroda-nawigacja-obserwacja",
    "roc-what-is-orienteering": "przyroda-nawigacja-obserwacja",
    "astronomical-league-observing-programs": "przyroda-nawigacja-obserwacja",
    "zooniverse-project-directory": "przyroda-nawigacja-obserwacja",
    "bbc-good-food-25-skills": "kuchnia-finanse-codziennosc",
    "cfpb-building-blocks-2016": "kuchnia-finanse-codziennosc",
    "purdue-owl-writing": "komunikacja-pisanie-spoleczne",
    "learning-scientists-six-strategies": "myslenie-pamiec-uczenie",
    "wdsf-dancesport-disciplines": "ruch-sport-taniec",
    "ausport-fundamental-movement": "ruch-sport-taniec",
    "olympic-education-fundamentals-2023": "ruch-sport-taniec",
    "heritage-crafts-inventory": "tworczosc-sztuka-rzemioslo",
}
SCOUT_DOMAIN = {
    "activity centre service": "praktyka-naprawa-samodzielnosc",
    "activity plus": "praktyka-naprawa-samodzielnosc",
    "air or sea navigation": "przyroda-nawigacja-obserwacja",
    "air researcher": "przyroda-nawigacja-obserwacja",
    "air spotter": "przyroda-nawigacja-obserwacja",
    "angler": "przyroda-nawigacja-obserwacja",
    "animal carer": "przyroda-nawigacja-obserwacja",
    "animal friend": "przyroda-nawigacja-obserwacja",
    "artist": "tworczosc-sztuka-rzemioslo",
    "athletics": "ruch-sport-taniec",
    "athletics plus": "ruch-sport-taniec",
    "backwoods cooking": "kuchnia-finanse-codziennosc",
    "be active": "ruch-sport-taniec",
    "book reader": "komunikacja-pisanie-spoleczne",
    "brilliant builder": "praktyka-naprawa-samodzielnosc",
    "builder": "praktyka-naprawa-samodzielnosc",
    "camp craft": "praktyka-naprawa-samodzielnosc",
    "camper": "przyroda-nawigacja-obserwacja",
    "caver": "przyroda-nawigacja-obserwacja",
    "caving": "przyroda-nawigacja-obserwacja",
    "chef": "kuchnia-finanse-codziennosc",
    "circus skills": "tworczosc-sztuka-rzemioslo",
    "climber": "ruch-sport-taniec",
    "collector": "technologia-nauka-nisze",
    "communicator": "komunikacja-pisanie-spoleczne",
    "cook": "kuchnia-finanse-codziennosc",
    "craft": "tworczosc-sztuka-rzemioslo",
    "creative": "tworczosc-sztuka-rzemioslo",
    "creative arts": "tworczosc-sztuka-rzemioslo",
    "cyclist": "ruch-sport-taniec",
    "disability awareness": "komunikacja-pisanie-spoleczne",
    "diy": "praktyka-naprawa-samodzielnosc",
    "dragon boating": "ruch-sport-taniec",
    "electronics": "technologia-nauka-nisze",
    "entertainer": "tworczosc-sztuka-rzemioslo",
    "environmental conservation": "przyroda-nawigacja-obserwacja",
    "equestrian": "ruch-sport-taniec",
    "exciting experiments": "myslenie-pamiec-uczenie",
    "experiment": "myslenie-pamiec-uczenie",
    "explore": "przyroda-nawigacja-obserwacja",
    "explore outdoors": "przyroda-nawigacja-obserwacja",
    "faith": "komunikacja-pisanie-spoleczne",
    "farming": "przyroda-nawigacja-obserwacja",
    "feel good": "kuchnia-finanse-codziennosc",
    "fire safety": "praktyka-naprawa-samodzielnosc",
    "forester": "przyroda-nawigacja-obserwacja",
    "fundraising": "komunikacja-pisanie-spoleczne",
    "gardener": "przyroda-nawigacja-obserwacja",
    "geocaching": "przyroda-nawigacja-obserwacja",
    "get creative": "tworczosc-sztuka-rzemioslo",
    "global issues": "komunikacja-pisanie-spoleczne",
    "go wild": "przyroda-nawigacja-obserwacja",
    "health and fitness": "ruch-sport-taniec",
    "hill walker": "ruch-sport-taniec",
    "hobbies": "technologia-nauka-nisze",
    "home help": "praktyka-naprawa-samodzielnosc",
    "home safety": "praktyka-naprawa-samodzielnosc",
    "instructor": "komunikacja-pisanie-spoleczne",
    "international": "komunikacja-pisanie-spoleczne",
    "jota-joti blanket badge": "komunikacja-pisanie-spoleczne",
    "leadership": "komunikacja-pisanie-spoleczne",
    "let it grow": "przyroda-nawigacja-obserwacja",
    "let’s celebrate": "komunikacja-pisanie-spoleczne",
    "let's celebrate": "komunikacja-pisanie-spoleczne",
    "librarian": "komunikacja-pisanie-spoleczne",
    "lifesaver": "praktyka-naprawa-samodzielnosc",
    "local knowledge": "przyroda-nawigacja-obserwacja",
    "local superhero": "komunikacja-pisanie-spoleczne",
    "martial arts": "ruch-sport-taniec",
    "master at arms": "praktyka-naprawa-samodzielnosc",
    "mechanic": "praktyka-naprawa-samodzielnosc",
    "media relations & marketing": "komunikacja-pisanie-spoleczne",
    "media relations and marketing": "komunikacja-pisanie-spoleczne",
    "meteorologist": "przyroda-nawigacja-obserwacja",
    "model maker": "tworczosc-sztuka-rzemioslo",
    "money skills": "kuchnia-finanse-codziennosc",
    "motor sports": "ruch-sport-taniec",
    "mountain biking": "ruch-sport-taniec",
    "my faith": "komunikacja-pisanie-spoleczne",
    "naturalist": "przyroda-nawigacja-obserwacja",
    "orienteer": "przyroda-nawigacja-obserwacja",
    "parascending": "ruch-sport-taniec",
    "performing arts": "tworczosc-sztuka-rzemioslo",
    "personal safety": "praktyka-naprawa-samodzielnosc",
    "photographer": "tworczosc-sztuka-rzemioslo",
    "physical recreation": "ruch-sport-taniec",
    "pioneer": "praktyka-naprawa-samodzielnosc",
    "power coxswain": "ruch-sport-taniec",
    "pulling (fixed seat rowing)": "ruch-sport-taniec",
    "quartermaster": "praktyka-naprawa-samodzielnosc",
    "racquet sports": "ruch-sport-taniec",
    "road safety": "praktyka-naprawa-samodzielnosc",
    "safety": "praktyka-naprawa-samodzielnosc",
    "science and technology": "technologia-nauka-nisze",
    "scientist": "technologia-nauka-nisze",
    "skater": "ruch-sport-taniec",
    "space": "przyroda-nawigacja-obserwacja",
    "space explorer": "przyroda-nawigacja-obserwacja",
    "sports": "ruch-sport-taniec",
    "sports enthusiast": "ruch-sport-taniec",
    "story time": "komunikacja-pisanie-spoleczne",
    "street sports": "ruch-sport-taniec",
    "super chef": "kuchnia-finanse-codziennosc",
    "survival skills": "praktyka-naprawa-samodzielnosc",
    "water activities": "ruch-sport-taniec",
    "world faiths": "komunikacja-pisanie-spoleczne",
    "writer": "komunikacja-pisanie-spoleczne",
    "26 in 26: a network challenge": "technologia-nauka-nisze",
}
ONET_WORK = {
    "Thinking Creatively": "tworczosc-sztuka-rzemioslo",
    "Performing for or Working Directly with the Public": "tworczosc-sztuka-rzemioslo",
    "Repairing and Maintaining Mechanical Equipment": "praktyka-naprawa-samodzielnosc",
    "Repairing and Maintaining Electronic Equipment": "praktyka-naprawa-samodzielnosc",
    "Handling and Moving Objects": "praktyka-naprawa-samodzielnosc",
    "Performing General Physical Activities": "ruch-sport-taniec",
    "Documenting/Recording Information": "komunikacja-pisanie-spoleczne",
    "Interpreting the Meaning of Information for Others": "komunikacja-pisanie-spoleczne",
    "Communicating with People Outside the Organization": "komunikacja-pisanie-spoleczne",
    "Establishing and Maintaining Interpersonal Relationships": "komunikacja-pisanie-spoleczne",
    "Resolving Conflicts and Negotiating with Others": "komunikacja-pisanie-spoleczne",
    "Training and Teaching Others": "myslenie-pamiec-uczenie",
    "Coaching and Developing Others": "myslenie-pamiec-uczenie",
    "Making Decisions and Solving Problems": "myslenie-pamiec-uczenie",
    "Judging the Qualities of Objects, Services, or People": "myslenie-pamiec-uczenie",
    "Working with Computers": "technologia-nauka-nisze",
}
OPENLEARN_DOMAIN = {
    "Digital & Computing": "technologia-nauka-nisze",
    "Education & Development": "myslenie-pamiec-uczenie",
    "Health, Sports & Psychology": "ruch-sport-taniec",
    "History & The Arts": "tworczosc-sztuka-rzemioslo",
    "Languages": "komunikacja-pisanie-spoleczne",
    "Money & Business": "kuchnia-finanse-codziennosc",
    "Nature & Environment": "przyroda-nawigacja-obserwacja",
    "Science, Maths & Technology": "technologia-nauka-nisze",
    "Society, Politics & Law": "komunikacja-pisanie-spoleczne",
}
KEYWORD_DOMAINS = [
    (
        "ruch-sport-taniec",
        re.compile(
            r"\b(dance|dancing|dances|swim|swimming|ski|skiing|skat|gymnastic|climb|climber|athletic|yoga|pilates|running|cycl|equestrian|paddl|tumbl|sport|fitness|throwing|catching|kicking|balancing|hopping|jumping)\b",
            re.I,
        ),
    ),
    (
        "przyroda-nawigacja-obserwacja",
        re.compile(
            r"\b(astronom|constellation|telescope|meteor|lunar|comet|orienteer|compass|contour|garden|gardening|wildlife|fossil|geolog|hike|hiking|naturalist|birdwatch|plant|forest|camp|navigat|map|observ)\b",
            re.I,
        ),
    ),
    (
        "kuchnia-finanse-codziennosc",
        re.compile(
            r"\b(cook|cooking|bake|baking|kitchen|dough|budget|saving|financ|money|grocery|sauce|knife)\b",
            re.I,
        ),
    ),
    (
        "komunikacja-pisanie-spoleczne",
        re.compile(
            r"\b(writ|proofread|outline|speak|speaking|listen|listening|negotiat|persuad|story|email|argument|paragraph|communicat|language|rhetoric)\b",
            re.I,
        ),
    ),
    (
        "myslenie-pamiec-uczenie",
        re.compile(
            r"\b(spacing|retrieval practice|elaboration|interleaving|dual coding|memory|critical thinking|problem solving|logic|mathematics|puzzle|chess|sudoku)\b",
            re.I,
        ),
    ),
    (
        "praktyka-naprawa-samodzielnosc",
        re.compile(
            r"\b(repair|diy|sew|sewing|knit|knitting|woodwork|wood chisel|solder|bicycle|tool|maintain|fix|builder)\b",
            re.I,
        ),
    ),
    (
        "tworczosc-sztuka-rzemioslo",
        re.compile(
            r"\b(paint|draw|photo|photograph|music|instrument|piano|guitar|sculpt|pottery|ceramic|art|sing|theatr|theater|film|video|calligraph|weav|smith|batik|craft|print)\b",
            re.I,
        ),
    ),
    (
        "technologia-nauka-nisze",
        re.compile(
            r"\b(program|software|comput|electron|science|chemistr|robot|radio|digital|code)\b",
            re.I,
        ),
    ),
]
ESCO_REJECT_TITLE = re.compile(
    r"\b(sewage|sewer|production plants|power plant|treatment plant|food plant)\b",
    re.I,
)
ORG_VERBS = {
    "manage",
    "supervise",
    "administer",
    "liaise",
    "recruit",
    "enforce",
    "audit",
    "delegate",
    "oversee",
    "coordinate",
    "prescribe",
    "diagnose",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def fold(value: str | None) -> str:
    text = unicodedata.normalize("NFKC", (value or "").replace("\u00a0", " "))
    return re.sub(r"\s+", " ", text).strip().casefold()


def first_token(title: str) -> str:
    parts = re.findall(r"[a-z0-9]+", fold(title))
    return parts[0] if parts else ""


def parent_label(row: dict) -> str:
    category = row.get("source_category") or ""
    return category.split("; ")[0] or "brak"


def keyword_domain(text: str) -> str | None:
    if ESCO_REJECT_TITLE.search(text):
        return None
    for domain, pattern in KEYWORD_DOMAINS:
        if pattern.search(text):
            return domain
    return None


def assign_domain(row: dict) -> str | None:
    source = row["source_id"]
    if source in SOURCE_DOMAIN:
        return SOURCE_DOMAIN[source]
    if source == "scouts-uk-activity-badges":
        return SCOUT_DOMAIN.get(fold(row["source_title"]))
    if source == "openlearn-full-catalogue":
        return OPENLEARN_DOMAIN.get(row["source_title"])
    if source == "onet-content-model-31.0" and row["source_title"] in ONET_WORK:
        return ONET_WORK[row["source_title"]]
    text = f"{row['source_title']} {row.get('source_description') or ''}"
    found = keyword_domain(text)
    if found:
        return found
    if source in {"wikidata-hobbies", "onet-content-model-31.0", "openlearn-full-catalogue"}:
        return "technologia-nauka-nisze"
    return None


def description_fields(row: dict) -> tuple[bool, str | None]:
    description = row.get("source_description")
    folded = fold(description)
    if not folded:
        return False, "Brak opisu źródłowego w bazie. Nie dopisano go."
    if folded in {"hobby", "activity"} or len(folded) < 12:
        return False, "Opis źródłowy jest zbyt krótki, żeby ocenić praktykę. Nie rozszerzano go."
    return True, None


def split_even(items: list[dict]) -> list[list[dict]]:
    if len(items) <= MAX_BATCH:
        return [items]
    parts = (len(items) + MAX_BATCH - 1) // MAX_BATCH
    base, extra = divmod(len(items), parts)
    chunks = []
    start = 0
    for index in range(parts):
        size = base + (1 if index < extra else 0)
        chunks.append(items[start : start + size])
        start += size
    return chunks


def interleave(rows: list[dict]) -> list[dict]:
    buckets: dict[str, list[dict]] = defaultdict(list)
    for row in sorted(rows, key=lambda item: (item["source_id"], fold(item["source_title"]), item["candidate_id"])):
        buckets[row["source_id"]].append(row)
    mixed = []
    while any(buckets.values()):
        for source in sorted(buckets):
            if buckets[source]:
                mixed.append(buckets[source].pop(0))
    return mixed


def select(raw: dict[str, dict], triage: dict[str, dict], clusters: list[dict]) -> tuple[dict[str, dict], dict]:
    chosen: dict[str, dict] = {}
    reasons: dict[str, str] = {}

    def add(row: dict, reason: str, domain: str | None = None) -> None:
        if row["candidate_id"] in chosen:
            return
        resolved = domain or assign_domain(row)
        if resolved not in DOMAINS:
            return
        chosen[row["candidate_id"]] = row
        reasons[row["candidate_id"]] = reason

    for row in raw.values():
        source = row["source_id"]
        title = row["source_title"]
        suitability = triage[row["candidate_id"]]["suitability"]
        if source in SOURCE_DOMAIN or source in {
            "astronomical-league-observing-programs",
            "zooniverse-project-directory",
        }:
            add(row, "zrodlo-praktyczne")
        elif source == "heritage-crafts-inventory":
            add(row, "rzemioslo-z-inwentarza")
        elif source == "wikidata-hobbies":
            add(row, "hobby-z-wikidanych")
        elif source == "scouts-uk-activity-badges":
            folded = fold(title)
            if "birthday" in folded or "uniform" in folded or "blanket badge" in folded:
                continue
            add(row, "odznaka-skautowa")
        elif source == "openlearn-full-catalogue":
            add(row, "naglowek-dzialu-kursow")
        elif source == "onet-content-model-31.0" and suitability == "adaptable_candidate":
            add(row, "onet-umiejetnosc-przenosna")
        elif title in ONET_WORK:
            add(row, "onet-czynosc-pracy-jako-inspiracja")

    esco_pool = []
    for row in raw.values():
        if row["source_id"] != "esco-skills-v1.2.1" or row["candidate_id"] in chosen:
            continue
        if triage[row["candidate_id"]]["suitability"] == "not_a_distinct_skill":
            continue
        if first_token(row["source_title"]) in ORG_VERBS:
            continue
        domain = keyword_domain(row["source_title"])
        if not domain:
            continue
        rank = {"adaptable_candidate": 0, "uncertain": 1, "occupational_or_abstract": 2}.get(
            triage[row["candidate_id"]]["suitability"], 9
        )
        if rank == 9:
            continue
        esco_pool.append((rank, fold(row["source_title"]), row["candidate_id"], domain, row))
    esco_pool.sort()
    per_domain: Counter[str] = Counter()
    per_parent: Counter[str] = Counter()
    per_token: Counter[str] = Counter()
    esco_added = 0
    for _rank, _title, _cid, domain, row in esco_pool:
        parent = parent_label(row)
        token = first_token(row["source_title"])
        if per_domain[domain] >= 18 or per_parent[parent] >= 3 or per_token[token] >= 2 or esco_added >= 100:
            continue
        add(row, "esco-probka-codziennej-praktyki", domain)
        per_domain[domain] += 1
        per_parent[parent] += 1
        per_token[token] += 1
        esco_added += 1

    siblings: dict[str, list[str]] = defaultdict(list)
    for cluster in clusters:
        if len(cluster["candidate_ids"]) > 6:
            continue
        for member in cluster["candidate_ids"]:
            siblings[member].extend(
                other for other in cluster["candidate_ids"] if other != member and other not in siblings[member]
            )
    for cid in list(chosen):
        for other in siblings.get(cid, []):
            if other in chosen or other not in raw:
                continue
            add(raw[other], "sasiedni-rekord-z-grupy-podobieństwa")

    stats = {
        "esco_added_before_siblings": esco_added,
        "by_reason": dict(Counter(reasons.values())),
        "excluded_ceremonial_or_blanket_scouts": sum(
            1
            for row in raw.values()
            if row["source_id"] == "scouts-uk-activity-badges"
            and any(word in fold(row["source_title"]) for word in ("birthday", "uniform", "blanket badge"))
        ),
    }
    return {cid: {"domain": assign_domain(raw[cid]) if reasons[cid] != "esco-probka-codziennej-praktyki" else assign_domain(raw[cid]), "reason": reasons[cid]} for cid in chosen}, stats


def domain_of(row: dict, meta: dict) -> str:
    if meta["reason"] == "esco-probka-codziennej-praktyki":
        return keyword_domain(row["source_title"]) or "technologia-nauka-nisze"
    if meta["reason"] == "sasiedni-rekord-z-grupy-podobieństwa":
        assigned = assign_domain(row)
        return assigned or "technologia-nauka-nisze"
    assigned = assign_domain(row)
    if not assigned:
        raise SystemExit(f"Selected record has no domain: {row['candidate_id']}")
    return assigned


def write_schema() -> None:
    schema = {
        "schema_version": 1,
        "status": "empty_template",
        "purpose": "Docelowy rekord skilla katalogu 1001. Ten plik nie zawiera gotowych skillów ani treści poziomów.",
        "fields": {
            "skill_id": {
                "type": "string",
                "required": True,
                "description": "Stabilny identyfikator skilla. Nie jest identyfikatorem rekordu źródłowego.",
            },
            "name": {
                "type": "string",
                "required": True,
                "description": "Krótka, rozpoznawalna nazwa umiejętności, nie tytuł kursu ani nazwa zawodu.",
            },
            "description": {
                "type": "string",
                "required": True,
                "description": "Czego osoba się uczy i co ćwiczy. Nie jest kopią całego opisu źródłowego.",
            },
            "category": {
                "type": "string",
                "required": True,
                "description": "Jedna dziedzina katalogu, ustalona przy zatwierdzeniu.",
            },
            "source_candidate_ids": {
                "type": "array[string]",
                "required": True,
                "description": "Identyfikatory kandydatur z candidates-raw.jsonl, które potwierdzają albo inspirują skilla.",
            },
            "source_ids": {
                "type": "array[string]",
                "required": True,
                "description": "Identyfikatory źródeł z sources.json użyte jako inspiracja albo potwierdzenie.",
            },
            "levels": {
                "type": "array[object]",
                "required": True,
                "length": 3,
                "description": "Dokładnie trzy poziomy rozwoju, od pierwszego samodzielnego wykonania do pewnej praktyki.",
                "item_fields": {
                    "name": "Nazwa poziomu. Na tym etapie pusta.",
                    "completion_criterion": "Mierzalne albo obserwowalne kryterium ukończenia. Na tym etapie puste.",
                    "can_do": "Co użytkownik potrafi wykonać na tym poziomie. Na tym etapie puste.",
                    "safety_requirements": "Wymagania bezpieczeństwa tego poziomu albo null, gdy nie są potrzebne.",
                },
            },
            "emoji": {
                "type": "string",
                "required": True,
                "description": "Jedno emoji dopasowane do umiejętności. Zasady są w emoji-guidelines.md.",
            },
            "emoji_rationale": {
                "type": "string",
                "required": True,
                "description": "Krótkie uzasadnienie, dlaczego to emoji pasuje do praktyki.",
            },
            "tags": {
                "type": "array[string]",
                "required": True,
                "description": "Krótkie etykiety pomocnicze. Nie zastępują kategorii ani nazwy.",
            },
            "safety_notes": {
                "type": "string|null",
                "required": False,
                "description": "Uwagi bezpieczeństwa dla całej umiejętności. Null, gdy praktyka ich nie wymaga.",
            },
            "review_status": {
                "type": "string",
                "required": True,
                "allowed": ["unreviewed", "accepted", "rejected", "needs_source"],
                "description": "Stan redakcji. Pusty szablon nie ma statusu zatwierdzenia.",
            },
        },
        "example": {
            "skill_id": None,
            "name": None,
            "description": None,
            "category": None,
            "source_candidate_ids": [],
            "source_ids": [],
            "levels": [
                {
                    "name": None,
                    "completion_criterion": None,
                    "can_do": None,
                    "safety_requirements": None,
                },
                {
                    "name": None,
                    "completion_criterion": None,
                    "can_do": None,
                    "safety_requirements": None,
                },
                {
                    "name": None,
                    "completion_criterion": None,
                    "can_do": None,
                    "safety_requirements": None,
                },
            ],
            "emoji": None,
            "emoji_rationale": None,
            "tags": [],
            "safety_notes": None,
            "review_status": None,
        },
    }
    (DOC_DIR / "approved-skill-schema.json").write_text(
        json.dumps(schema, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def write_emoji_guidelines() -> None:
    text = """# Wytyczne emoji dla katalogu 1001 Skills

Emoji wybiera się dopiero przy zatwierdzaniu skilla. Ten dokument nie przypisuje ikon kandydaturom.

## Zasada

Każdy zatwierdzony skill dostaje dokładnie jedno emoji. Ma być zrozumiałe bez legendy i ma pasować do praktyki, nie do żartu ani do marki.

Powtórzenia są dozwolone. Nie trzeba mieć 1001 różnych emoji. Nie wolno natomiast oprzeć niemal całego katalogu na kilku ikonach, na przykład samym młotku, książce albo gwiazdce.

## Jak dobierać

- Najpierw szukaj emoji czynności: pisanie, gotowanie, pływanie, obserwacja.
- Gdy czynność nie ma własnej ikony, użyj narzędzia, obiektu albo miejsca, które odróżnia skill od sąsiednich.
- Mniej oczywiste emoji są lepsze niż kolejna kopia już częstej ikony, o ile nadal da się je odczytać.
- Jedno emoji może łączyć kilka skillów jednej rodziny, jeśli różnica jest w nazwie i poziomach, a nie w ikonie.
- Nie twórz osobnego skilla tylko po to, żeby użyć innego emoji.

## Czego nie robić

- Nie wstawiaj kilku emoji w jednym polu.
- Nie używaj emoji jako nazwy skilla.
- Nie dobieraj ikony do zawodu, źródła albo poziomu trudności.
- Nie zmieniaj emoji przy przejściu na kolejny poziom. Poziomy opisuje pole `levels`, nie ikona.

## Kontrola przy zatwierdzaniu

Przy zamknięciu katalogu policz częstotliwość każdego emoji. Zwróć uwagę na symbol, który pokrywa dużą część katalogu albo całą dziedzinę, choć w tej dziedzinie są wyraźnie różne praktyki. Wtedy część skillów dostaje inne, nadal czytelne emoji. Raport częstotliwości jest osobnym krokiem i nie powstaje w tej fali recenzji.
"""
    (DOC_DIR / "emoji-guidelines.md").write_text(text, encoding="utf-8")


def write_readme(batches: list[dict], stats: dict, suitability: Counter, sources: Counter) -> None:
    lines = [
        "# Pierwsza fala pakietów recenzji",
        "",
            f"Data: {TODAY}. Kandydatury w fali: **{sum(batch['count'] for batch in batches)}**.",
            "To nie jest katalog skillów. Każdy wiersz wskazuje rekord w `data/skills-catalog/research/candidates-raw.jsonl`. Triage jest heurystyką, nie oceną jakości.",
            "Pakiet poniżej 100 rekordów nie był dociągany innymi dziedzinami. Tyle materiału ta fala uczciwie znalazła.",
        "",
        "## Pakiety",
        "",
        "| Plik | Dziedzina | Rekordy |",
        "| --- | --- | ---: |",
    ]
    for batch in batches:
        lines.append(
            f"| `{batch['file']}` | {DOMAIN_LABELS[batch['domain']]} | {batch['count']} |"
        )
    lines.extend(["", "## Dziedziny", ""])
    for domain in DOMAINS:
        count = sum(batch["count"] for batch in batches if batch["domain"] == domain)
        lines.append(f"- {DOMAIN_LABELS[domain]}: {count}")
    lines.extend(
        [
            "",
            "## Źródła w fali",
            "",
        ]
    )
    for source, count in sources.most_common():
        lines.append(f"- `{source}`: {count}")
    lines.extend(
        [
            "",
            "## Klasy triage w fali",
            "",
            "Te liczby opisują skład pakietów, nie nową ocenę.",
            "",
        ]
    )
    for key in (
        "strong_candidate",
        "adaptable_candidate",
        "uncertain",
        "occupational_or_abstract",
        "not_a_distinct_skill",
    ):
        lines.append(f"- `{key}`: {suitability[key]}")
    lines.extend(
        [
            "",
            "## Dobór",
            "",
            "- Wzięto całe źródła praktyczne z etapu T4S-CATALOG-002, cały inwentarz rzemiosł i całą listę hobby Wikidanych.",
            "- Odznaki Skautów weszły bez tekstu wymagań. Pominięto odznaki mundurowe, urodzinowe i blanket badge, bo nazwa nie opisuje praktyki.",
            f"- Takich pominiętych odznak jest {stats['excluded_ceremonial_or_blanket_scouts']}.",
            "- Z ESCO wzięto próbkę co najwyżej 100 tytułów pasujących do codziennej praktyki, najwyżej 18 na dziedzinę, 3 na jedną etykietę nadrzędną i 2 na ten sam pierwszy wyraz. Pominięto czasowniki organizacyjne i tytuły „types of”.",
            "- Z O*NET wzięto umiejętności oznaczone wcześniej jako adaptowalne oraz krótką listę czynności pracy, które mogą podsunąć praktykę codzienną. Nie wzięto obsadzania stanowisk, administracji ani nadzoru.",
            "- Nagłówki działów OpenLearn weszły jako przykłady tematów, nie skillów.",
            "- Jeśli rekord z fali należy do grupy podobieństwa o co najwyżej sześciu członkach, sąsiednie identyfikatory dopisano do fali. Nie scalano ich i nie usuwano z bazy.",
            "",
            "## Braki",
            "",
            "- Myślenie, pamięć i uczenie się ma osobny, krótki pakiet. Poza sześcioma strategiami i kilkoma łamigłówkami baza nie ma szerszego materiału. Nie dociągano go systemami LMS ani kursami.",
            "- Rozpoznawanie organizmów po wyglądzie i głosie: brak rekordów iNaturalist. W fali są tylko pośrednie tytuły, takie jak naturalist albo gardener.",
            "- Oszustwa finansowe: brak osobnego rekordu w dostępnym materiale CFPB.",
            "- Przyprawianie i organizacja stanowiska kuchennego: strona BBC nie dała na nie osobnych kandydatur.",
            "- Większość dyscyplin sportowych nie weszła do bazy, bo lista olimpijska podawała same nazwy. W fali są opisane praktyki ruchu, nie komplet sportów.",
            "- Odznaki Skautów nie mają wymagań, więc recenzent nie dostaje kryterium ukończenia.",
            "- Próbka ESCO nie jest przeglądem 13 939 pojęć. Duże kategorie zawodowe celowo nie wypełniają pakietów.",
            "",
            "## Jak oceniać",
            "",
            "Dla każdej pozycji rozstrzygnąć jedną z możliwości: odrębna praktyka, praktyka po adaptacji, przykład albo wariant, temat, narzędzie, zawód, albo brak wystarczającego źródła. Podobne brzmienie nie scala pozycji. Ogólna technika może zostać osobnym skillem, jeśli ma własną drogę rozwoju.",
            "",
            "Pole `related_unresolved_candidate_ids` jest tylko wskazówką z `duplicate-clusters.json`. Odrębność nie została rozstrzygnięta.",
            "",
            "Gdy `description_sufficient` jest false, oceniać wyłącznie nazwę, kategorię i pochodzenie. Nie traktować pustki jako ukrytego opisu.",
            "",
            "Z zatwierdzonych praktyk powstanie później rekord według `approved-skill-schema.json`. Ta fala go nie wypełnia. Emoji dobiera się według `emoji-guidelines.md`.",
            "",
            "## Pola rekordu w pakiecie",
            "",
            "- `batch_id`, `position` — miejsce w pliku.",
            "- `candidate_id`, `source_id` — odnośniki do bazy głównej.",
            "- `source_title` — oryginalna nazwa.",
            "- `source_description` — oryginalny opis albo null.",
            "- `description_sufficient`, `description_note` — czy opisu starcza do oceny.",
            "- `source_url`, `source_category`, `candidate_type` — pola źródłowe.",
            "- `triage_suitability`, `triage_confidence`, `triage_reason`, `human_review_required` — wynik heurystyki.",
            "- `review_domain` — dziedzina pakietu.",
            "- `selection_reason` — dlaczego rekord wszedł do tej fali.",
            "- `related_unresolved_candidate_ids` — inne kandydatury z małych grup podobieństwa.",
            "",
        ]
    )
    (BATCH_DIR / "README.md").write_text("\n".join(lines), encoding="utf-8")


def update_catalog_readme() -> None:
    path = DOC_DIR / "README.md"
    marker = "## T4S-CATALOG-004"
    text = path.read_text(encoding="utf-8")
    addition = (
        "\n## T4S-CATALOG-004\n\n"
        "Pierwsza fala recenzji jest w `review-batches/`. Schemat docelowego skilla: "
        "`approved-skill-schema.json`. Zasady emoji: `emoji-guidelines.md`. "
        "Odtworzenie: `python3 scripts/catalog/build_review_batches.py`. "
        "Ten etap nie zatwierdza skillów i nie zmienia bazy źródłowej.\n"
    )
    if marker in text:
        text = text.split(marker)[0].rstrip() + "\n" + addition
    else:
        text = text.rstrip() + "\n" + addition
    path.write_text(text, encoding="utf-8")


def main() -> None:
    check_only([DATA / name for name in PROTECTED] + [DOC_DIR / "README.md"])
    before = {name: sha256(DATA / name) for name in PROTECTED}
    raw = {
        json.loads(line)["candidate_id"]: json.loads(line)
        for line in (DATA / "candidates-raw.jsonl").read_text(encoding="utf-8").splitlines()
    }
    triage = {
        json.loads(line)["candidate_id"]: json.loads(line)
        for line in (DATA / "candidate-triage.jsonl").read_text(encoding="utf-8").splitlines()
    }
    cluster_doc = json.loads((DATA / "duplicate-clusters.json").read_text(encoding="utf-8"))
    known_sources = {
        item["source_id"]
        for item in json.loads((DATA / "sources.json").read_text(encoding="utf-8"))["sources"]
    }
    meta, stats = select(raw, triage, cluster_doc["clusters"])
    related: dict[str, list[str]] = defaultdict(list)
    for cluster in cluster_doc["clusters"]:
        if len(cluster["candidate_ids"]) > 6:
            continue
        for member in cluster["candidate_ids"]:
            for other in cluster["candidate_ids"]:
                if other != member and other not in related[member]:
                    related[member].append(other)

    by_domain: dict[str, list[dict]] = {domain: [] for domain in DOMAINS}
    for cid, info in meta.items():
        row = raw[cid]
        domain = domain_of(row, info)
        by_domain[domain].append(row)

    if BATCH_DIR.exists():
        for path in BATCH_DIR.glob("*.jsonl"):
            path.unlink()
    BATCH_DIR.mkdir(exist_ok=True)

    batches = []
    file_index = 1
    suitability = Counter()
    sources = Counter()
    for domain in DOMAINS:
        mixed = interleave(by_domain[domain])
        for part, chunk in enumerate(split_even(mixed), start=1):
            file_name = f"{file_index:02d}-{domain}-{part:02d}.jsonl"
            records = []
            for position, row in enumerate(chunk, start=1):
                sufficient, note = description_fields(row)
                triage_row = triage[row["candidate_id"]]
                record = {
                    "batch_id": file_name.removesuffix(".jsonl"),
                    "position": position,
                    "candidate_id": row["candidate_id"],
                    "source_id": row["source_id"],
                    "source_title": row["source_title"],
                    "source_description": row.get("source_description"),
                    "description_sufficient": sufficient,
                    "description_note": note,
                    "source_url": row["source_url"],
                    "source_category": row["source_category"],
                    "candidate_type": row["candidate_type"],
                    "triage_suitability": triage_row["suitability"],
                    "triage_confidence": triage_row["confidence"],
                    "triage_reason": triage_row["reason"],
                    "human_review_required": triage_row["human_review_required"],
                    "review_domain": domain,
                    "selection_reason": meta[row["candidate_id"]]["reason"],
                    "related_unresolved_candidate_ids": related.get(row["candidate_id"], []),
                }
                if record["source_id"] not in known_sources:
                    raise SystemExit(f"Unknown source {record['source_id']}")
                records.append(record)
                suitability[record["triage_suitability"]] += 1
                sources[record["source_id"]] += 1
            (BATCH_DIR / file_name).write_text(
                "".join(json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n" for record in records),
                encoding="utf-8",
            )
            batches.append({"file": file_name, "domain": domain, "count": len(records)})
            file_index += 1

    write_readme(batches, stats, suitability, sources)
    write_schema()
    write_emoji_guidelines()
    update_catalog_readme()
    after = {name: sha256(DATA / name) for name in PROTECTED}
    if before != after:
        raise SystemExit("Protected files changed")
    seen = set()
    for batch in batches:
        for line in (BATCH_DIR / batch["file"]).read_text(encoding="utf-8").splitlines():
            record = json.loads(line)
            if record["candidate_id"] in seen or record["candidate_id"] not in raw:
                raise SystemExit(f"Bad candidate {record['candidate_id']}")
            seen.add(record["candidate_id"])
            source = raw[record["candidate_id"]]
            if record["source_id"] != source["source_id"] or record["source_title"] != source["source_title"]:
                raise SystemExit(f"Source mismatch {record['candidate_id']}")
            if record["source_description"] != source.get("source_description"):
                raise SystemExit(f"Description rewritten {record['candidate_id']}")
            for other in record["related_unresolved_candidate_ids"]:
                if other not in raw:
                    raise SystemExit(f"Unknown related id {other}")
            if record["review_domain"] != batch["domain"] or record["source_id"] not in known_sources:
                raise SystemExit(f"Domain or source mismatch {record['candidate_id']}")
        if batch["count"] > MAX_BATCH:
            raise SystemExit(f"Batch too large {batch['file']}")
    total = sum(batch["count"] for batch in batches)
    print("total", total)
    print("batches", [(batch["file"], batch["count"]) for batch in batches])
    print("suitability", dict(suitability))
    print("reasons", stats["by_reason"])
    if not 800 <= total <= 1000:
        raise SystemExit(f"Wave size {total} is outside 800-1000")


if __name__ == "__main__":
    main()
