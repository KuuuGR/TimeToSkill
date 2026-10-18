#!/usr/bin/env python3
"""Rebuild the 1001 Skills candidate files from public sources.

Downloads are cached under /tmp/t4s-catalog and are not written into the
repository. The script overwrites data/skills-catalog/research and the
matching reports in docs/catalog-research. It does not select a final
catalogue, assign levels, or deduplicate. Pass --check to verify paths
and exit before any download or write.
"""

from __future__ import annotations

import csv
import io
import json
import re
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from collections import Counter, defaultdict
from html import unescape
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from layout import DOCS, RESEARCH, check_only

OUT_DIR = RESEARCH
DOC_DIR = DOCS
CACHE = Path("/tmp/t4s-catalog")
RETRIEVED_ON = "2026-10-18"
UA = "Time4Skill-catalog-research/1.0 (public research extract; contact: local research script)"

REQUIRED_KEYS = [
    "candidate_id",
    "source_id",
    "source_item_id",
    "source_title",
    "source_description",
    "source_url",
    "source_language",
    "source_category",
    "candidate_type",
    "consumer_relevance",
    "adaptation_hint",
    "provenance_note",
]
CANDIDATE_TYPES = {
    "skill",
    "praktyczna czynność",
    "obszar wiedzy",
    "hobby",
    "aktywność",
    "pojęcie zawodowe",
    "węzeł taksonomii",
    "zdolność",
}
RELEVANCE = {"high", "medium", "low", "unclear"}

OPENLEARN_HEADINGS = {
    "Health, Sports & Psychology": "health-sports-psychology",
    "Education & Development": "education-development",
    "History & The Arts": "history-the-arts",
    "Languages": "languages",
    "Money & Business": "money-business",
    "Nature & Environment": "nature-environment",
    "Science, Maths & Technology": "science-maths-technology",
    "Society, Politics & Law": "society-politics-law",
    "Digital & Computing": "digital-computing",
}

AREA_PATTERNS = [
    ("Nawigacja, mapa i orientacja", ["navigat", "orienteer", "map reading", "compass"]),
    ("Astronomia amatorska", ["astronom", "stargaz", "telescope", "constellation"]),
    ("Obserwacja przyrody", ["birdwatch", "wildlife", "botan", "foraging", "nature study"]),
    ("Nauka obywatelska", ["citizen science"]),
    ("Majsterkowanie, elektronika, naprawa, modelarstwo", ["electron", "solder", "repair", "woodwork", "model mak", "model engineer"]),
    ("Rytm, taniec, koordynacja", ["danc", "rhythm", "choreograph", "coordination"]),
    ("Retoryka, negocjacje, słuchanie", ["rhetor", "negotiat", "active listening", "public speak"]),
    ("Pamięć, rozumowanie, analiza", ["memory", "reasoning", "problem solv", "critical think"]),
    ("Gotowanie i żywność", ["cook", "baking", "cuisine", "food prepar"]),
    ("Organizacja życia i samodzielność", ["self-reliance", "housekeep", "time management", "personal organis"]),
    ("Finanse osobiste", ["personal finance", "budget", "household financ"]),
    ("Rzemiosło", ["blacksmith", "weaving", "pottery", "wood carv", "leather"]),
    ("Instrumenty", ["musical instrument", "guitar", "piano", "violin"]),
    ("Fotografia", ["photograph"]),
    ("Pisanie", ["creative writing", "writing"]),
]


def http_get(url: str, accept: str = "*/*") -> tuple[int, bytes]:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": UA, "Accept": accept},
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as error:
        body = error.read() if error.fp is not None else b""
        return error.code, body


def cached_download(url: str, dest: Path, refresh: bool = False) -> tuple[str, int]:
    CACHE.mkdir(parents=True, exist_ok=True)
    if dest.exists() and dest.stat().st_size > 0 and not refresh:
        return "cache", dest.stat().st_size
    status, body = http_get(url)
    if status != 200 or not body:
        raise RuntimeError(f"{url} returned HTTP {status}, {len(body)} bytes")
    dest.write_bytes(body)
    return "downloaded", len(body)


def norm_text(value: str | None) -> str | None:
    if value is None:
        return None
    text = unicodedata.normalize("NFC", value).replace("\u00a0", " ")
    text = re.sub(r"\s+", " ", text).strip()
    return text or None


def comparison_key(title: str) -> str:
    collapsed = norm_text(title) or ""
    return unicodedata.normalize("NFKC", collapsed).casefold()


def record(
    candidate_id: str,
    source_id: str,
    source_item_id: str | None,
    source_title: str,
    source_description: str | None,
    source_url: str,
    source_category: str | None,
    candidate_type: str,
    consumer_relevance: str,
    provenance_note: str,
) -> dict:
    return {
        "candidate_id": candidate_id,
        "source_id": source_id,
        "source_item_id": source_item_id,
        "source_title": norm_text(source_title),
        "source_description": norm_text(source_description),
        "source_url": source_url,
        "source_language": "en",
        "source_category": norm_text(source_category),
        "candidate_type": candidate_type,
        "consumer_relevance": consumer_relevance,
        "adaptation_hint": None,
        "provenance_note": norm_text(provenance_note),
    }


