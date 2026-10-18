#!/usr/bin/env python3
"""Profile candidates and propose triage plus duplicate groups.

Does not modify candidates-raw.jsonl, candidates-normalized.jsonl, or sources.json.
Does not delete, merge, or approve records. Does not call an external model.
"""

from __future__ import annotations

import hashlib
import json
import re
import unicodedata
from collections import Counter, defaultdict
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from layout import DOCS, RESEARCH, check_only

DATA = RESEARCH
DOCS_DIR = DOCS
TODAY = "2026-10-18"
SUITABILITY = {
    "strong_candidate",
    "adaptable_candidate",
    "occupational_or_abstract",
    "not_a_distinct_skill",
    "uncertain",
}
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
MACHINE_VERBS = {"operate", "tend", "weld", "assemble", "manufacture"}
KNOWLEDGE_TOPIC = re.compile(
    r"^(types of|principles of|characteristics of|composition of|legislation|regulations|regulatory|policies)\b",
    re.I,
)
CONSUMER_TITLE = re.compile(
    r"("
    r"\bplay the [a-z]|"
    r"\bplay musical instruments\b|"
    r"\bperform dances\b|"
    r"\bpractice dance moves\b|"
    r"^swim$|"
    r"\bswimming styles\b|"
    r"\bwater skiing\b|"
    r"\buse manual sewing techniques\b|"
    r"\buse manual knitting techniques\b|"
    r"^photography$|"
    r"\brepair clocks\b|"
    r"\brepair jewellery\b|"
    r"\brepair electric bicycles\b|"
    r"\bclimb trees\b|"
    r"\bcarve materials\b|"
    r"\bsolder electronics\b|"
    r"\bapply soldering techniques\b"
    r")",
    re.I,
)
DANCE_FAMILIES = {"standard dances", "latin dances", "rhythm", "smooth"}
STOP = {
    "a",
    "an",
    "the",
    "of",
    "and",
    "or",
    "to",
    "for",
    "in",
    "on",
    "with",
    "by",
    "from",
    "your",
    "their",
    "into",
    "onto",
}
AREAS = [
    ("Nawigacja i mapa", r"\b(map|compass|contour|orienteer|bearing|declination)\b"),
    ("Astronomia", r"\b(astronom|constellation|telescope|meteor|lunar|comet)\b"),
    ("Przyroda i obserwacja", r"\b(bird|plant|insect|wildlife|species|naturalist)\b"),
    ("Nauka obywatelska", r"\b(citizen science|georeferenc|transcrib|classifying)\b"),
    ("Gotowanie", r"\b(cook|bake|knife|dough|sauce|kitchen)\b"),
    ("Finanse osobiste", r"\b(budget|saving|interest payment|comparison shopping|financial)\b"),
    ("Pisanie", r"\b(writ|proofread|outline|paragraph|argument|edit)\b"),
    ("Taniec", r"\b(dance|dancing|choreograph|waltz|salsa)\b"),
    ("Ruch i sport", r"\b(throw|catch|kick|swim|ski|skat|gymnastic|climb|balanc)\b"),
    ("Rzemiosło", r"\b(craft|smith|weav|pottery|carv|sew|knit)\b"),
    ("Pamięć i uczenie się", r"\b(spacing|retrieval|elaboration|interleaving|dual coding)\b"),
    ("Muzyka", r"\b(music|instrument|piano|guitar|sing)\b"),
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def norm_text(value: str | None) -> str:
    if not value:
        return ""
    text = unicodedata.normalize("NFC", value.replace("\u00a0", " "))
    return re.sub(r"\s+", " ", text).strip()


def comparison_key(value: str | None) -> str:
    return unicodedata.normalize("NFKC", norm_text(value)).casefold()


def slug(value: str) -> str:
    text = re.sub(r"[^a-z0-9]+", "-", comparison_key(value)).strip("-")
    return text[:48] or "item"


def cluster_id(kind: str, label: str, member_ids: list[str]) -> str:
    joined = "\n".join(sorted(member_ids))
    digest = hashlib.sha1(joined.encode("utf-8")).hexdigest()[:8]
    return f"{kind}:{slug(label)}:{digest}"


def esco_fields(note: str) -> tuple[str, str]:
    skill_type = re.search(r"skillType=([^\s.]+)", note or "")
    reuse = re.search(r"reuseLevel=([^\s.]+)", note or "")
    return (
        skill_type.group(1) if skill_type else "",
        reuse.group(1) if reuse else "",
    )


def first_token(title: str) -> str:
    parts = re.findall(r"[a-z0-9]+", title.casefold())
    return parts[0] if parts else ""


def decision(suitability: str, confidence: str, reason: str, signals: list[str], review: bool) -> dict:
    if suitability not in SUITABILITY:
        raise SystemExit(f"bad suitability {suitability}")
    if confidence not in {"high", "medium", "low"}:
        raise SystemExit(f"bad confidence {confidence}")
    return {
        "suitability": suitability,
        "confidence": confidence,
        "reason": reason,
        "signals": signals,
        "human_review_required": review,
    }


def classify(row: dict) -> dict:
    title = row["source_title"]
    folded = title.casefold().strip()
    source = row["source_id"]
    kind = row["candidate_type"]
    description = norm_text(row.get("source_description"))
    skill_type, reuse = esco_fields(row.get("provenance_note") or "")
    token = first_token(title)

    if kind == "węzeł taksonomii":
        return decision(
            "occupational_or_abstract",
            "high",
            "Rekord jest węzłem taksonomii pracy, a nie czynnością do ćwiczenia.",
            ["candidate_type:taxonomy-node", f"source:{source}"],
            False,
        )
    if source == "openlearn-full-catalogue":
        return decision(
            "not_a_distinct_skill",
            "high",
            "To nagłówek działu katalogu kursów. Kursy pod nim nie zostały zapisane jako umiejętności.",
            ["source:openlearn-subject-heading"],
            False,
        )
    if source == "scouts-uk-activity-badges":
        if any(word in folded for word in ("uniform", "birthday", "anniversary")):
            return decision(
                "not_a_distinct_skill",
                "high",
                "Nazwa dotyczy odznaki okolicznościowej albo mundurowej, nie ćwiczonej umiejętności.",
                ["source:scouts", "ceremonial-badge"],
                False,
            )
        return decision(
            "uncertain",
            "low",
            "Zapisano sam tytuł odznaki. Bez wymagań nie da się odróżnić umiejętności od tematu albo jednorazowej aktywności.",
            ["source:scouts", "title-only"],
            True,
        )
    if source == "astronomical-league-observing-programs":
        return decision(
            "adaptable_candidate",
            "medium",
            "Tytuł jest nazwą programu albo nagrody. W pochodzeniu jest praktyka obserwacyjna, ale sam program nie jest jeszcze skilliem.",
            ["source:astronomical-league", "program-name"],
            True,
        )
    if source == "zooniverse-project-directory":
        return decision(
            "adaptable_candidate",
            "medium",
            "Tytuł jest zdaniem z jednego projektu i stoi za szerszym typem działania. Nie zatwierdza osobnego skilla.",
            ["source:zooniverse", "example-phrase"],
            True,
        )
    if source == "olympic-education-fundamentals-2023" and folded == "learning to play fair":
        return decision(
            "adaptable_candidate",
            "low",
            "Źródło opisuje postawę i kartę fair play, nie technikę ruchu z własną drogą ćwiczeń.",
            ["source:ovep", "attitude"],
            True,
        )
    if source == "olympic-education-fundamentals-2023" and folded == "seats with runners":
        return decision(
            "adaptable_candidate",
            "medium",
            "Fraza opisuje sposób zjeżdżania na płozach. Bobslej, saneczkarstwo i skeleton nie zostały rozdzielone.",
            ["source:ovep", "mode-not-a-named-sport"],
            True,
        )
    if source == "ausport-fundamental-movement" and folded == "using a wheelchair":
        return decision(
            "adaptable_candidate",
            "medium",
            "Źródło wymienia poruszanie się na wózku wśród umiejętności lokomocyjnych. To kontekst ruchu, nie osobny sport.",
            ["source:ausport", "equipment-context"],
            True,
        )
    if source == "wdsf-dancesport-disciplines" and folded in DANCE_FAMILIES:
        return decision(
            "adaptable_candidate",
            "medium",
            "Strona opisuje rodzinę tańców jednym akapitem. Poszczególne tańce nie zostały rozdzielone i mogą nie być jednym skillem.",
            ["source:wdsf", "dance-family"],
            True,
        )
    if source == "usgs-map-and-compass" and folded == "topographic maps":
        return decision(
            "adaptable_candidate",
            "medium",
            "Tytuł jest typem mapy. Opis dotyczy czytania obiektów, więc wymaga przepisania na czynność.",
            ["source:usgs", "topic-label"],
            True,
        )
    if source == "learning-scientists-six-strategies":
        return decision(
            "adaptable_candidate",
            "medium",
            "Nazwa strategii jest w źródle, ale zapisana strona nie podaje definicji ani kryteriów postępu.",
            ["source:learning-scientists", "name-without-definition"],
            True,
        )
    if source in {
        "usgs-map-and-compass",
        "roc-what-is-orienteering",
        "bbc-good-food-25-skills",
        "cfpb-building-blocks-2016",
        "purdue-owl-writing",
        "wdsf-dancesport-disciplines",
        "ausport-fundamental-movement",
        "olympic-education-fundamentals-2023",
    }:
        return decision(
            "strong_candidate",
            "medium",
            "Źródło opisuje powtarzalną praktykę. Trzy poziomy nie zostały napisane, więc to nie jest zatwierdzenie.",
            ["source:" + source, "described-practice"],
            True,
        )
    if source == "heritage-crafts-inventory":
        if "(" in title:
            return decision(
                "not_a_distinct_skill",
                "medium",
                "Nawias doprecyzowuje region, materiał albo instrument. Wygląda to na wariant rzemiosła, nie na osobny skill.",
                ["source:heritage-crafts", "parenthetical-variant"],
                True,
            )
        return decision(
            "strong_candidate",
            "medium",
            "Inwentarz podaje nazwę rzemiosła. Artykułu nie czytano, więc droga trzech poziomów nie jest opisana w rekordzie.",
            ["source:heritage-crafts", "craft-name-only"],
            True,
        )
    if source == "wikidata-hobbies":
        lowered = description.casefold()
        if lowered in {"", "hobby", "activity"} or "job and/or hobby" in lowered:
            return decision(
                "uncertain",
                "low",
                "Opis jest pusty, ogólny albo mówi jednocześnie o zawodzie i hobby. Z samej nazwy nie wynika praktyka.",
                ["source:wikidata", "thin-description"],
                True,
            )
        if any(
            phrase in lowered
            for phrase in (
                "toy",
                "transportation system",
                "computer generated",
                "computer-created",
                "occupation",
                "person who",
                "person specializing",
                "resource for",
            )
        ):
            return decision(
                "not_a_distinct_skill",
                "medium",
                "Opis wskazuje przedmiot, system, zawód albo osobę, a nie ćwiczenie do rozwijania.",
                ["source:wikidata", "not-a-practice-description"],
                True,
            )
        if any(phrase in lowered for phrase in ("collect", "interest for", "trading", "exchanging postcard")):
            return decision(
                "not_a_distinct_skill",
                "low",
                "Opis dotyczy zbierania, zainteresowania albo wymiany. To może być hobby, ale nie widać ćwiczonej umiejętności.",
                ["source:wikidata", "collecting-or-interest"],
                True,
            )
        if any(
            phrase in lowered
            for phrase in (
                "craft",
                "practice",
                "performance",
                "sport",
                "making",
                "riding",
                "fitness",
                "swimming",
                "diving",
            )
        ):
            return decision(
                "strong_candidate",
                "medium",
                "Opis Wikidanych nazywa praktykę, sport albo rzemiosło. Przynależność do listy hobby nie jest sama w sobie oceną.",
                ["source:wikidata", "practice-description"],
                True,
            )
        return decision(
            "adaptable_candidate",
            "low",
            "Jest opis aktywności, ale nie widać w nim wyraźnej drogi trzech poziomów.",
            ["source:wikidata", "activity-description"],
            True,
        )
    if source == "onet-content-model-31.0":
        if kind == "pojęcie zawodowe":
            return decision(
                "occupational_or_abstract",
                "high",
                "To szczegółowa czynność z modelu treści pracy, zapisana jako pojęcie zawodowe.",
                ["source:onet", "work-activity-detail"],
                False,
            )
        if kind == "zdolność":
            return decision(
                "occupational_or_abstract",
                "medium",
                "O*NET opisuje to jako zdolność, czyli potencjał, a nie wybraną praktykę. Nie rozstrzygnięto, czy da się ją ćwiczyć.",
                ["source:onet", "ability"],
                True,
            )
        if kind == "obszar wiedzy":
            return decision(
                "occupational_or_abstract",
                "medium",
                "To element wiedzy zawodowej, nie osobna praktyka konsumencka.",
                ["source:onet", "knowledge"],
                True,
            )
        if kind == "praktyczna czynność":
            return decision(
                "adaptable_candidate",
                "low",
                "Czynność pochodzi z taksonomii pracy. Może dać się przepisać, ale opis nie jest praktyką hobbystyczną.",
                ["source:onet", "work-activity"],
                True,
            )
        return decision(
            "adaptable_candidate",
            "low",
            "To umiejętność przenośna z modelu pracy. Nazwa nie pokazuje jeszcze konsumenckiej drogi rozwoju.",
            ["source:onet", "transferable-skill"],
            True,
        )
    if source == "esco-skills-v1.2.1":
        if not skill_type or not reuse:
            return decision(
                "uncertain",
                "low",
                "W pochodzeniu brakuje skillType albo reuseLevel. Nazwa i opis nie zostały dodatkowo interpretowane.",
                ["source:esco", "missing-esco-type"],
                True,
            )
        if skill_type == "knowledge" and KNOWLEDGE_TOPIC.search(title):
            return decision(
                "not_a_distinct_skill",
                "high",
                "Tytuł nazywa typ obiektów, zasady albo regulacje. To temat klasyfikacji, nie ćwiczenie.",
                ["source:esco", "skillType:knowledge", "topic-title"],
                False,
            )
        if skill_type == "knowledge":
            return decision(
                "occupational_or_abstract",
                "medium",
                "ESCO oznacza rekord jako wiedzę, nie jako umiejętność praktyczną. Nie czytano opisu pod kątem wyjątku.",
                ["source:esco", "skillType:knowledge", f"reuseLevel:{reuse}"],
                True,
            )
        if CONSUMER_TITLE.search(folded):
            return decision(
                "adaptable_candidate",
                "medium",
                "Tytuł pasuje do wzorca praktyki osobistej, ale rekord pochodzi z klasyfikacji zawodowej i wymaga przepisania.",
                ["source:esco", "consumer-title-pattern", f"reuseLevel:{reuse}"],
                True,
            )
        if token in ORG_VERBS and reuse in {"sector-specific", "occupation-specific"}:
            return decision(
                "occupational_or_abstract",
                "high",
                "Czasownik dotyczy zarządzania, nadzoru albo funkcji organizacyjnej, a ESCO ogranicza pojęcie do sektora lub zawodu.",
                ["source:esco", f"verb:{token}", f"reuseLevel:{reuse}"],
                False,
            )
        if token in ORG_VERBS:
            return decision(
                "occupational_or_abstract",
                "medium",
                "Czasownik jest organizacyjny. Poziom ponownego użycia nie jest wąskozawodowy, więc wyjątek konsumencki wymaga człowieka.",
                ["source:esco", f"verb:{token}", f"reuseLevel:{reuse}"],
                True,
            )
        if token in MACHINE_VERBS and reuse in {"sector-specific", "occupation-specific"}:
            return decision(
                "occupational_or_abstract",
                "medium",
                "Czasownik dotyczy obsługi procesu albo maszyny w pojęciu sektorowym. Nie wykluczono rzadkiego zastosowania domowego.",
                ["source:esco", f"verb:{token}", f"reuseLevel:{reuse}"],
                True,
            )
        if reuse in {"sector-specific", "occupation-specific"}:
            return decision(
                "occupational_or_abstract",
                "low",
                "ESCO oznacza pojęcie jako sektorowe albo zawodowe, a tytuł nie trafił we wzorzec praktyki osobistej. Opisu nie interpretowano zdanie po zdaniu.",
                ["source:esco", f"reuseLevel:{reuse}", "no-consumer-pattern"],
                True,
            )
        return decision(
            "uncertain",
            "medium",
            "Pojęcie jest międzysektorowe albo transwersalne. Sama nazwa nie rozstrzyga, czy da się z niego zrobić praktykę na trzech poziomach.",
            ["source:esco", f"reuseLevel:{reuse}", "cross-context"],
            True,
        )
    return decision(
        "uncertain",
        "low",
        "Brak reguły dla tego źródła. Rekord nie został zgadnięty.",
        ["source:" + source, "no-rule"],
        True,
    )


def content_tokens(title: str) -> list[str]:
    tokens = re.findall(r"[a-z0-9]+", comparison_key(title))
    return [token for token in tokens if token not in STOP and len(token) > 2]


def stem_title(title: str) -> str:
    text = re.sub(r"\([^)]*\)", " ", title)
    return comparison_key(text)


def build_clusters(raw: list[dict], norms: dict[str, str]) -> tuple[list[dict], dict]:
    by_key: dict[str, list[str]] = defaultdict(list)
    by_stem: dict[str, list[str]] = defaultdict(list)
    by_desc: dict[str, list[str]] = defaultdict(list)
    titles = {}
    for row in raw:
        cid = row["candidate_id"]
        titles[cid] = row["source_title"]
        key = norms[cid]
        by_key[key].append(cid)
        stem = stem_title(row["source_title"])
        if stem and stem != key:
            by_stem[stem].append(cid)
        elif stem:
            by_stem[stem].append(cid)
        description = comparison_key(row.get("source_description"))
        if len(description) >= 40:
            by_desc[description].append(cid)

    clusters = []
    for key, members in sorted(by_key.items()):
        if len(members) < 2:
            continue
        sources = {cid.split(":", 1)[0] for cid in members}
        same_source = len(sources) == 1
        clusters.append(
            {
                "cluster_id": cluster_id("exact", key, members),
                "similarity_type": "identical_normalized_title",
                "confidence": "high" if same_source else "medium",
                "human_review_required": True,
                "reason": "Ta sama znormalizowana nazwa. Identyczny tytuł nie rozstrzyga, czy praktyka jest ta sama.",
                "candidate_ids": sorted(members),
            }
        )
    for stem, members in sorted(by_stem.items()):
        keys = {norms[cid] for cid in members}
        if len(members) < 2 or len(keys) < 2:
            continue
        clusters.append(
            {
                "cluster_id": cluster_id("variant", stem, members),
                "similarity_type": "parenthetical_or_punctuation_variant",
                "confidence": "medium",
                "human_review_required": True,
                "reason": "Po usunięciu nawiasów albo zbędnej interpunkcji zostaje wspólny rdzeń. To może być wariant, nie duplikat.",
                "candidate_ids": sorted(members),
            }
        )
    for _description, members in sorted(by_desc.items()):
        if len(members) < 2:
            continue
        clusters.append(
            {
                "cluster_id": cluster_id("description", titles[members[0]], members),
                "similarity_type": "identical_source_description",
                "confidence": "low",
                "human_review_required": True,
                "reason": "Długi opis źródłowy jest identyczny, a tytuły mogą nazywać różne czynności. Identyczny opis nie scala rekordów.",
                "candidate_ids": sorted(members),
            }
        )

    token_sets = {row["candidate_id"]: content_tokens(row["source_title"]) for row in raw}
    frequency: Counter[str] = Counter()
    for tokens in token_sets.values():
        frequency.update(set(tokens))
    buckets: dict[str, list[str]] = defaultdict(list)
    unscanned = []
    for cid, tokens in token_sets.items():
        if len(tokens) < 2:
            continue
        ordered = sorted(set(tokens), key=lambda token: (frequency[token], token))
        placed = False
        for token in ordered:
            if frequency[token] <= 400:
                buckets[token].append(cid)
                placed = True
                break
        if not placed:
            unscanned.append(cid)

    parent = {}

    def find(cid: str) -> str:
        parent.setdefault(cid, cid)
        while parent[cid] != cid:
            parent[cid] = parent[parent[cid]]
            cid = parent[cid]
        return cid

    def union(left: str, right: str) -> None:
        left_root = find(left)
        right_root = find(right)
        if left_root != right_root:
            parent[right_root] = left_root

    comparisons = 0
    lexical_pairs = 0
    for token, members in buckets.items():
        if len(members) > 400:
            unscanned.extend(members)
            continue
        for index, left in enumerate(members):
            left_tokens = set(token_sets[left])
            for right in members[index + 1 :]:
                comparisons += 1
                if norms[left] == norms[right]:
                    continue
                right_tokens = set(token_sets[right])
                shared = left_tokens & right_tokens
                if len(shared) < 2:
                    continue
                union_size = len(left_tokens | right_tokens)
                if union_size == 0 or len(shared) / union_size < 0.8:
                    continue
                if len(left_tokens ^ right_tokens) > 2:
                    continue
                union(left, right)
                lexical_pairs += 1
    groups: dict[str, list[str]] = defaultdict(list)
    for cid in list(parent):
        groups[find(cid)].append(cid)
    for members in groups.values():
        if len(members) < 2:
            continue
        label = min((titles[cid] for cid in members), key=len)
        clusters.append(
            {
                "cluster_id": cluster_id("lexical", label, members),
                "similarity_type": "lexical_near_title",
                "confidence": "low",
                "human_review_required": True,
                "reason": "Tytuły mają co najmniej dwa wspólne tokeny, podobieństwo Jaccarda co najmniej 0,8 i różnią się najwyżej dwoma tokenami. To nie jest porównanie znaczenia.",
                "candidate_ids": sorted(members),
            }
        )
    stats = {
        "identical_title_groups": sum(1 for members in by_key.values() if len(members) > 1),
        "source_item_id_groups": 0,
        "parenthetical_groups": sum(
            1
            for members in by_stem.values()
            if len(members) > 1 and len({norms[cid] for cid in members}) > 1
        ),
        "identical_description_groups": sum(1 for members in by_desc.values() if len(members) > 1),
        "lexical_pairs": lexical_pairs,
        "lexical_comparisons": comparisons,
        "lexical_unscanned_records": len(set(unscanned)),
        "semantic_comparison_performed": False,
        "synonym_comparison_performed": False,
    }
    return clusters, stats


def area_hits(raw: list[dict], triage: dict[str, dict]) -> list[dict]:
    compiled = [(label, re.compile(pattern, re.I)) for label, pattern in AREAS]
    rows = []
    for label, pattern in compiled:
        matched = [row for row in raw if pattern.search(row["source_title"])]
        promising = [
            row
            for row in matched
            if triage[row["candidate_id"]]["suitability"] in {"strong_candidate", "adaptable_candidate"}
        ]
        rows.append(
            {
                "area": label,
                "title_hits": len(matched),
                "promising_hits": len(promising),
            }
        )
    return rows


def write_method() -> None:
    text = """# Metoda triage i grupowania — T4S-CATALOG-003

Data: 2026-10-18. Skrypt: `build_catalog_003.py`.

To jest heurystyka deterministyczna. Nie jest oceną ekspercką i nie zatwierdza skillów. Żaden rekord nie został usunięty ani scalony. Nie wywołano zewnętrznego modelu.

## Klasyfikacja

Pytanie robocze: czy pozycja może być samodzielną praktyką, którą osoba niebędąca ekspertem rozwija na trzech odróżnialnych poziomach?

Reguły stosowane są w stałej kolejności. Pierwsza pasująca wygrywa. Sygnał `rule` jest w polu `signals` pośrednio przez etykiety źródła i cechy; pełna kolejność jest w skrypcie.

- Węzeł taksonomii O*NET oraz nagłówek działu OpenLearn są rozstrzygane z typu rekordu.
- Odznaki Skautów bez tekstu wymagań dostają `uncertain`, poza nazwami mundurowymi i okolicznościowymi.
- Źródła z etapu T4S-CATALOG-002 dostają `strong_candidate` tylko wtedy, gdy zapis opisuje powtarzalną praktykę. Nazwy programów, rodzin tańca, przykładów projektów i postaw dostają `adaptable_candidate`.
- Rzemiosło z nawiasem jest traktowane jako wariant. Sama nazwa rzemiosła jest `strong_candidate` ze średnią pewnością, bo artykułu nie czytano.
- Wikidata nie jest uznawana za przydatną tylko dlatego, że rekord jest na liście hobby. Pusty opis daje `uncertain`. Opis przedmiotu, zawodu albo zbioru daje `not_a_distinct_skill`.
- ESCO nie jest hurtowo odrzucane. `skillType=knowledge` oznacza pojęcie albo obszar. Wąski wzorzec tytułu, na przykład gra na instrumencie, daje `adaptable_candidate` także przy wysokim reuseLevel zawodowym. Reszta pojęć sektorowych i zawodowych dostaje `occupational_or_abstract` z niską albo średnią pewnością, bo opisu nie interpretowano zdanie po zdaniu. Pojęcia międzysektorowe i transwersalne bez takiego wzorca dostają `uncertain`.
- Wysoka pewność i brak indywidualnej recenzji dotyczy tylko reguł strukturalnych: węzeł taksonomii, nagłówek kursów, odznaka okolicznościowa, tytuł „types of” i pokrewne oraz czasownik organizacyjny przy reuseLevel sektorowym albo zawodowym, a także szczegółowe czynności O*NET już oznaczone jako pojęcie zawodowe.

`human_review_required` jest prawdziwe dla każdej pozycji obiecującej, niepewnej i dla reguł o pewności średniej albo niskiej. Fałsz nie oznacza zatwierdzenia odrzucenia. Oznacza, że ta heurystyka nie kieruje rekordu do indywidualnej lektury w następnym kroku.

## Grupowanie

Nie wykonano porównania synonimów ani porównania semantycznego.

1. Identyczna znormalizowana nazwa (`comparison_key` z pliku znormalizowanego).
2. Ten sam `source_item_id` w obrębie źródła. W tym zbiorze takich grup nie było.
3. Rdzeń tytułu po usunięciu nawiasów, jeśli powstaje więcej niż jedna nazwa.
4. Identyczny opis źródłowy o długości co najmniej 40 znaków. Niska pewność, bo ten sam akapit może opisywać różne czynności.
5. Podobieństwo leksykalne tytułu: tokeny dłuższe niż dwa znaki, bez krótkich przyimków; co najmniej dwa tokeny wspólne; Jaccard co najmniej 0,8; różnica symetryczna co najwyżej dwa tokeny. Blokowanie idzie po najrzadszym tokenie, którego częstość nie przekracza 400. Rekordy złożone wyłącznie z bardzo częstych tokenów nie wchodzą do porównań parami.

Podobieństwo nazwy nie scala rekordów. Grupy o wysokiej pewności też wymagają człowieka, gdy tytuł może być homonimem albo tą samą odznaką w innej sekcji wiekowej.

## Ograniczenia

- Wzorzec praktyki osobistej w ESCO jest krótki i celowo wąski. Pomija część prawdziwych praktyk i może złapać tytuł zawodowy o podobnych słowach.
- Opisy ESCO i O*NET nie były czytane pojedynczo.
- Brak synonimów: „throwing” i „rzut” nie zostaną połączone, podobnie jak para opisująca to samo innymi słowami.
- Jaccard nie rozumie, że dwa podobne ciągi znaków mogą być różnymi praktykami.
"""
    (DOCS_DIR / "triage-method.md").write_text(text, encoding="utf-8")


def write_profile(raw: list[dict], triage: list[dict], areas: list[dict], cluster_stats: dict) -> None:
    by_source = Counter(row["source_id"] for row in raw)
    by_type = Counter(row["candidate_type"] for row in raw)
    by_language = Counter(row["source_language"] for row in raw)
    by_relevance = Counter(row["consumer_relevance"] for row in raw)
    missing_description = sum(1 for row in raw if not norm_text(row.get("source_description")))
    missing_category = sum(1 for row in raw if not norm_text(row.get("source_category")))
    missing_url = sum(1 for row in raw if not norm_text(row.get("source_url")))
    missing_title = sum(1 for row in raw if not norm_text(row.get("source_title")))
    hint_null = sum(1 for row in raw if row.get("adaptation_hint") is None)
    categories = Counter(row.get("source_category") or "" for row in raw)
    triage_by_id = {row["candidate_id"]: row for row in triage}
    suitability = Counter(row["suitability"] for row in triage)
    promising_by_source = Counter(
        row["source_id"]
        for row in raw
        if triage_by_id[row["candidate_id"]]["suitability"] in {"strong_candidate", "adaptable_candidate"}
    )
    occupational_parents = Counter()
    for row in raw:
        if not row["source_id"].startswith("esco"):
            continue
        if triage_by_id[row["candidate_id"]]["suitability"] != "occupational_or_abstract":
            continue
        parent = (row.get("source_category") or "brak etykiety").split("; ")[0]
        occupational_parents[parent] += 1

    def example(predicate) -> dict | None:
        for row in raw:
            if predicate(row):
                return {
                    "candidate_id": row["candidate_id"],
                    "source_id": row["source_id"],
                    "source_title": row["source_title"],
                    "suitability": triage_by_id[row["candidate_id"]]["suitability"],
                }
        return None

    examples_fit = [
        example(lambda row: row["source_title"] == "How to master basic knife skills"),
        example(lambda row: row["source_title"] == "contours"),
        example(lambda row: row["source_title"] == "Blacksmithing"),
        example(lambda row: row["source_id"] == "wikidata-hobbies" and row["source_title"] == "pottery"),
        example(lambda row: row["source_title"] == "play the piano"),
    ]
    examples_unfit = [
        example(lambda row: row["source_title"] == "manage musical staff"),
        example(lambda row: row["source_title"] == "Abilities"),
        example(lambda row: row["source_title"] == "Digital & Computing"),
        example(lambda row: "Birthday" in row["source_title"]),
        example(lambda row: row["source_title"].casefold().startswith("types of cooktops")),
    ]
    profile = {
        "generated_on": TODAY,
        "record_count": len(raw),
        "by_source": dict(by_source.most_common()),
        "by_candidate_type": dict(by_type.most_common()),
        "by_language": dict(by_language),
        "by_consumer_relevance_mechanical": dict(by_relevance),
        "incomplete_fields": {
            "missing_source_description": missing_description,
            "missing_source_category": missing_category,
            "missing_source_url": missing_url,
            "missing_source_title": missing_title,
            "adaptation_hint_null": hint_null,
        },
        "repeated_normalized_titles": cluster_stats["identical_title_groups"],
        "repeated_source_item_id_groups": cluster_stats["source_item_id_groups"],
        "top_source_categories": categories.most_common(15),
        "largest_occupational_parent_labels": occupational_parents.most_common(10),
        "area_scan": areas,
        "suitability_counts": dict(suitability),
        "promising_by_source": dict(promising_by_source.most_common()),
        "examples_that_fit_the_app_question": [item for item in examples_fit if item],
        "examples_that_likely_do_not_fit": [item for item in examples_unfit if item],
        "notes": [
            "consumer_relevance is the earlier mechanical tag. It is not the triage decision.",
            "ESCO volume is not evidence of consumer usefulness.",
            "Area scan is a title regex and can count one record in several areas.",
        ],
    }
    (DATA / "catalog-profile.json").write_text(
        json.dumps(profile, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    lines = [
        "# Profil bazy kandydatur",
        "",
        f"Data: {TODAY}. Liczba rekordów: **{len(raw)}**.",
        "Liczebność źródła nie jest oceną przydatności. ESCO ma większość wierszy, ponieważ zaimportowano cały filar umiejętności.",
        "",
        "## Według źródła",
        "",
    ]
    for source_id, count in by_source.most_common():
        lines.append(f"- `{source_id}`: {count}")
    lines.extend(["", "## Według typu", ""])
    for key, count in sorted(by_type.items()):
        lines.append(f"- {key}: {count}")
    lines.extend(["", "## Według języka", ""])
    for key, count in sorted(by_language.items()):
        lines.append(f"- {key}: {count}")
    lines.extend(
        [
            "",
            "## Według kategorii źródłowej",
            "",
            "Pole `source_category` jest wypełnione w każdym rekordzie, ale nie jest jedną taksonomią. W ESCO są to etykiety nadrzędne. Poniżej 15 najczęstszych wartości całego pola.",
            "",
        ]
    )
    for label, count in categories.most_common(15):
        lines.append(f"- {label}: {count}")
    lines.extend(
        [
            "",
            "## Pola niepełne",
            "",
            f"- Brak `source_description`: {missing_description}.",
            f"- Brak `source_category`: {missing_category}.",
            f"- Brak `source_url`: {missing_url}.",
            f"- Brak `source_title`: {missing_title}.",
            f"- `adaptation_hint` puste: {hint_null}. To pole było puste celowo i nie jest brakiem importu.",
            f"- Mechaniczny `consumer_relevance`: high {by_relevance['high']}, medium {by_relevance['medium']}, low {by_relevance['low']}, unclear {by_relevance['unclear']}. To nie jest triage.",
            "",
            "## Powtórzenia",
            "",
            f"- Grupy o identycznej znormalizowanej nazwie: {cluster_stats['identical_title_groups']}.",
            f"- Grupy o tym samym `source_item_id`: {cluster_stats['source_item_id_groups']}.",
            "",
            "## Duże grupy zawodowe i abstrakcyjne",
            "",
            "Poniższe liczniki biorą rekordy ESCO sklasyfikowane heurystycznie jako `occupational_or_abstract` i ich pierwszą etykietę nadrzędną. To nie jest lista skillów do usunięcia.",
            "",
        ]
    )
    for label, count in occupational_parents.most_common(10):
        lines.append(f"- {label}: {count}")
    lines.extend(
        [
            "",
            "## Dziedziny: trafienia w tytule i część obiecująca",
            "",
            "Skan tytułu jest leksykalny. Jedna pozycja może wejść do kilku dziedzin. Duża liczba trafień często pochodzi z ESCO i nie oznacza bogatego materiału konsumenckiego. Kolumna obiecujących liczy tylko `strong_candidate` i `adaptable_candidate`.",
            "",
            "| Dziedzina | Trafienia w tytule | Z tego obiecujące |",
            "| --- | ---: | ---: |",
        ]
    )
    for area in areas:
        lines.append(f"| {area['area']} | {area['title_hits']} | {area['promising_hits']} |")
    lines.extend(["", "## Przykłady bliższe pytaniu aplikacji", ""])
    for item in examples_fit:
        if item:
            lines.append(
                f"- `{item['candidate_id']}` — {item['source_title']} ({item['source_id']}, {item['suitability']})"
            )
    lines.extend(["", "## Przykłady, które najpewniej nie są skillami katalogu", ""])
    for item in examples_unfit:
        if item:
            lines.append(
                f"- `{item['candidate_id']}` — {item['source_title']} ({item['source_id']}, {item['suitability']})"
            )
    lines.extend(
        [
            "",
            "Przykłady wybrano jako ilustrację reguł, nie jako zatwierdzoną listę.",
            "",
        ]
    )
    (DOCS_DIR / "catalog-profile.md").write_text("\n".join(lines), encoding="utf-8")


def write_report(raw: list[dict], triage: list[dict], clusters: list[dict], cluster_stats: dict) -> None:
    suitability = Counter(row["suitability"] for row in triage)
    confidence = Counter(row["confidence"] for row in triage)
    review = sum(1 for row in triage if row["human_review_required"])
    by_id = {row["candidate_id"]: row for row in triage}
    promising = {"strong_candidate", "adaptable_candidate"}
    by_source = Counter()
    promising_source = Counter()
    for row in raw:
        label = by_id[row["candidate_id"]]["suitability"]
        by_source[(row["source_id"], label)] += 1
        if label in promising:
            promising_source[row["source_id"]] += 1
    cluster_types = Counter(cluster["similarity_type"] for cluster in clusters)
    cluster_confidence = Counter(cluster["confidence"] for cluster in clusters)
    high_clusters = sum(1 for cluster in clusters if cluster["confidence"] == "high")
    review_clusters = sum(1 for cluster in clusters if cluster["human_review_required"])
    promising_ids = {row["candidate_id"] for row in triage if row["suitability"] in promising}
    exact_extra = 0
    for cluster in clusters:
        if cluster["similarity_type"] != "identical_normalized_title":
            continue
        if cluster["confidence"] != "high":
            continue
        members = [cid for cid in cluster["candidate_ids"] if cid in promising_ids]
        if len(members) > 1:
            exact_extra += len(members) - 1
    promising_count = sum(suitability[name] for name in promising)
    estimate = promising_count - exact_extra
    lines = [
        "# Raport triage kandydatur",
        "",
        f"Data: {TODAY}. Sklasyfikowano {len(triage)} z {len(raw)} rekordów. Niesklasyfikowanych: 0.",
        "To propozycja heurystyczna. Nie zatwierdza finalnych skillów i nie usuwa rekordów.",
        "",
        "## Liczby klasyfikacji",
        "",
        f"- `strong_candidate`: {suitability['strong_candidate']}",
        f"- `adaptable_candidate`: {suitability['adaptable_candidate']}",
        f"- `occupational_or_abstract`: {suitability['occupational_or_abstract']}",
        f"- `not_a_distinct_skill`: {suitability['not_a_distinct_skill']}",
        f"- `uncertain`: {suitability['uncertain']}",
        "",
        f"Pewność: high {confidence['high']}, medium {confidence['medium']}, low {confidence['low']}.",
        f"Kandydatury z `human_review_required`: {review}.",
        (
            "W tej liczbie priorytetem następnego czytania są "
            f"{suitability['strong_candidate'] + suitability['adaptable_candidate'] + suitability['uncertain']} "
            "rekordów obiecujących albo niepewnych. Reszta flagi dotyczy głównie pojęć zawodowych o pewności niskiej lub średniej. "
            "Nie trzeba ich czytać pojedynczo przed próbką."
        ),
        "",
        "## Obiecujący materiał według źródła",
        "",
        "Suma `strong_candidate` i `adaptable_candidate`. Liczba nie jest oceną jakości ani liczbą unikalnych skillów.",
        "",
        "| Źródło | Obiecujące | strong | adaptable | occupational | not a skill | uncertain |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for source_id, _count in promising_source.most_common():
        lines.append(
            "| `{0}` | {1} | {2} | {3} | {4} | {5} | {6} |".format(
                source_id,
                promising_source[source_id],
                by_source[(source_id, "strong_candidate")],
                by_source[(source_id, "adaptable_candidate")],
                by_source[(source_id, "occupational_or_abstract")],
                by_source[(source_id, "not_a_distinct_skill")],
                by_source[(source_id, "uncertain")],
            )
        )
    lines.extend(
        [
            "",
            "Źródła spoza tabeli, w tym odznaki Skautów i nagłówki OpenLearn, mają zero rekordów obiecujących: odznaki są `uncertain`, nagłówki są `not_a_distinct_skill`.",
            "Najwięcej obiecujących rekordów dają inwentarz rzemiosł i Wikidata, potem nieduże źródła praktyczne z etapu T4S-CATALOG-002. ESCO prawie nie wchodzi do tej sumy, mimo że ma 13939 rekordów. To jest skutek reguły, nie dowód, że w ESCO nie ma praktyk. Wąski wzorzec tytułu złapał tylko dopasowania w rodzaju gry na instrumencie, tańca albo pływania.",
            "",
            "## Grupy podobieństw",
            "",
            f"- Grupy identycznych nazw: {cluster_stats['identical_title_groups']}.",
            f"- Grupy tego samego identyfikatora źródłowego: {cluster_stats['source_item_id_groups']}.",
            f"- Grupy rdzenia po nawiasie: {cluster_stats['parenthetical_groups']}.",
            f"- Grupy identycznego opisu: {cluster_stats['identical_description_groups']}.",
            f"- Pary leksykalne, z których powstały składowe: {cluster_stats['lexical_pairs']}. Porównań w blokach: {cluster_stats['lexical_comparisons']}.",
            f"- Rekordy pominięte w porównaniu leksykalnym, bo nie miały rzadkiego tokenu: {cluster_stats['lexical_unscanned_records']}.",
            f"- Wszystkie grupy w `duplicate-clusters.json`: {len(clusters)}.",
            f"- Grupy o pewności high: {high_clusters}. Grupy wymagające człowieka: {review_clusters}.",
            f"- Typy grup: {', '.join(f'{key} {value}' for key, value in sorted(cluster_types.items()))}.",
            "- Porównania synonimów nie wykonano. Porównania semantycznego nie wykonano.",
            "- Przykład, że bliski tytuł nie jest duplikatem: `interpret 2D plans` i `interpret 3D plans` oraz pary z „hazardous” i „non-hazardous”. Zostały w grupie leksykalnej o niskiej pewności i wymagają człowieka. Nie scalono ich.",
            "",
            "Rekordy, grupy i umiejętności to trzy różne liczby.",
            "",
            f"- Rekordy obiecujące (`strong_candidate` + `adaptable_candidate`): {promising_count}.",
            f"- Dodatkowe kopie w grupach identycznej nazwy o pewności high, ograniczone do rekordów obiecujących: {exact_extra}.",
            f"- Niezweryfikowany szacunek różnych obiecujących pozycji po odjęciu tych kopii: {estimate}.",
            "Tego szacunku nie traktować jako liczby skillów. Nie odejmuje grup leksykalnych, rodzin tańca ani wariantów rzemiosła o niższej pewności. Nie sprawdza, czy dwie różne nazwy są jedną praktyką.",
            "",
            "## Co analizować najpierw",
            "",
            "1. Rzemiosła Heritage Crafts oznaczone jako `strong_candidate`: czy nazwa naprawdę niesie trzy poziomy, czy jest zbyt wąskim wyrobem.",
            "2. Warianty w nawiasie: czy zostawić je poza katalogiem jako uszczegółowienie.",
            "3. Praktyki z etapu T4S-CATALOG-002: mapa, gotowanie, ruch, taniec, pisanie, finanse. To najbliższe gotowe opisy.",
            "4. Wikidata z opisem praktyki: oddzielić sport, rzemiosło i zbyt wąskie hobby.",
            "5. Rodziny tańca WDSF i programy Astronomical League: przepisać nazwę programu na czynność albo zostawić jako materiał, nie skill.",
            "6. Identyczne tytuły odznak Skautów w kilku sekcjach wiekowych. Same odznaki zostają `uncertain`, dopóki nie ma wymagań.",
            "7. Krótka lista ESCO z wzorcem praktyki osobistej (`play the piano`, taniec, pływanie, szycie ręczne).",
            "8. Próbka `uncertain` wśród umiejętności międzysektorowych ESCO, najpierw pisanie, naprawa i gotowanie domowe, nie zarządzanie.",
            "9. Umiejętności przenośne O*NET: które da się przepisać bez języka stanowiska pracy.",
            "10. Nakładki już opisane w raporcie pokrycia: mapa USGS i orientacja, breaking, uderzanie i łapanie.",
            "",
            "## Ograniczenia",
            "",
            "- Reguły nie czytały opisów ESCO i O*NET poza polami `skillType`, `reuseLevel` i typem rekordu.",
            "- Wysoka liczba `occupational_or_abstract` wynika głównie z tych pól, nie z recenzji każdej nazwy.",
            "- `strong_candidate` przy rzemiośle opiera się na nazwie z inwentarza. Artykułów nie było w rekordzie.",
            "- Heurystyka może uznać wąskie rzemiosło za obiecujące i pominąć praktykę ESCO, której tytuł nie trafił we wzorzec.",
            "- Grupy podobieństw są propozycjami. Żadnej nie scalono.",
            "",
            "## Następny etap do shortlisty 1001",
            "",
            "Nie promować hurtowo pojęć zawodowych, żeby dobić liczbę. Najpierw człowiek przegląda `strong_candidate` i `adaptable_candidate`, korzystając z grup identycznych nazw i wariantów w nawiasie. Z grupy bierze jedną praktykę i zostawia pozostałe identyfikatory w pochodzeniu. Tytuły adaptowalne przepisuje na czynność, której da się bronić trzema poziomami. Dopiero potem losuje próbkę `uncertain` z ESCO międzysektorowego i z odznak, których wymagania nadal nie są w bazie. Jeśli po tej recenzji zostanie wyraźnie mniej niż 1001 praktyk, brak uzupełniać nowymi źródłami dziedzin rzadkich, a nie kolejnym zrzutem kompetencji stanowiskowych.",
            "",
            "Szczegóły reguł: `triage-method.md`.",
            "",
        ]
    )
    (DOCS_DIR / "catalog-triage-report.md").write_text("\n".join(lines), encoding="utf-8")


def update_readme() -> None:
    path = DOCS_DIR / "README.md"
    text = path.read_text(encoding="utf-8")
    old = "Pula jest liczna, ponieważ filar umiejętności ESCO został zapisany w całości. Większość tych pojęć jest zawodowa. Osobne pliki nie zawierają poziomów, punktacji ani widoku katalogu. `duplicate-clusters.json` jest pustym schematem: deduplikacja nie była uruchamiana."
    new = "Pula jest liczna, ponieważ filar umiejętności ESCO został zapisany w całości. Większość tych pojęć jest zawodowa. Osobne pliki nie zawierają poziomów, punktacji ani widoku katalogu. `duplicate-clusters.json` zawiera propozycje grup z etapu T4S-CATALOG-003. Rekordy nie zostały scalone ani usunięte."
    if old not in text:
        if "T4S-CATALOG-003" not in text:
            raise SystemExit("README paragraph not found")
        return
    addition = (
        "\n\n## T4S-CATALOG-003\n\n"
        "Profil, triage i grupy są w `catalog-profile.md`, `catalog-profile.json`, "
        "`candidate-triage.jsonl`, `duplicate-clusters.json`, `catalog-triage-report.md` "
        "i `triage-method.md`. Odtworzenie: `python3 scripts/catalog/build_catalog_003.py`. "
        "Ten etap nie zatwierdza skillów. Nie zmienia `candidates-raw.jsonl` ani `sources.json`.\n"
    )
    if "## T4S-CATALOG-003" not in text:
        text = text.replace(old, new) + addition
    else:
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")


def main() -> None:
    check_only(
        [
            DATA / "candidates-raw.jsonl",
            DATA / "candidates-normalized.jsonl",
            DATA / "sources.json",
            DOCS_DIR / "README.md",
        ]
    )
    raw_path = DATA / "candidates-raw.jsonl"
    norm_path = DATA / "candidates-normalized.jsonl"
    sources_path = DATA / "sources.json"
    before = {path.name: sha256(path) for path in (raw_path, norm_path, sources_path)}
    raw = [json.loads(line) for line in raw_path.read_text(encoding="utf-8").splitlines()]
    normalized = [json.loads(line) for line in norm_path.read_text(encoding="utf-8").splitlines()]
    norms = {row["raw_candidate_id"]: row["comparison_key"] for row in normalized}
    if set(norms) != {row["candidate_id"] for row in raw}:
        raise SystemExit("Normalized ids do not match raw ids")
    triage = []
    for row in raw:
        item = classify(row)
        triage.append(
            {
                "candidate_id": row["candidate_id"],
                "suitability": item["suitability"],
                "confidence": item["confidence"],
                "reason": item["reason"],
                "signals": item["signals"],
                "human_review_required": item["human_review_required"],
            }
        )
    if len(triage) != len(raw):
        raise SystemExit("Triage did not cover every record")
    clusters, stats = build_clusters(raw, norms)
    # same source_item_id check, reported even when empty
    seen = defaultdict(list)
    for row in raw:
        seen[(row["source_id"], row["source_item_id"])].append(row["candidate_id"])
    stats["source_item_id_groups"] = sum(1 for members in seen.values() if len(members) > 1)
    areas = area_hits(raw, {row["candidate_id"]: row for row in triage})
    write_method()
    write_profile(raw, triage, areas, stats)
    write_report(raw, triage, clusters, stats)
    cluster_document = {
        "schema_version": 2,
        "status": "proposed",
        "deduplication_performed": False,
        "records_removed": 0,
        "records_merged": 0,
        "generated_on": TODAY,
        "algorithm": "exact normalized title; identical source item id; parenthetical stem; identical long description; blocked lexical Jaccard on titles",
        "semantic_comparison_performed": False,
        "synonym_comparison_performed": False,
        "cluster_count": len(clusters),
        "high_confidence_cluster_count": sum(1 for cluster in clusters if cluster["confidence"] == "high"),
        "human_review_cluster_count": sum(1 for cluster in clusters if cluster["human_review_required"]),
        "counts_by_similarity_type": dict(Counter(cluster["similarity_type"] for cluster in clusters)),
        "counts_by_confidence": dict(Counter(cluster["confidence"] for cluster in clusters)),
        "lexical_unscanned_records": stats["lexical_unscanned_records"],
        "lexical_comparisons": stats["lexical_comparisons"],
        "limitations": [
            "Groups are proposals. Source records were not merged or deleted.",
            "No synonym list and no semantic comparison were run.",
            "An identical title can still be two practices. A different wording can still be one practice.",
            "Lexical comparison uses titles only and skips records whose tokens are all very common.",
        ],
        "clusters": clusters,
    }
    (DATA / "duplicate-clusters.json").write_text(
        json.dumps(cluster_document, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (DATA / "candidate-triage.jsonl").write_text(
        "".join(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n" for row in triage),
        encoding="utf-8",
    )
    update_readme()
    after = {path.name: sha256(path) for path in (raw_path, norm_path, sources_path)}
    if before != after:
        raise SystemExit(f"Source files changed: {before} {after}")
    print("records", len(raw))
    print("triage", Counter(row["suitability"] for row in triage))
    print("review", sum(1 for row in triage if row["human_review_required"]))
    print("clusters", len(clusters), stats)


if __name__ == "__main__":
    main()