def load_esco(rows: list[dict], facts: dict) -> None:
    zip_path = CACHE / "esco_v121_en_csv.zip"
    url = "https://ec.europa.eu/esco/download/ESCO%20dataset%20-%20v1.2.1%20-%20classification%20-%20en%20-%20csv.zip"
    how, size = cached_download(url, zip_path)
    facts["esco_fetch"] = {"url": url, "cache": how, "zip_bytes": size}
    with zipfile.ZipFile(zip_path) as archive:
        with archive.open("skills_en.csv") as raw_skills:
            skills = list(csv.DictReader(io.TextIOWrapper(raw_skills, encoding="utf-8")))
        with archive.open("broaderRelationsSkillPillar_en.csv") as raw_relations:
            relations = list(csv.DictReader(io.TextIOWrapper(raw_relations, encoding="utf-8")))
    broader: dict[str, list[str]] = defaultdict(list)
    for relation in relations:
        if relation["conceptType"] != "KnowledgeSkillCompetence":
            continue
        label = norm_text(relation["broaderLabel"])
        if label and label not in broader[relation["conceptUri"]]:
            broader[relation["conceptUri"]].append(label)
    grouped: dict[str, list[dict]] = defaultdict(list)
    for row in skills:
        grouped[row["conceptUri"]].append(row)
    conflicting = 0
    identical_extra = 0
    for uri, copies in grouped.items():
        first = copies[0]
        if len(copies) > 1:
            if all(copy == first for copy in copies[1:]):
                identical_extra += len(copies) - 1
            else:
                conflicting += 1
        title = norm_text(first["preferredLabel"])
        if not title or not uri:
            continue
        skill_type = (first.get("skillType") or "").strip()
        reuse = (first.get("reuseLevel") or "").strip()
        if skill_type == "knowledge":
            candidate_type = "obszar wiedzy"
        elif skill_type == "skill/competence":
            candidate_type = "skill"
        else:
            candidate_type = "skill"
        if reuse in {"transversal", "cross-sector"}:
            relevance = "medium"
        elif reuse in {"sector-specific", "occupation-specific"}:
            relevance = "low"
        else:
            relevance = "unclear"
        uuid = uri.rstrip("/").rsplit("/", 1)[-1]
        labels = broader.get(uri, [])
        rows.append(
            record(
                candidate_id=f"esco:{uuid}",
                source_id="esco-skills-v1.2.1",
                source_item_id=uri,
                source_title=title,
                source_description=first.get("description"),
                source_url=uri,
                source_category="; ".join(labels) if labels else None,
                candidate_type=candidate_type,
                consumer_relevance=relevance,
                provenance_note=(
                    "ESCO v1.2.1 English CSV, file skills_en.csv. "
                    f"skillType={skill_type or 'missing'}. reuseLevel={reuse or 'missing'}. "
                    "Occupational classification concept; consumer-catalog fit is not decided beyond the reuse-level tag. "
                    + (
                        f"Identical extra CSV rows for this URI collapsed: {len(copies) - 1}."
                        if len(copies) > 1 and copies[1] == first
                        else ""
                    )
                ),
            )
        )
    facts["esco"] = {
        "csv_rows": len(skills),
        "unique_uris": len(grouped),
        "identical_extra_rows_collapsed": identical_extra,
        "conflicting_duplicate_uris": conflicting,
        "records": sum(1 for row in rows if row["source_id"] == "esco-skills-v1.2.1"),
    }


def load_onet(rows: list[dict], facts: dict) -> None:
    dest = CACHE / "content_model_reference.csv"
    url = "https://www.onetcenter.org/dl_files/database/db_31_0_csv/content_model_reference.csv"
    how, size = cached_download(url, dest)
    facts["onet_fetch"] = {"url": url, "cache": how, "bytes": size}
    with dest.open(newline="", encoding="utf-8") as handle:
        elements = list(csv.DictReader(handle))
    by_id = {row["Element ID"]: norm_text(row["Element Name"]) for row in elements}

    def pillar_of(element_id: str) -> str | None:
        if element_id == "1.A" or element_id.startswith("1.A."):
            return "abilities"
        if element_id == "2.A" or element_id.startswith("2.A."):
            return "essential skills"
        if element_id == "2.B" or element_id.startswith("2.B."):
            return "transferable skills"
        if element_id == "2.C" or element_id.startswith("2.C."):
            return "knowledge"
        if element_id == "4.A" or element_id.startswith("4.A."):
            return "work activities"
        return None

    held = []
    for element in elements:
        element_id = element["Element ID"]
        pillar = pillar_of(element_id)
        if pillar is None:
            continue
        depth = element_id.count(".")
        if pillar == "work activities" and depth >= 6:
            held.append(element_id)
            continue
        title = norm_text(element["Element Name"])
        if not title:
            continue
        if depth <= 2:
            candidate_type = "węzeł taksonomii"
            relevance = "low"
        elif pillar == "abilities":
            candidate_type = "zdolność"
            relevance = "medium"
        elif pillar in {"essential skills", "transferable skills"}:
            candidate_type = "skill"
            relevance = "medium"
        elif pillar == "knowledge":
            candidate_type = "obszar wiedzy"
            relevance = "medium"
        elif depth == 4:
            candidate_type = "praktyczna czynność"
            relevance = "medium"
        else:
            candidate_type = "pojęcie zawodowe"
            relevance = "low"
        parent = None
        parts = element_id.split(".")
        for length in range(len(parts) - 1, 0, -1):
            parent_id = ".".join(parts[:length])
            if parent_id in by_id:
                parent = by_id[parent_id]
                break
        rows.append(
            record(
                candidate_id=f"onet:{element_id}",
                source_id="onet-content-model-31.0",
                source_item_id=element_id,
                source_title=title,
                source_description=element.get("Description"),
                source_url=url,
                source_category=f"{pillar}; {parent}" if parent else pillar,
                candidate_type=candidate_type,
                consumer_relevance=relevance,
                provenance_note=(
                    "O*NET 31.0 Content Model Reference. "
                    f"Element ID {element_id}, depth {depth}. "
                    "Detailed work activities (4.A IDs with six or more dots) were not imported. "
                    "This element is discovery material, not a decision that it belongs in the consumer catalogue."
                ),
            )
        )
    facts["onet"] = {
        "content_model_rows": len(elements),
        "detailed_work_activities_not_imported": len(held),
        "records": sum(1 for row in rows if row["source_id"] == "onet-content-model-31.0"),
    }


def load_scouts(rows: list[dict], facts: dict) -> None:
    live_status, live_body = http_get("https://www.scouts.org.uk/activity-badges", accept="text/html")
    live_has_badges = b"badge-card-link" in live_body
    snapshot = "20260308034627"
    url = f"https://web.archive.org/web/{snapshot}/https://www.scouts.org.uk/activity-badges"
    dest = CACHE / "scouts_20260308.html"
    how, size = cached_download(url, dest)
    html = dest.read_text(encoding="utf-8", errors="replace")
    pairs = re.findall(
        r'href="[^"]*?https://www\.scouts\.org\.uk/'
        r'((?:squirrels|beavers|cubs|scouts|explorers)/activity-badges/[a-z0-9\-]+)/?"'
        r'[^>]*class="badge-card-link"[^>]*>\s*([^<]+?)\s*<',
        html,
    )
    seen: set[str] = set()
    section_names = {
        "squirrels": "Squirrels",
        "beavers": "Beavers",
        "cubs": "Cubs",
        "scouts": "Scouts",
        "explorers": "Explorers",
    }
    for path, title in pairs:
        if path in seen:
            continue
        seen.add(path)
        section = path.split("/")[0]
        clean_title = unescape(title)
        folded = clean_title.casefold()
        if any(word in folded for word in ("uniform", "birthday", "anniversary")):
            relevance = "low"
        else:
            relevance = "high"
        rows.append(
            record(
                candidate_id=f"scouts-uk:{path.replace('/', ':')}",
                source_id="scouts-uk-activity-badges",
                source_item_id=path,
                source_title=clean_title,
                source_description=None,
                source_url=f"https://www.scouts.org.uk/{path}/",
                source_category=section_names.get(section, section),
                candidate_type="aktywność",
                consumer_relevance=relevance,
                provenance_note=(
                    f"Title and URL from Wayback snapshot {snapshot} of the activity-badges index "
                    f"(fetch {how}, {size} bytes). Live request on {RETRIEVED_ON} returned HTTP {live_status} "
                    f"and {'included' if live_has_badges else 'did not include'} badge cards. "
                    "Requirement text was not collected. "
                    f"Age section: {section_names.get(section, section)}. "
                    "The same badge title may exist in another age section; those rows were kept and not clustered."
                ),
            )
        )
    page_links = sorted(set(re.findall(r"activity-badges/\?p=(\d+)", html)))
    facts["scouts"] = {
        "live_http_status": live_status,
        "live_included_badge_cards": live_has_badges,
        "snapshot": snapshot,
        "badge_rows": len(seen),
        "pagination_labels_seen": page_links,
    }


def load_openlearn(rows: list[dict], facts: dict) -> None:
    live_status, _ = http_get(
        "https://www.open.edu/openlearn/free-courses/full-catalogue",
        accept="text/html",
    )
    snapshot = "20230314213107"
    url = f"https://web.archive.org/web/{snapshot}/https://www.open.edu/openlearn/free-courses/full-catalogue"
    dest = CACHE / "openlearn_20230314.html"
    how, size = cached_download(url, dest)
    html = dest.read_text(encoding="utf-8", errors="replace")
    headings = list(
        re.finditer(r'id="section-heading-\d+"[^>]*>(.*?)</h2>', html, flags=re.I)
    )
    course_total = 0
    for index, match in enumerate(headings):
        title = norm_text(unescape(re.sub(r"<[^>]+>", "", match.group(1))))
        folder = OPENLEARN_HEADINGS.get(title or "")
        end = headings[index + 1].start() if index + 1 < len(headings) else len(html)
        slugs: set[str] = set()
        if folder:
            slugs = set(re.findall(rf"openlearn/{re.escape(folder)}/([a-z0-9\-]+)", html[match.start() : end]))
            slugs = {slug for slug in slugs if not slug.startswith("content-section") and len(slug) > 1}
        course_total += len(slugs)
        if not title or not folder:
            continue
        slug = folder
        rows.append(
            record(
                candidate_id=f"openlearn-subject:{slug}",
                source_id="openlearn-full-catalogue",
                source_item_id=slug,
                source_title=title,
                source_description=None,
                source_url="https://www.open.edu/openlearn/free-courses/full-catalogue",
                source_category="OpenLearn subject heading",
                candidate_type="obszar wiedzy",
                consumer_relevance="medium",
                provenance_note=(
                    f"Subject heading from Wayback snapshot {snapshot} of the full catalogue "
                    f"(fetch {how}, {size} bytes). {len(slugs)} course paths were listed under this heading "
                    "and were not imported as separate candidates. "
                    f"Live catalogue request on {RETRIEVED_ON} returned HTTP {live_status}."
                ),
            )
        )
    facts["openlearn"] = {
        "live_http_status": live_status,
        "snapshot": snapshot,
        "subject_rows": sum(1 for row in rows if row["source_id"] == "openlearn-full-catalogue"),
        "course_paths_not_imported": course_total,
    }


def load_wikidata(rows: list[dict], facts: dict) -> None:
    query = """
    SELECT ?item ?itemLabel ?itemDescription WHERE {
      { ?item wdt:P31 wd:Q47728. }
      UNION
      { ?item wdt:P279 wd:Q47728. }
      MINUS { ?item (wdt:P279*) wd:Q2312410. }
      MINUS { ?item (wdt:P279*) wd:Q56055944. }
      MINUS { ?item (wdt:P31) wd:Q31629. }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }
    """
    encoded = urllib.parse.urlencode({"query": query}).encode()
    request = urllib.request.Request(
        "https://query.wikidata.org/sparql",
        data=encoded,
        headers={"User-Agent": UA, "Accept": "application/sparql-results+json"},
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        payload = json.load(response)
    bindings = payload["results"]["bindings"]
    seen: set[str] = set()
    skipped_unlabeled = 0
    for binding in bindings:
        item = binding["item"]["value"]
        qid = item.rstrip("/").rsplit("/", 1)[-1]
        label = norm_text(binding.get("itemLabel", {}).get("value"))
        if not label or re.fullmatch(r"Q\d+", label):
            skipped_unlabeled += 1
            continue
        if qid in seen:
            continue
        seen.add(qid)
        description = norm_text(binding.get("itemDescription", {}).get("value"))
        if description is None or description.casefold() in {"hobby", "hobbies", "pastime"}:
            relevance = "unclear"
        else:
            relevance = "high"
        rows.append(
            record(
                candidate_id=f"wikidata:{qid}",
                source_id="wikidata-hobbies",
                source_item_id=qid,
                source_title=label,
                source_description=description,
                source_url=f"https://www.wikidata.org/wiki/{qid}",
                source_category="hobby or subclass of hobby, excluding sports disciplines and types of art",
                candidate_type="hobby",
                consumer_relevance=relevance,
                provenance_note=(
                    "SPARQL result of the query published on Wikidata:List_of_activities_done_as_hobby. "
                    "The page says the list is collaborative, incomplete, and may contain items that do not belong. "
                    "Sports disciplines (Q2312410) and types of art (Q56055944) are excluded by that query, "
                    "so their absence here is a property of the source query."
                ),
            )
        )
    facts["wikidata"] = {
        "bindings": len(bindings),
        "records": len(seen),
        "skipped_unlabeled": skipped_unlabeled,
    }


def load_heritage(rows: list[dict], facts: dict) -> None:
    url = "https://heritagecrafts.org.uk/skills/crafts/"
    dest = CACHE / "heritage_crafts.html"
    how, size = cached_download(url, dest, refresh=True)
    html = dest.read_text(encoding="utf-8", errors="replace")
    pairs = re.findall(
        r'href="https://heritagecrafts.org.uk/craft/([a-z0-9\-]+)/?"[^>]*>(.*?)</a>',
        html,
        flags=re.I,
    )
    seen: set[str] = set()
    for slug, inner in pairs:
        title = norm_text(unescape(re.sub(r"<[^>]+>", " ", inner)))
        if not title or slug in seen:
            continue
        seen.add(slug)
        rows.append(
            record(
                candidate_id=f"heritage-crafts:{slug}",
                source_id="heritage-crafts-inventory",
                source_item_id=slug,
                source_title=title,
                source_description=None,
                source_url=f"https://heritagecrafts.org.uk/craft/{slug}/",
                source_category="Heritage Crafts craft inventory",
                candidate_type="praktyczna czynność",
                consumer_relevance="high",
                provenance_note=(
                    f"Title taken from the craft inventory page (fetch {how}, {size} bytes). "
                    "The craft article was not copied. "
                    "Entries that differ by region, material, or instrument were kept as separate source rows and not clustered."
                ),
            )
        )
    facts["heritage"] = {"records": len(seen), "fetch": how, "bytes": size}


def probe_unused(facts: dict) -> None:
    map_status, map_body = http_get("https://www.ordnancesurvey.co.uk/mapzone/map-skills", accept="text/html")
    map_text = map_body.decode("utf-8", errors="replace")
    facts["ordnance_survey_mapzone"] = {
        "http_status": map_status,
        "bytes": len(map_body),
        "javascript_required_message": "Javascript" in map_text or "JavaScript" in map_text,
    }
    astro_status, astro_body = http_get("https://www.astroleague.org/observing-programs/", accept="text/html")
    astro_html = astro_body.decode("utf-8", errors="replace")
    program_links = set(
        re.findall(r'https://www\.astroleague\.org/[^"\']*(?:observing-program|/programs/)', astro_html)
    )
    facts["astronomical_league"] = {
        "http_status": astro_status,
        "bytes": len(astro_body),
        "program_links_seen": len(program_links),
        "imported": 0,
    }


def source_documents(facts: dict, counts: Counter) -> list[dict]:
    esco = facts["esco"]
    onet = facts["onet"]
    scouts = facts["scouts"]
    openlearn = facts["openlearn"]
    wikidata = facts["wikidata"]
    heritage = facts["heritage"]
    documents = [
        {
            "source_id": "esco-skills-v1.2.1",
            "title": "ESCO classification, skills pillar, English CSV",
            "publisher": "European Commission, Directorate-General for Employment, Social Affairs and Inclusion",
            "url": "https://esco.ec.europa.eu/en/use-esco/download",
            "download_url": facts["esco_fetch"]["url"],
            "source_type": "official classification export",
            "domains": ["occupational skills", "knowledge", "competences", "transversal skills"],
            "retrieved_on": RETRIEVED_ON,
            "language": "en",
            "access_status": "downloaded",
            "completeness": (
                f"skills_en.csv has {esco['csv_rows']} rows and {esco['unique_uris']} concept URIs. "
                f"{esco['identical_extra_rows_collapsed']} identical extra rows were stored once. "
                f"Conflicting duplicate URIs: {esco['conflicting_duplicate_uris']}."
            ),
            "license": (
                "No separate licence label was printed on the download page retrieved for this run. "
                "ESCO v1.2.1 is published by the European Commission. Reuse of Commission documents "
                "is governed by Commission Decision 2011/833/EU where no narrower statement is given. "
                "This is a research note, not a legal opinion."
            ),
            "attribution_required": "Attribute the European Commission / ESCO. Do not present the extract as an official ESCO product.",
            "notes": (
                "The ESCO search API returned results only for offset 0 and 100 (200 skills) on this date, "
                "so the official v1.2.1 English classification CSV was used. "
                "Skill groups were used only as broader labels, not as extra candidates. "
                "consumer_relevance is a mechanical tag from reuseLevel: transversal and cross-sector are medium; "
                "sector-specific and occupation-specific are low. No adaptation hints were written."
            ),
            "records_written": counts["esco-skills-v1.2.1"],
        },
        {
            "source_id": "onet-content-model-31.0",
            "title": "O*NET 31.0 Database, Content Model Reference",
            "publisher": "U.S. Department of Labor, Employment and Training Administration; National Center for O*NET Development",
            "url": "https://www.onetcenter.org/database.html",
            "download_url": facts["onet_fetch"]["url"],
            "source_type": "official occupational database extract",
            "domains": ["abilities", "skills", "knowledge", "work activities"],
            "retrieved_on": RETRIEVED_ON,
            "language": "en",
            "access_status": "downloaded",
            "completeness": (
                f"Content Model Reference has {onet['content_model_rows']} elements. "
                "Imported abilities (1.A), essential skills (2.A), transferable skills (2.B), knowledge (2.C), "
                f"and work activities (4.A) except detailed work activities. "
                f"Not imported: {onet['detailed_work_activities_not_imported']} work-activity elements whose IDs have six or more dots."
            ),
            "license": "Creative Commons Attribution 4.0 International (CC BY 4.0), except as stated on the O*NET database licence page.",
            "attribution_required": (
                "Credit the O*NET 31.0 Database and the U.S. Department of Labor, Employment and Training Administration "
                "as the source, link to CC BY 4.0, and indicate modifications. O*NET is a trademark of USDOL/ETA. "
                "USDOL/ETA has not approved, endorsed, or tested this extract."
            ),
            "notes": (
                "The database licence applies to downloadable database files. It does not by itself license the "
                "O*NET Career Exploration Tools or the rest of the website. Occupation-by-skill rating tables and "
                "task statements were not imported. Headings with ID depth of two or less are tagged as taxonomy nodes."
            ),
            "records_written": counts["onet-content-model-31.0"],
        },
        {
            "source_id": "scouts-uk-activity-badges",
            "title": "Scouts activity badges",
            "publisher": "The Scout Association",
            "url": "https://www.scouts.org.uk/activity-badges",
            "download_url": f"https://web.archive.org/web/{facts['scouts']['snapshot']}/https://www.scouts.org.uk/activity-badges",
            "source_type": "youth organisation activity catalogue",
            "domains": ["outdoor activity", "creative activity", "practical self-reliance", "nature", "technical activity"],
            "retrieved_on": RETRIEVED_ON,
            "language": "en",
            "access_status": "live site blocked; archived index used",
            "completeness": (
                f"Live HTTP status {scouts['live_http_status']}; badge cards in that response: {scouts['live_included_badge_cards']}. "
                f"{scouts['badge_rows']} badge titles were read from Wayback snapshot {scouts['snapshot']}. "
                f"Pagination labels seen in that snapshot: {', '.join(scouts['pagination_labels_seen']) or 'none'}. "
                "Requirement pages were not retrieved, so descriptions are empty."
            ),
            "license": "Copyright The Scout Association. No open licence was found for badge syllabi. Titles and URLs only were stored.",
            "attribution_required": "Attribute The Scout Association. Do not copy requirement text from this research file; it was not collected.",
            "notes": (
                "Uniform, birthday, and anniversary badges are tagged consumer_relevance low. "
                "Other badges are tagged high as practical activities. Age-section copies of the same title were kept."
            ),
            "records_written": counts["scouts-uk-activity-badges"],
        },
        {
            "source_id": "openlearn-full-catalogue",
            "title": "OpenLearn full course catalogue",
            "publisher": "The Open University",
            "url": "https://www.open.edu/openlearn/free-courses/full-catalogue",
            "download_url": f"https://web.archive.org/web/{facts['openlearn']['snapshot']}/https://www.open.edu/openlearn/free-courses/full-catalogue",
            "source_type": "open course catalogue",
            "domains": ["science", "languages", "nature", "arts", "technology", "finance", "health", "education"],
            "retrieved_on": RETRIEVED_ON,
            "language": "en",
            "access_status": "live catalogue blocked; archived subject headings used",
            "completeness": (
                f"Live HTTP status {openlearn['live_http_status']}. "
                f"Subject headings written: {openlearn['subject_rows']}. "
                f"Course paths seen under those headings and not imported: {openlearn['course_paths_not_imported']}. "
                "The usable snapshot is from 2023-03-14, so the subject list may be stale."
            ),
            "license": "Copyright The Open University. Course texts were not copied. Only the nine catalogue subject headings were stored.",
            "attribution_required": "Attribute The Open University / OpenLearn if a heading is reused.",
            "notes": "Individual course titles were deliberately not treated as skills.",
            "records_written": counts["openlearn-full-catalogue"],
        },
        {
            "source_id": "wikidata-hobbies",
            "title": "Wikidata list of activities done as a hobby",
            "publisher": "Wikimedia contributors",
            "url": "https://www.wikidata.org/wiki/Wikidata:List_of_activities_done_as_hobby",
            "download_url": "https://query.wikidata.org/sparql",
            "source_type": "collaborative structured-data list",
            "domains": ["hobbies", "niche leisure activities"],
            "retrieved_on": RETRIEVED_ON,
            "language": "en",
            "access_status": "sparql query succeeded",
            "completeness": (
                f"Query bindings: {wikidata['bindings']}. Records written: {wikidata['records']}. "
                f"Unlabeled bindings skipped: {wikidata['skipped_unlabeled']}. "
                "The query is the one embedded on the wiki page and excludes sports disciplines and types of art."
            ),
            "license": "Wikidata structured data is CC0. The wiki page text is CC BY-SA; this extract uses the SPARQL results, not the page prose.",
            "attribution_required": "CC0 does not require attribution. Citing Wikidata is still appropriate.",
            "notes": (
                "A description that is only the word hobby is tagged consumer_relevance unclear. "
                "A more specific description is tagged high, still subject to the page's own reliability warning."
            ),
            "records_written": counts["wikidata-hobbies"],
        },
        {
            "source_id": "heritage-crafts-inventory",
            "title": "Heritage Crafts craft inventory",
            "publisher": "Heritage Crafts",
            "url": "https://heritagecrafts.org.uk/skills/crafts/",
            "download_url": "https://heritagecrafts.org.uk/skills/crafts/",
            "source_type": "specialist craft inventory",
            "domains": ["craft", "making", "heritage trades", "instruments", "repair"],
            "retrieved_on": RETRIEVED_ON,
            "language": "en",
            "access_status": "downloaded",
            "completeness": f"{heritage['records']} inventory entries with anchor text were stored. Craft articles were not copied.",
            "license": "No open licence was stated on the inventory page. Titles and canonical URLs only were stored.",
            "attribution_required": "Attribute Heritage Crafts. Do not treat this extract as permission to republish craft articles.",
            "notes": (
                "Added after the initial sources because craft practice was mostly present only as occupational ESCO concepts. "
                "Regional and material variants remain separate rows on purpose."
            ),
            "records_written": counts["heritage-crafts-inventory"],
        },
        {
            "source_id": "ordnance-survey-mapzone",
            "title": "Ordnance Survey Mapzone map skills",
            "publisher": "Ordnance Survey",
            "url": "https://www.ordnancesurvey.co.uk/mapzone/map-skills",
            "download_url": "https://www.ordnancesurvey.co.uk/mapzone/map-skills",
            "source_type": "educational map-skills page",
            "domains": ["navigation", "map reading", "observation"],
            "retrieved_on": RETRIEVED_ON,
            "language": "en",
            "access_status": "retrieved but not imported",
            "completeness": (
                f"HTTP {facts['ordnance_survey_mapzone']['http_status']}, "
                f"{facts['ordnance_survey_mapzone']['bytes']} bytes. "
                "The page says JavaScript is required and does not list map skills in the HTML."
            ),
            "license": "Copyright Ordnance Survey. No skill names were extracted.",
            "attribution_required": "Not applicable to candidate rows, because none were written.",
            "notes": "Checked as a possible navigation source. No candidates were created.",
            "records_written": 0,
        },
        {
            "source_id": "astronomical-league-observing-programs",
            "title": "Astronomical League observing programs (A to C index)",
            "publisher": "Astronomical League",
            "url": "https://www.astroleague.org/observing-programs/",
            "download_url": "https://www.astroleague.org/observing-programs/",
            "source_type": "amateur astronomy award index",
            "domains": ["amateur astronomy", "observation", "citizen science"],
            "retrieved_on": RETRIEVED_ON,
            "language": "en",
            "access_status": "retrieved but not imported",
            "completeness": (
                f"HTTP {facts['astronomical_league']['http_status']}, "
                f"{facts['astronomical_league']['bytes']} bytes. "
                f"Program links seen on the A-to-C page: {facts['astronomical_league']['program_links_seen']}. "
                "Programs are mostly object-class observing awards and were not imported."
            ),
            "license": "Copyright Astronomical League. No program list was copied into the candidate file.",
            "attribution_required": "Not applicable to candidate rows, because none were written.",
            "notes": "Importing one program per object class would split observing into successive catalogue exercises.",
            "records_written": 0,
        },
    ]
    return documents


def normalize(raw_rows: list[dict]) -> list[dict]:
    normalized = []
    for raw in raw_rows:
        title = raw["source_title"] or ""
        item = {
            "candidate_id": raw["candidate_id"] + ":normalized",
            "raw_candidate_id": raw["candidate_id"],
            "source_id": raw["source_id"],
            "source_item_id": raw["source_item_id"],
            "source_title": title,
            "normalized_title": title,
            "comparison_key": comparison_key(title),
            "source_description": raw["source_description"],
            "source_url": raw["source_url"],
            "source_language": raw["source_language"],
            "source_category": raw["source_category"],
            "candidate_type": raw["candidate_type"],
            "consumer_relevance": raw["consumer_relevance"],
            "adaptation_hint": raw["adaptation_hint"],
            "provenance_note": "Technical normalization only: NFC, NBSP folded to space, whitespace collapsed. No deduplication decision.",
        }
        normalized.append(item)
    return normalized


def write_jsonl(path: Path, rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n")


def area_counts(rows: list[dict]) -> list[tuple[str, int]]:
    counts = []
    compiled = [
        (label, [re.compile(r"(?<![a-z0-9])" + re.escape(pattern)) for pattern in patterns])
        for label, patterns in AREA_PATTERNS
    ]
    for label, patterns in compiled:
        found = 0
        for row in rows:
            key = comparison_key(row["source_title"] or "")
            if any(pattern.search(key) for pattern in patterns):
                found += 1
        counts.append((label, found))
    return counts


def write_coverage(path: Path, rows: list[dict], sources: list[dict], facts: dict) -> None:
    by_source = Counter(row["source_id"] for row in rows)
    by_type = Counter(row["candidate_type"] for row in rows)
    by_language = Counter(row["source_language"] for row in rows)
    by_relevance = Counter(row["consumer_relevance"] for row in rows)
    with_id = sum(1 for row in rows if row["source_item_id"])
    without_id = len(rows) - with_id
    esco_rows = [row for row in rows if row["source_id"] == "esco-skills-v1.2.1"]
    reuse = Counter()
    skill_type = Counter()
    broader = Counter()
    for row in esco_rows:
        note = row["provenance_note"] or ""
        reuse_match = re.search(r"reuseLevel=([^\s.]+)", note)
        type_match = re.search(r"skillType=([^\s.]+)", note)
        reuse[reuse_match.group(1) if reuse_match else "missing"] += 1
        skill_type[type_match.group(1) if type_match else "missing"] += 1
        if row["source_category"]:
            for label in row["source_category"].split("; "):
                broader[label] += 1
    areas = area_counts(rows)
    thin = [item for item in areas if item[1] < 30]
    lines = [
        "# Raport pokrycia kandydatur",
        "",
        f"Data generacji: {RETRIEVED_ON}. Wszystkie liczby poniżej zostały policzone z plików wygenerowanych w tym przebiegu albo z pobranych plików źródłowych, które skrypt odrzucił przed zapisem.",
        "",
        "## Liczba kandydatur",
        "",
        f"- Rekordy w `candidates-raw.jsonl`: **{len(rows)}**.",
        f"- Rekordy w `candidates-normalized.jsonl`: **{len(rows)}** (jeden znormalizowany rekord na każdą kandydaturę surową).",
        f"- Cel organizacyjny 3500–4000 został przekroczony, bo sam filar umiejętności ESCO ma {facts['esco']['unique_uris']} unikalnych pojęć. Nadmiar nie jest katalogiem 1001 Skills.",
        "",
        "## Według źródła",
        "",
    ]
    for source in sources:
        lines.append(f"- `{source['source_id']}`: {source['records_written']}")
    lines.extend(["", "## Według typu", ""])
    for key, value in sorted(by_type.items()):
        lines.append(f"- {key}: {value}")
    lines.extend(["", "## Według języka", ""])
    for key, value in sorted(by_language.items()):
        lines.append(f"- {key}: {value}")
    lines.extend(["", "## Według wstępnej przydatności konsumenckiej", ""])
    lines.append("To mechaniczny znacznik opisany w `README.md`, nie ocena redakcyjna.")
    lines.append("")
    for key in ("high", "medium", "low", "unclear"):
        lines.append(f"- {key}: {by_relevance[key]}")
    lines.extend(
        [
            "",
            "## Identyfikatory",
            "",
            f"- Z `source_item_id`: {with_id}.",
            f"- Bez `source_item_id`: {without_id}.",
            "",
            "## ESCO: typ i poziom ponownego użycia",
            "",
            "Każdy rekord ESCO liczy się tu raz.",
            "",
        ]
    )
    for key, value in sorted(skill_type.items()):
        lines.append(f"- skillType {key}: {value}")
    lines.append("")
    for key, value in sorted(reuse.items()):
        lines.append(f"- reuseLevel {key}: {value}")
    lines.extend(
        [
            "",
            "## Najczęstsze etykiety nadrzędne ESCO",
            "",
            "Rekord z kilkoma etykietami nadrzędnymi wchodzi do każdej z nich. To nie jest podział rozłączny.",
            "",
        ]
    )
    for label, value in broader.most_common(15):
        lines.append(f"- {label}: {value}")
    lines.extend(
        [
            "",
            "## Skan słów w tytułach",
            "",
            "Jedna kandydatura może trafić do kilku obszarów. Wzorzec musi zaczynać się na granicy znaku innego niż litera lub cyfra. To nie jest taksonomia.",
            "",
        ]
    )
    for label, value in areas:
        lines.append(f"- {label}: {value}")
    lines.extend(["", "## Obszary nadreprezentowane", ""])
    lines.append(
        f"- Pojęcia zawodowe ESCO o reuseLevel sector-specific albo occupation-specific: "
        f"{reuse['sector-specific'] + reuse['occupation-specific']} z {len(esco_rows)} rekordów ESCO."
    )
    lines.append(
        "- Szczegółowe czynności zawodowe O*NET na głębokości identyfikatora 5 zostały zapisane jako pojęcia zawodowe o niskiej przydatności, "
        "ale nadal pochodzą z taksonomii pracy, nie z praktyki hobbystycznej."
    )
    if broader:
        top_label, top_value = broader.most_common(1)[0]
        lines.append(f"- Najliczniejsza etykieta nadrzędna ESCO to „{top_label}” ({top_value} powiązań).")
    lines.extend(["", "## Obszary, które wymagają dalszego pozyskiwania", ""])
    lines.append("Próg raportowy: mniej niż 30 trafień skanu tytułów. To nie jest ocena, że obszar jest pusty merytorycznie.")
    lines.append("")
    if thin:
        for label, value in thin:
            lines.append(f"- {label}: {value}")
    else:
        lines.append("- Żaden obszar skanu nie spadł poniżej 30 trafień.")
    lines.extend(
        [
            "",
            "Niezależnie od skanu, te źródła specjalistyczne nie dały listy kandydatur:",
            "",
            f"- Ordnance Survey Mapzone: HTTP {facts['ordnance_survey_mapzone']['http_status']}, strona wymaga JavaScriptu, brak listy umiejętności.",
            f"- Astronomical League, indeks programów obserwacyjnych A–C: {facts['astronomical_league']['program_links_seen']} odsyłaczy do programów. Nie zaimportowano ich, bo dzielą obserwację według klas obiektów.",
            "- Zapytanie Wikidanych celowo pomija dyscypliny sportu i typy sztuki. Taniec, sporty i sztuki wizualne nie są więc pokryte przez to źródło.",
            "- Wymagania odznak Skautów nie zostały pobrane. "
            f"Żywe żądanie zwróciło HTTP {facts['scouts']['live_http_status']}; "
            f"karty odznak w tej odpowiedzi: {facts['scouts']['live_included_badge_cards']}. "
            "Archiwalny indeks ma same nazwy.",
            "",
            "## Problemy dostępu",
            "",
            f"- ESCO API `/search` z `full=true` oddało rekordy tylko dla offset 0 i 100. Użyto CSV v1.2.1 ({facts['esco_fetch']['zip_bytes']} bajtów, {facts['esco_fetch']['cache']}).",
            f"- Scouts, żywa strona: HTTP {facts['scouts']['live_http_status']}. Użyto snapshotu {facts['scouts']['snapshot']}.",
            f"- OpenLearn, żywy katalog: HTTP {facts['openlearn']['live_http_status']}. Użyto snapshotu {facts['openlearn']['snapshot']}, starszego niż data badania.",
            f"- Szczegółowe czynności O*NET niezaimportowane: {facts['onet']['detailed_work_activities_not_imported']}.",
            f"- Ścieżki kursów OpenLearn niezaimportowane: {facts['openlearn']['course_paths_not_imported']}.",
            "",
            "## Ograniczenia jakości",
            "",
            "- Większość rekordów to pojęcia klasyfikacji zawodowej. Nie są one osobnymi skillami katalogu konsumenckiego.",
            "- `consumer_relevance` nie była recenzowana ręcznie.",
            "- `adaptation_hint` jest wszędzie puste. Skrypt nie dopisuje pomysłów adaptacji.",
            "- Opisy Skautów i Heritage Crafts są puste, bo nie kopiowano artykułów ani regulaminów.",
            "- Warianty odznak według sekcji wiekowej oraz warianty rzemiosł według regionu albo materiału nadal są osobnymi wierszami.",
            "- Deduplikacja nie została wykonana. `duplicate-clusters.json` ma pustą listę grup.",
            "",
            "## Dalsza praca do 1001 skillów",
            "",
            "Samych rekordów jest dość, żeby po selekcji redakcyjnej wybrać 1001 pozycji, ale obecna pula nie jest jeszcze tą listą.",
            "Następny etap to grupowanie duplikatów bez usuwania pochodzenia, odrzucenie pojęć czysto zawodowych i uzupełnienie obszarów poniżej progu skanu.",
            "Nie należy dobijać liczby kolejnym zrzutem kompetencji zawodowych. Brakuje praktycznych źródeł dla nawigacji, astronomii amatorskiej bez podziału na klasy obiektów, nauki obywatelskiej, tańca i sportu oraz komunikacji interpersonalnej opisanej jako ćwiczenie, a nie jako kompetencja stanowiska.",
            "Trzy poziomy, wyzwania i interfejs katalogu nadal nie istnieją.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def write_readme(path: Path, raw_count: int) -> None:
    text = f"""# Baza kandydatur katalogu 1001 Skills

Ten katalog zbiera materiał wejściowy do przyszłego katalogu **1001 Skills** w Time4Skill. Aplikacja ma pomagać odkrywać umiejętności i ćwiczyć je w praktyce. Docelowy katalog ma mieć co najmniej 1001 jakościowo różnych skillów. Każdy zatwierdzony skill będzie miał najwyżej trzy poziomy rozwoju, odpowiadające trzem gwiazdkom.

Ten etap nie wybiera listy 1001, nie opisuje poziomów, nie tworzy wyzwań i nie zmienia aplikacji.

## Skąd są dane

Rekordy pochodzą z publicznych eksportów, zapytań i stron wymienionych w `sources.json`. Skrypt `build_catalog_research.py` pobiera je ponownie, normalizuje technicznie i zapisuje pliki w tym katalogu. Duże pliki źródłowe zostają w pamięci podręcznej `/tmp/t4s-catalog` i nie wchodzą do repozytorium.

Aktualna liczba surowych kandydatur: **{raw_count}**. Szczegóły, odrzucenia i luki są w `coverage-report.md`.

## Czym jest surowa kandydatura

Surowa kandydatura to jedna pozycja tak, jak wystąpiła w źródle: z oryginalną nazwą, identyfikatorem i adresem, jeśli źródło je podało. Nie jest obietnicą, że trafi do katalogu. Znacznik `consumer_relevance` jest tylko mechaniczną etykietą z reguły opisanej przy źródle.

## Kandydatura, skill i wyzwanie

- **Kandydatura** to wiersz w `candidates-raw.jsonl`. Dwie kandydatury mogą być tą samą umiejętnością albo wcale nie być umiejętnością.
- **Osobny skill** będzie decyzją późniejszej redakcji. Ten etap jej nie podejmuje i niczego nie usuwa.
- **Pojedyncze wyzwanie** to konkretne ćwiczenie albo kryterium ukończenia. Takich rekordów tu nie ma.

## Stan, ograniczenia, następne kroki

Pula jest liczna, ponieważ filar umiejętności ESCO został zapisany w całości. Większość tych pojęć jest zawodowa. Osobne pliki nie zawierają poziomów, punktacji ani widoku katalogu. `duplicate-clusters.json` jest pustym schematem: deduplikacja nie była uruchamiana.

Następne kroki to grupowanie duplikatów z zachowaniem pochodzenia, selekcja pod katalog konsumencki i dozbieranie dziedzin, które `coverage-report.md` wskazuje jako słabo trafione skanem tytułów.

## Ponowne uruchomienie

Z katalogu repozytorium:

```bash
python3 scripts/catalog/build_catalog_research.py
```

Skrypt wymaga Pythona 3 i sieci przy braku plików w `/tmp/t4s-catalog`. Po zakończeniu sprawdza składnię JSON i JSONL, unikalność `candidate_id` oraz to, że każdy `source_id` występuje w `sources.json`. Usunięcie pamięci podręcznej wymusza ponowne pobranie. Nie edytuj tysięcy wierszy ręcznie; zmień regułę w skrypcie i uruchom go ponownie.
"""
    path.write_text(text, encoding="utf-8")


def validate(sources: list[dict], raw_rows: list[dict], normalized_rows: list[dict]) -> None:
    source_ids = [source["source_id"] for source in sources]
    if len(source_ids) != len(set(source_ids)):
        raise SystemExit("duplicate source_id")
    raw_ids = [row["candidate_id"] for row in raw_rows]
    if len(raw_ids) != len(set(raw_ids)):
        raise SystemExit("duplicate raw candidate_id")
    normalized_ids = [row["candidate_id"] for row in normalized_rows]
    if len(normalized_ids) != len(set(normalized_ids)):
        raise SystemExit("duplicate normalized candidate_id")
    known = set(source_ids)
    raw_by_id = {row["candidate_id"]: row for row in raw_rows}
    for row in raw_rows:
        if row["source_id"] not in known:
            raise SystemExit(f"unknown source_id {row['source_id']}")
        if set(row) != set(REQUIRED_KEYS):
            raise SystemExit(f"raw keys mismatch for {row['candidate_id']}")
        if row["candidate_type"] not in CANDIDATE_TYPES:
            raise SystemExit(f"bad type {row['candidate_type']}")
        if row["consumer_relevance"] not in RELEVANCE:
            raise SystemExit(f"bad relevance {row['consumer_relevance']}")
        if not row["source_title"]:
            raise SystemExit(f"empty title {row['candidate_id']}")
    for row in normalized_rows:
        if row["source_id"] not in known:
            raise SystemExit(f"normalized unknown source {row['source_id']}")
        raw = raw_by_id.get(row["raw_candidate_id"])
        if raw is None:
            raise SystemExit(f"normalized row without raw record {row['candidate_id']}")
        if row["comparison_key"] != comparison_key(raw["source_title"]):
            raise SystemExit(f"comparison key drift {row['candidate_id']}")
    for path in (OUT_DIR / "sources.json", OUT_DIR / "duplicate-clusters.json"):
        json.loads(path.read_text(encoding="utf-8"))
    for path in (OUT_DIR / "candidates-raw.jsonl", OUT_DIR / "candidates-normalized.jsonl"):
        with path.open(encoding="utf-8") as handle:
            for line_number, line in enumerate(handle, start=1):
                if not line.endswith("\n") or not line.strip():
                    raise SystemExit(f"bad line {line_number} in {path.name}")
                json.loads(line)


def assert_safe_to_rebuild() -> None:
    """Stage 002 appends records this script does not know how to regenerate."""
    path = OUT_DIR / "candidates-raw.jsonl"
    if not path.exists():
        return
    known_prefixes = (
        "esco:",
        "onet:",
        "scouts-uk:",
        "openlearn-subject:",
        "wikidata:",
        "heritage-crafts:",
    )
    foreign = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        candidate_id = json.loads(line)["candidate_id"]
        if not candidate_id.startswith(known_prefixes):
            foreign.append(candidate_id)
            if len(foreign) >= 5:
                break
    if foreign:
        raise SystemExit(
            "Refusing to rebuild. candidates-raw.jsonl contains records added after "
            "the first extract, for example: "
            + ", ".join(foreign)
            + ". This script would overwrite them. It does not delete or renumber candidates."
        )
    clusters_path = OUT_DIR / "duplicate-clusters.json"
    if clusters_path.exists():
        proposed = json.loads(clusters_path.read_text(encoding="utf-8"))
        if proposed.get("status") not in {None, "not_run"} or proposed.get("cluster_count", 0):
            raise SystemExit(
                "Refusing to rebuild. duplicate-clusters.json already contains grouping "
                "proposals. This script would replace them with an empty list."
            )


def main() -> None:
    check_only(
        [
            OUT_DIR / "candidates-raw.jsonl",
            OUT_DIR / "candidates-normalized.jsonl",
            OUT_DIR / "sources.json",
            OUT_DIR / "duplicate-clusters.json",
            DOC_DIR / "coverage-report.md",
            DOC_DIR / "README.md",
        ]
    )
    assert_safe_to_rebuild()
    facts: dict = {}
    rows: list[dict] = []
    load_esco(rows, facts)
    load_onet(rows, facts)
    load_scouts(rows, facts)
    load_openlearn(rows, facts)
    load_wikidata(rows, facts)
    load_heritage(rows, facts)
    probe_unused(facts)
    rows.sort(key=lambda row: row["candidate_id"])
    counts = Counter(row["source_id"] for row in rows)
    sources = source_documents(facts, counts)
    normalized = normalize(rows)
    write_jsonl(OUT_DIR / "candidates-raw.jsonl", rows)
    write_jsonl(OUT_DIR / "candidates-normalized.jsonl", normalized)
    (OUT_DIR / "sources.json").write_text(
        json.dumps({"retrieved_on": RETRIEVED_ON, "sources": sources}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (OUT_DIR / "duplicate-clusters.json").write_text(
        json.dumps(
            {
                "schema_version": 1,
                "status": "not_run",
                "deduplication_performed": False,
                "generated_on": None,
                "cluster_count": 0,
                "clusters": [],
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    write_coverage(DOC_DIR / "coverage-report.md", rows, sources, facts)
    write_readme(DOC_DIR / "README.md", len(rows))
    validate(sources, rows, normalized)
    print(f"OK raw={len(rows)} sources={len(sources)}")


if __name__ == "__main__":
    main()
