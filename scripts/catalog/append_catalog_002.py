#!/usr/bin/env python3
"""Append T4S-CATALOG-002 candidates. Does not rewrite existing JSONL lines."""

from __future__ import annotations

import hashlib
import html
import json
import re
import unicodedata
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from layout import DOCS, RESEARCH, check_only

OUT = RESEARCH
DOC_DIR = DOCS
CACHE = Path("/tmp/t4s-catalog/c002")
TODAY = "2026-10-18"
RAW_KEYS = [
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
NORM_NOTE = (
    "Technical normalization only: NFC, NBSP folded to space, whitespace collapsed. "
    "No deduplication decision."
)


def norm_text(value: str | None) -> str:
    if not value:
        return ""
    text = unicodedata.normalize("NFC", value.replace("\u00a0", " "))
    return re.sub(r"\s+", " ", text).strip()


def comparison_key(value: str | None) -> str:
    return unicodedata.normalize("NFKC", norm_text(value)).casefold()


def slug(value: str) -> str:
    text = comparison_key(value)
    text = re.sub(r"[^a-z0-9]+", "-", text).strip("-")
    return text[:80]


def plain(raw: str) -> str:
    text = html.unescape(raw)
    text = re.sub(r"(?is)<script.*?>.*?</script>", " ", text)
    text = re.sub(r"(?is)<style.*?>.*?</style>", " ", text)
    text = re.sub(r"(?s)<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", text)


def load_evidence() -> dict[str, str]:
    files = {
        "usgs": CACHE / "usgs.bin",
        "usgs-fs": CACHE / "usgs-fs.txt",
        "roc": CACHE / "roc.bin",
        "al": None,
        "zoo": CACHE / "zoo.bin",
        "ls6": CACHE / "ls6.bin",
        "bbc": CACHE / "bbc.bin",
        "cfpb": CACHE / "cfpb-blocks.txt",
        "owl-gen": CACHE / "owl_gen.bin",
        "owl-proc": CACHE / "owl_proc.bin",
        "wdsf": CACHE / "wdsf_disc.bin",
        "asc-fms": CACHE / "asc_fms.bin",
        "asc-obj": CACHE / "asc_obj.bin",
        "ovep": CACHE / "ovep.txt",
    }
    out = {}
    for key, path in files.items():
        if key == "al":
            parts = [plain(item.read_text(encoding="utf-8", errors="replace")) for item in sorted(CACHE.glob("al_*.bin"))]
            if not parts:
                raise SystemExit("Missing Astronomical League cache")
            out[key] = " ".join(parts)
            continue
        if not path.exists():
            raise SystemExit(f"Missing cached source text: {path}")
        raw = path.read_text(encoding="utf-8", errors="replace")
        out[key] = plain(raw) if path.suffix == ".bin" else re.sub(r"\s+", " ", raw)
    return out


def rec(**kwargs) -> dict:
    row = {
        "candidate_id": f"c002:{kwargs['source_id']}:{slug(kwargs['source_title'])}",
        "source_language": "en",
        "adaptation_hint": None,
        "consumer_relevance": kwargs.get("consumer_relevance", "high"),
        "candidate_type": kwargs.get("candidate_type", "praktyczna czynność"),
    }
    row.update(kwargs)
    return row


def records() -> list[dict]:
    usgs = "https://www.usgs.gov/educational-resources/finding-your-way-map-and-compass"
    usgs_fs = "https://pubs.usgs.gov/fs/2001/0035/report.pdf"
    roc = "https://roc.us.orienteering.org/What-is-Orienteering"
    al = "https://www.astroleague.org/observing-programs-by-experience-level-of-observer/"
    zoo = "https://www.zooniverse.org/projects"
    learn = "https://www.learningscientists.org/blog/2016/8/18-1"
    bbc = "https://www.bbcgoodfood.com/howto/guide/25-skills-every-cook-should-know"
    cfpb = "https://files.consumerfinance.gov/f/documents/092016_cfpb_BuildingBlocksReport_PDF.pdf"
    owl_g = "https://owl.purdue.edu/owl/general_writing/index.html"
    owl_p = "https://owl.purdue.edu/owl/general_writing/the_writing_process/index.html"
    wdsf = "https://www.worlddancesport.org/About/Dance-Styles/DanceSport-Disciplines"
    asc = "https://www.ausport.gov.au/athlete_development/top_10_tips_for_parents/smart_bullets/tip_2"
    obj = "https://www.ausport.gov.au/physical_literacy/physical/framework/object_manipulation"
    ovep = "https://gstatic.olympics.com/s3/mc2026/documents/Education%20Programme/OVEP/English%20Toolkit/OVEP-Fundamentals-2023%20-%20English.pdf"
    rows = [
        rec(
            source_id="usgs-map-and-compass",
            source_item_id="topographic maps",
            source_title="Topographic maps",
            source_description="They define and locate natural and manmade features like woodlands, waterways, important buildings, and bridges.",
            source_url=usgs,
            source_category="map reading",
            evidence_file="usgs",
            evidence="Topics: Topographic maps, contours, elevation, navigation, compass use, compass reading, distance, map scale",
            provenance_note="Topic label from the USGS educational page. The fact sheet adds that features are shown by colored areas and standard symbols. Elevation and navigation were not stored as further skills. Map series were not split.",
        ),
        rec(
            source_id="usgs-map-and-compass",
            source_item_id="contours",
            source_title="contours",
            source_description="These are imaginary lines that follow the ground surface at a constant elevation",
            source_url=usgs_fs,
            source_category="map reading",
            evidence_file="usgs-fs",
            evidence="imaginary lines that follow the ground surface at a constant elevation",
            provenance_note="Topic label contours. Index contours, the contour interval, and close lines for steep slopes are the same fact-sheet section.",
        ),
        rec(
            source_id="usgs-map-and-compass",
            source_item_id="map scale",
            source_title="map scale",
            source_description="Maps are made to scale; that is, there is a direct relationship, a ratio, between a unit of measurement on the map and the actual distance that same unit of measurement represents on the ground.",
            source_url=usgs,
            source_category="map reading",
            evidence_file="usgs",
            evidence="Maps are made to scale",
            provenance_note="The topic list also says distance. Measuring distance is this same skill and was not stored again. The fact sheet describes the graphic scale bar in that section.",
        ),
        rec(
            source_id="usgs-map-and-compass",
            source_item_id="compass reading",
            source_title="compass reading",
            source_description="To determine the direction, or bearing, from one point to another, you need a compass as well as a map.",
            source_url=usgs_fs,
            source_category="compass",
            evidence_file="usgs-fs",
            evidence="To determine the direction, or bearing",
            provenance_note="The topic list names both compass use and compass reading. They were not split. Cardinal directions and the 360-degree circle are in the same section.",
        ),
        rec(
            source_id="usgs-map-and-compass",
            source_item_id="declination",
            source_title="declination",
            source_description="A diagram in the map margin will show the difference (declination) at the center of the map between compass north",
            source_url=usgs_fs,
            source_category="compass",
            evidence_file="usgs-fs",
            evidence="difference (declination)",
            provenance_note="Named in the fact sheet as the difference between compass north and true north. Kept apart from compass reading.",
        ),
        rec(
            source_id="roc-what-is-orienteering",
            source_item_id="map to terrain",
            source_title="reading the map and relating it to the terrain",
            source_description="In fact, the primary skill in orienteering is reading the map and relating it to the terrain.",
            source_url=roc,
            source_category="orienteering",
            evidence_file="roc",
            evidence="primary skill in orienteering is reading the map and relating it to the terrain",
            provenance_note="Overlaps USGS topographic-map reading. Kept because the page describes a sport map. White through Blue course colors are ability levels and were not imported.",
        ),
        rec(
            source_id="roc-what-is-orienteering",
            source_item_id="orient the map",
            source_title="orienting the map",
            source_description="The compass aids in orienting the map to the proper direction and for locating controls that are away from trails and other distinctive features.",
            source_url=roc,
            source_category="orienteering",
            evidence_file="roc",
            evidence="The compass aids in orienting the map",
            provenance_note="Compass use here is map orientation, not a second declination skill.",
        ),
        rec(
            source_id="roc-what-is-orienteering",
            source_item_id="route choice",
            source_title="choose routes",
            source_description="The object is to choose routes, which can be both on and off trail, that will help you find all the points in order and get back to the finish in the shortest amount of time.",
            source_url=roc,
            source_category="orienteering",
            evidence_file="roc",
            evidence="choose routes, which can be both on and off trail",
            provenance_note="On-trail and off-trail choices stay inside this record. Course colors were not split.",
        ),
        rec(
            source_id="roc-what-is-orienteering",
            source_item_id="map symbols",
            source_title="Map Symbols Legend",
            source_description="symbols are defined for the Map Symbols Legend",
            source_url=roc,
            source_category="orienteering",
            evidence_file="roc",
            evidence="symbols are defined for the Map Symbols Legend",
            provenance_note="The legend page itself was not fetched. Overlaps USGS symbol reading and was kept for later comparison.",
        ),
        rec(
            source_id="roc-what-is-orienteering",
            source_item_id="control descriptions",
            source_title="Control Descriptions",
            source_description="Control Descriptions the are used on orienteering maps.",
            source_url=roc,
            source_category="orienteering",
            evidence_file="roc",
            evidence="Control Descriptions",
            provenance_note="The page names control descriptions separately from the map-symbol legend. The sentence on the page is ungrammatical and was not rewritten.",
        ),
    ]
    astronomy = [
        ("Lunar Observing Program", "Moon observing. Lunar II, Lunar Evolution, and the binocular lunar program differ by level, equipment, or object list and were not added."),
        ("Constellation Hunter Observing Program", "Constellation recognition. Northern, southern, alternate, Beyond Polaris, and asterism variants were not added."),
        ("Meteor Observing Program", "Meteor observing. The 6, 12, 18, and 24 hour awards are levels of one program."),
        ("Deep Sky Binocular Observing Program", "Binocular observing as a method. Binocular Messier, binocular double star, and southern binocular lists were not added as separate skills."),
        ("Sketching Observing Award", "Recording observations by sketching. Many other programs require a log; a separate generic journal skill was not invented."),
        ("Citizen Science Special Program", "Taking part in an astronomical observing project. Not duplicated under Zooniverse."),
        ("Sunspotters Observing Program", "Solar observing. H-alpha and analemma programs were not added."),
        ("Solar System Observing Program", "Observing solar-system objects. The Galileo program was not added as a second planet list."),
        ("Comet Observing Program", "Comet observing. Silver and gold are levels, not separate skills."),
        ("Asteroid Observing Program", "Asteroid observing. Gold and Target NEO were not added."),
        ("Variable Star Observing Program", "Variable-star observing. The binocular program and the nova program were not added."),
        ("Double Star Observing Program", "Double-star observing. Advanced binocular and multiple-star variants were not added."),
        ("Messier Observing Program", "Identifying selected deep-sky objects. Caldwell, Herschel, Bennett, nebula, cluster, and galaxy programs are object-list variants and were not added."),
        ("Occultation Observing Program", "Timing an occultation. Kept because the method differs from catalog identification."),
        ("Radio Astronomy Observing Program", "Radio observing. Bronze, silver, and gold are levels."),
        ("Foundations of Imaging Observing Program", "Recording the sky with imaging equipment. Not split from visual observing by camera model."),
        ("Earth Orbiting Satellite Observing Program", "Observing Earth-orbiting satellites. Not merged with solar-system objects because the page lists it separately."),
    ]
    for title, note in astronomy:
        rows.append(
            rec(
                source_id="astronomical-league-observing-programs",
                source_item_id=slug(title),
                source_title=title,
                source_description=None,
                source_url=al,
                source_category="amateur astronomy",
                candidate_type="hobby",
                evidence_file="al",
                evidence=title,
                provenance_note=note + " Program and award names were used as hints. Youth, outreach, and master-observer awards were not imported.",
            )
        )
    zooniverse = [
        (
            "classifying trail camera images",
            "Observe wildlife by classifying trail camera images",
            "snapshot-dubuque",
            "image classification",
            "Observe wildlife by classifying trail camera images",
            "Original phrase from one project blurb. It stands for image and observation classification. Overlap Zoo, Chimp&See, Snapshot Hoge Veluwe, Dolphin Chat, Aurora Zoo, Kelp Forest, and other classify projects on the first page were not added.",
        ),
        (
            "transcribing letters",
            "seventeenth and eighteenth century European religious minorities by transcribing letters",
            "print",
            "transcription",
            "transcribing letters",
            "Original phrase. Specimen-label and weather-archive transcription on the same page were not added again.",
        ),
        (
            "georeference museum specimen records",
            "Help georeference museum specimen records by matching locality descriptions to places on a map.",
            "notes-from-nature-map",
            "georeferencing",
            "Help georeference museum specimen records",
            "Original phrase. Overlaps map reading and was kept because the task is matching a written locality to a map.",
        ),
        (
            "transit light curves",
            "Explore ultra-precise transit light curves and help discover new worlds",
            "planet-hunters-tess",
            "data interpretation",
            "Explore ultra-precise transit light curves",
            "Original phrase for reading a scientific display. Spiral Graph was not added as a second interpretation skill. Project names are examples, not skills.",
        ),
    ]
    for title, description, item, category, evidence, note in zooniverse:
        rows.append(
            rec(
                source_id="zooniverse-project-directory",
                source_item_id=item,
                source_title=title,
                source_description=description,
                source_url=zoo,
                source_category=category,
                evidence_file="zoo",
                evidence=evidence,
                provenance_note=note + " The directory showed 71 projects; only the first page was read. Projects were not imported one for one.",
            )
        )
    for title in [
        "Spacing",
        "Retrieval Practice",
        "Elaboration",
        "Interleaving",
        "Concrete Examples",
        "Dual Coding",
    ]:
        rows.append(
            rec(
                source_id="learning-scientists-six-strategies",
                source_item_id=slug(title),
                source_title=title,
                source_description=None,
                source_url=learn,
                source_category="learning strategy",
                candidate_type="skill",
                evidence_file="ls6",
                evidence=title,
                provenance_note="Named in the 18 August 2016 post. The saved page lists the six names and does not define them, so no definition was added. This is a study strategy, not a claim of higher intelligence or a larger memory. The PMC review uses the same six headings and was not imported again.",
            )
        )
    cooking = [
        ("How to master basic knife skills", "Knife work. Chopping an onion, crushing garlic, chillies, and preparing avocado are examples on the same page and were not added."),
        ("How to separate an egg", "Separating an egg. Not treated as a skill for one ingredient beyond the method the page names."),
        ("How to knead dough", "Kneading. No separate dough recipes were added."),
        ("How to brown meat", "Browning. Roast chicken was not added as another skill."),
        ("How to make gravy", "One sauce method. Tomato sauce was not added as a second sauce."),
        ("How to make stock", "Stock. Kept separate from gravy because the page gives it its own method."),
        ("How to cook rice", "Absorption cooking. Pasta was not added."),
        ("How to make a salad dressing", "A dressing method. The page explains a vinaigrette. Not a skill per salad."),
        ("How to stay safe in the kitchen", "Kitchen safety as its own listed skill."),
        ("How to make a batter", "Batter. Not split by dish."),
        ("How to rub flour and butter", "Rubbing in. Not a skill per pastry."),
        ("How to cook the perfect steak", "Judging doneness. The roast-chicken juice and thermometer check on the same page was not stored again."),
        ("How to poach an egg", "Poaching as a method. The heading names an egg; boiling an egg and omelette were not added."),
        ("How to melt chocolate", "Controlling temperature with a bain-marie, using the page's chocolate example. Not expanded to other ingredients."),
    ]
    for title, note in cooking:
        rows.append(
            rec(
                source_id="bbc-good-food-25-skills",
                source_item_id=slug(title),
                source_title=title,
                source_description=None,
                source_url=bbc,
                source_category="cooking",
                evidence_file="bbc",
                evidence=title,
                provenance_note=note + " The page loaded without a redirect. Seasoning and station organisation were requested but have no own heading here, so they were not invented.",
            )
        )
    finance = [
        (
            "Saving",
            "performing adult financial tasks such as setting financial goals, saving, and setting and following a budget.",
            "setting financial goals, saving, and setting and following a budget",
            "Named in that sentence and in the adult-application list. Age bands were not split. Executive function was not imported.",
        ),
        (
            "setting financial goals",
            "performing adult financial tasks such as setting financial goals, saving, and setting and following a budget.",
            "setting financial goals",
            "Named separately from saving and budgeting. Executive function was not imported.",
        ),
        (
            "developing and executing budgets",
            "Saving, setting financial goals, developing and executing budgets",
            "developing and executing budgets",
            "The report also says setting and following a budget and sticking to a spending plan. Those were not added again. Having a system to pay bills on time is in the same list and was not split off.",
        ),
        (
            "Effective comparison shopping",
            "Youth at this stage can learn how to find and recognize reliable financial information and how to compare financial products.",
            "Effective comparison shopping",
            "One comparison skill. Individual banking products and forms were not split. No investment advice.",
        ),
        (
            "financial research",
            "one needs to be able to do effective, purposeful financial research in order to analyze options and to be able to figure out how to execute on financial decisions.",
            "purposeful financial research",
            "Research before a consumer decision. Not investment advice.",
        ),
        (
            "evaluating interest payments",
            "evaluating interest payments for a credit card, auto loan, or student loan.",
            "evaluating interest payments",
            "Credit cards, auto loans, and student loans are examples in one sentence, not separate skills.",
        ),
    ]
    for title, description, evidence, note in finance:
        rows.append(
            rec(
                source_id="cfpb-building-blocks-2016",
                source_item_id=slug(title),
                source_title=title,
                source_description=description,
                source_url=cfpb,
                source_category="personal finance",
                evidence_file="cfpb",
                evidence=evidence,
                provenance_note=note + " Live educator pages returned HTTP 403. This report is the linked Building Blocks source available through the Internet Archive. Fraud recognition was not found in the retrieved text.",
            )
        )
    writing = [
        ("owl-proc", owl_p, "Prewriting (Invention)", "Invention before drafting. Not a skill per document type."),
        ("owl-proc", owl_p, "Developing an Outline", "Outlining. Reverse outlining is stored separately because the page gives it another method."),
        ("owl-proc", owl_p, "Reverse Outlining", "A revision outline made from an existing draft. Overlaps outlining and was kept for later comparison."),
        ("owl-proc", owl_p, "Tips and Examples for Writing Thesis Statements", "Stating the central claim. Not a skill per essay genre."),
        ("owl-proc", owl_p, "Proofreading", "Final correction. Distinct from the cohesion revision record."),
        ("owl-proc", owl_p, "Revising for Cohesion", "Revision for how parts connect. Other revision pages were not each imported."),
        ("owl-proc", owl_p, "Giving Feedback for Peer Review", "Responding to another writer's draft. Interpreting feedback is mentioned in the process and was not a second record."),
        ("owl-gen", owl_g, "Establishing Arguments", "Building an argument. Logic in argumentative writing was not imported again from the same index."),
        ("owl-gen", owl_g, "Conciseness", "Cutting text. The Paramedic Method is a lesson inside this topic, not a second skill."),
        ("owl-gen", owl_g, "Paragraphs and Paragraphing", "Organising information into paragraphs."),
        ("owl-gen", owl_g, "Email Etiquette", "Written correspondence. Personal-letter pages were not added."),
        ("owl-gen", owl_g, "Analyzing Visual Documents", "Reading visual material as part of writing. Not a second skill per chart type."),
    ]
    for evidence_file, url, title, note in writing:
        rows.append(
            rec(
                source_id="purdue-owl-writing",
                source_item_id=slug(title),
                source_title=title,
                source_description=None,
                source_url=url,
                source_category="writing",
                candidate_type="skill",
                evidence_file=evidence_file,
                evidence=title,
                provenance_note=note + " Only the two specified index pages were used. Grammar topics, citation styles, and document genres were not imported. Article text was not copied.",
            )
        )
    dance = [
        ("Acrobatic Rock'n'Roll", "Acrobatic Rock'n'Roll is characterised by high-precision, fast movements. The page says little of the original rock 'n' roll remains, so this was not merged with a generic social dance."),
        ("Boogie Woogie", "Fast footwork that is led rather than performed as a fixed choreography. Leading and following are described here and were not given a separate title."),
        ("Breaking", "The page describes breaking, or b-boying, as an athletic urban dance. The Olympic list also names breaking; that second copy was not added."),
        ("Disco Dance", "The page names contraction and release, turns, kicks, and jumps as disco technique."),
        ("Hip Hop", "Umbrella discipline. Oldschool, midschool, newschool, locking, popping, and electric boogaloo were named and not split."),
        ("Latin Dances", "One Latin family. Samba, cha-cha-cha, rumba, paso doble, and jive were not split because the page does not describe each technique."),
        ("Rhythm", "The page says Rhythm uses different counts and hip motion from International Latin. The individual Rhythm dances were not split. Overlap with Latin remains for later comparison."),
        ("Salsa", "One salsa skill. Country styles and the named source dances were not split."),
        ("Smooth", "The page distinguishes Smooth by allowing dancers to release the hold and dance solo. Waltz, tango, foxtrot, and Viennese waltz were not added again."),
        ("Modern/Contemporary dance", "Contemporary dance, including floor work, balance, and control. Named technique sources such as Graham and Cunningham were not split. Choreography is mentioned inside this description and was not a separate record."),
        ("Jazz Dance", "Jazz technique, including isolations and jazz walks. Lindy Hop and Charleston are examples in the paragraph, not extra skills."),
        ("Standard Dances", "One Standard family. Waltz, tango, Viennese waltz, slow foxtrot, and quickstep share the closed-hold description and were not split."),
    ]
    for title, note in dance:
        rows.append(
            rec(
                source_id="wdsf-dancesport-disciplines",
                source_item_id=slug(title),
                source_title=title,
                source_description=None,
                source_url=wdsf,
                source_category="dance",
                candidate_type="aktywność",
                evidence_file="wdsf",
                evidence=title,
                provenance_note=note + " Ten Dance, Para DanceSport, and Special Olympics are formats of related dances and were not added. The Standard-Latin-10Dance page was read and did not add a further technique.",
            )
        )
    movement = [
        ("asc-obj", obj, "Throwing", "object manipulation", "Fundamental throw. Sport-specific throws named as transfer examples were not added."),
        ("asc-obj", obj, "Catching", "object manipulation", "Fundamental catch. Not repeated for each ball sport."),
        ("asc-obj", obj, "Kicking", "object manipulation", "Fundamental kick. Soccer and other sports in the transfer column were not added."),
        ("asc-obj", obj, "Striking", "object manipulation", "The page also says hitting. Hitting was not stored as a second record."),
        ("asc-obj", obj, "Dribbling", "object manipulation", "One dribbling skill. The sports used as examples were not added."),
        ("asc-fms", asc, "Hopping", "locomotion", "Fundamental hop."),
        ("asc-fms", asc, "Jumping", "locomotion", "Fundamental jump. Not split by sport."),
        ("asc-fms", asc, "Skipping", "locomotion", "Fundamental skip."),
        ("asc-fms", asc, "Balancing", "stability", "Balance. Standing on a surfboard is listed as an aquatic example and was not a second balance skill."),
        ("asc-fms", asc, "Tumbling", "stability", "Tumbling as a fundamental skill, not a gymnastics code."),
        ("asc-fms", asc, "Climbing", "stability", "Fundamental climbing. Sport climbing from the Olympic list was not added from its name alone."),
        ("asc-fms", asc, "Floating", "aquatic", "Aquatic flotation."),
        ("asc-fms", asc, "Early swimming strokes", "aquatic", "Beginning strokes. Not split into named strokes."),
        ("asc-fms", asc, "Paddling", "aquatic", "Paddling. Not split by craft."),
        ("asc-fms", asc, "Using a wheelchair", "locomotion", "Listed with the locomotive skills. A prosthetic limb is described as equipment for locomotion and was not a separate skill."),
    ]
    for evidence_file, url, title, category, note in movement:
        rows.append(
            rec(
                source_id="ausport-fundamental-movement",
                source_item_id=slug(title),
                source_title=title,
                source_description=None,
                source_url=url,
                source_category=category,
                candidate_type="aktywność",
                evidence_file=evidence_file,
                evidence=title,
                provenance_note=note + " Running was not added because an existing candidate already has that exact title. The physical-literacy page is a framework overview and was not turned into more skills.",
            )
        )
    olympic = [
        (
            "skiing",
            "Sliding, gliding and jumping on slippery or snowy hills on skis, skates or seats with runners under them are great fun for children and adults in countries that have cold winters.",
            "on skis",
            "The word skiing is in the same section. Alpine, cross-country, freestyle, ski jumping, and ski mountaineering were not split. Biathlon was not added because the page does not describe shooting.",
        ),
        (
            "skating",
            "Winter sports such as skating and skiing are popular in parts of the world where cold winter temperatures turn water into ice and rain into snow.",
            "skating and skiing",
            "Figure skating, short track, and speed skating were not split. Figure skating is also named in the judged-sport sentence and was not added again.",
        ),
        (
            "seats with runners",
            "Sliding, gliding and jumping on slippery or snowy hills on skis, skates or seats with runners under them are great fun for children and adults in countries that have cold winters.",
            "seats with runners",
            "Bobsleigh, luge, and skeleton were not split. The practical action in the sentence is sliding on runners.",
        ),
        (
            "Artistic gymnastics",
            "Gymnastics, diving and figure skating are three examples. The panel of judges look for things like spectacular moves, body control, artistic style and difficulty of movements or combinations of movements.",
            "Artistic Gymnastics",
            "The sports list names artistic gymnastics. Rhythmic gymnastics and trampoline were not split. The judging sentence says gymnastics.",
        ),
        (
            "Diving",
            "Gymnastics, diving and figure skating are three examples. The panel of judges look for things like spectacular moves, body control, artistic style and difficulty of movements or combinations of movements.",
            "Gymnastics, diving and figure skating",
            "Diving is one of the three judged examples. Platform and springboard were not split.",
        ),
        (
            "Learning to play fair",
            "Fair play does not only mean adherence to written rules: rather it describes the right attitudes of sportsmen and sportswomen and the right spirit in which they conduct themselves",
            "Learning to play fair",
            "Section heading. The sentence is the International Fair Play Charter quotation in the toolkit. Joy of effort, respect, and excellence were not imported as skills.",
        ),
    ]
    for title, description, evidence, note in olympic:
        rows.append(
            rec(
                source_id="olympic-education-fundamentals-2023",
                source_item_id=slug(title),
                source_title=title,
                source_description=description,
                source_url=ovep,
                source_category="sport",
                candidate_type="aktywność",
                evidence_file="ovep",
                evidence=evidence,
                provenance_note=note + " The Paris 2024 and winter-sport names were used only to find gaps. A name alone was not enough.",
            )
        )
    return rows


NEW_SOURCES = [
    {
        "source_id": "usgs-map-and-compass",
        "name": "USGS — Finding Your Way with Map and Compass",
        "organization": "U.S. Geological Survey",
        "url": "https://www.usgs.gov/educational-resources/finding-your-way-map-and-compass",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Topographic-map reading, scale, contours, bearings, and declination from the educational page and its linked fact sheet.",
        "limits": "The educational page is a topic index. Skill text comes from the linked fact sheet FS 2001-0035. Map series were not split.",
        "license": "USGS fact sheet. U.S. government work; attribute the U.S. Geological Survey.",
    },
    {
        "source_id": "roc-what-is-orienteering",
        "name": "Rochester Orienteering Club — What is Orienteering?",
        "organization": "Rochester Orienteering Club",
        "url": "https://roc.us.orienteering.org/What-is-Orienteering",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Map-to-terrain reading, map orientation, route choice, symbols, and control descriptions.",
        "limits": "Course colors are ability levels and were not imported. The symbol-legend page was not fetched.",
        "license": "Page content belongs to Rochester Orienteering Club. Short quotations only.",
    },
    {
        "source_id": "zooniverse-project-directory",
        "name": "Zooniverse — Project Directory",
        "organization": "Zooniverse",
        "url": "https://www.zooniverse.org/projects",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Activity types from the first page of active projects: classification, transcription, georeferencing, and interpretation.",
        "limits": "The page said 71 projects and four pages. Only page 1 was read. Projects were not converted one for one.",
        "license": "Project blurbs cited from Zooniverse. No project content was copied beyond one sentence.",
    },
    {
        "source_id": "learning-scientists-six-strategies",
        "name": "The Learning Scientists — Six Strategies for Effective Learning",
        "organization": "The Learning Scientists",
        "url": "https://www.learningscientists.org/blog/2016/8/18-1",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "The six named study strategies.",
        "limits": "The saved post names the strategies and does not define them. No memory or intelligence gain is claimed.",
        "license": "Copyright The Learning Scientists. Strategy names only.",
    },
    {
        "source_id": "learning-scientists-concrete-examples",
        "name": "The Learning Scientists — Episode 10: Concrete Examples",
        "organization": "The Learning Scientists",
        "url": "https://www.learningscientists.org/learning-scientists-podcast/2018/1/3/episode-10-concrete-examples",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Checked as a second discussion of concrete examples.",
        "records_written": 0,
        "limits": "No additional candidate. Concrete examples is already recorded from the six-strategies post.",
        "license": "Copyright The Learning Scientists.",
    },
    {
        "source_id": "pmc-teaching-science-of-learning",
        "name": "Teaching the science of learning",
        "organization": "Weinstein, Madan, and Sumeracki; PubMed Central",
        "url": "https://pmc.ncbi.nlm.nih.gov/articles/PMC5780548/",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Checked so the same six strategies were not imported twice.",
        "records_written": 0,
        "limits": "The article sections match Spacing, Retrieval Practice, Elaboration, Interleaving, Concrete Examples, and Dual Coding. No extra records.",
        "license": "Creative Commons Attribution 4.0 International. Weinstein, Madan, and Sumeracki, 2018.",
    },
    {
        "source_id": "bbc-good-food-25-skills",
        "name": "BBC Good Food — 25 skills every cook should know",
        "organization": "Immediate Media / BBC Good Food",
        "url": "https://www.bbcgoodfood.com/howto/guide/25-skills-every-cook-should-know",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Method-level cooking techniques from the 25 headings.",
        "limits": "The page loaded directly. Dish, ingredient, and recipe headings were not imported. Seasoning and station organisation are not separate headings.",
        "license": "Copyright Immediate Media. Headings only.",
    },
    {
        "source_id": "cfpb-financial-well-being-resources",
        "name": "CFPB — Financial Well-Being Resources",
        "organization": "Consumer Financial Protection Bureau",
        "url": "https://www.consumerfinance.gov/consumer-tools/educator-tool/financial-well-being-resources/",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Requested source for personal-finance skills.",
        "records_written": 0,
        "limits": "Live request returned HTTP 403 Access Denied. No archive snapshot was found.",
        "license": "Not read.",
    },
    {
        "source_id": "cfpb-adult-financial-education",
        "name": "CFPB — Tools and Resources for Adult Financial Education",
        "organization": "Consumer Financial Protection Bureau",
        "url": "https://www.consumerfinance.gov/consumer-tools/educator-tool/adult-financial-education/tools-and-resources/",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Requested source for adult financial-education tools.",
        "records_written": 0,
        "limits": "Live request returned HTTP 403 Access Denied. No archive snapshot was found.",
        "license": "Not read.",
    },
    {
        "source_id": "cfpb-building-blocks-2016",
        "name": "CFPB — Building blocks to help youth achieve financial capability",
        "organization": "Consumer Financial Protection Bureau",
        "url": "https://www.consumerfinance.gov/consumer-tools/educator-tools/youth-financial-education/learn/",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Concrete consumer skills from the learn page and the linked 2016 Building Blocks report.",
        "limits": "The live learn page returned HTTP 403. The report was read from the Internet Archive snapshot of 5 June 2019. Age bands and financial products were not split. Fraud was not found in the report text.",
        "license": "U.S. government work. Attribute the Consumer Financial Protection Bureau.",
        "accessed_via": "https://web.archive.org/web/20190605130534/https://files.consumerfinance.gov/f/documents/092016_cfpb_BuildingBlocksReport_PDF.pdf",
    },
    {
        "source_id": "inaturalist-getting-started",
        "name": "iNaturalist — Getting Started",
        "organization": "iNaturalist",
        "url": "https://www.inaturalist.org/pages/getting-started",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Requested source for nature-observation skills.",
        "records_written": 0,
        "limits": "Live request returned HTTP 403. No public archive snapshot was found.",
        "license": "Not read.",
    },
    {
        "source_id": "inaturalist-birdwatching",
        "name": "iNaturalist — Easy birdwatching tips for new naturalists",
        "organization": "iNaturalist",
        "url": "https://www.inaturalist.org/pages/birdsaroundyou",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Requested source for bird observation by sight and sound.",
        "records_written": 0,
        "limits": "Live request returned HTTP 403. No public archive snapshot was found.",
        "license": "Not read.",
    },
    {
        "source_id": "purdue-owl-writing",
        "name": "Purdue OWL — General Writing and The Writing Process",
        "organization": "Purdue University Online Writing Lab",
        "url": "https://owl.purdue.edu/owl/general_writing/index.html",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Distinct writing methods named on the two specified index pages.",
        "limits": "Document genres, grammar topics, and citation styles were not imported. Article bodies were not copied. The OWL pages say the material is not to be republished.",
        "license": "Copyright Purdue University Online Writing Lab. Headings only.",
        "also_url": "https://owl.purdue.edu/owl/general_writing/the_writing_process/index.html",
    },
    {
        "source_id": "wdsf-dancesport-disciplines",
        "name": "WDSF — DanceSport Disciplines",
        "organization": "World DanceSport Federation",
        "url": "https://www.worlddancesport.org/About/Dance-Styles/DanceSport-Disciplines",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Dance practices that the page describes as distinct techniques.",
        "limits": "Dances that share one description were kept as one family. Ten Dance and Para DanceSport are formats, not extra skills.",
        "license": "Copyright World DanceSport Federation. Short quotations only.",
        "also_url": "https://www.worlddancesport.org/Standard-Latin-10Dance",
    },
    {
        "source_id": "ausport-fundamental-movement",
        "name": "Australian Sports Commission — Fundamental movement skills",
        "organization": "Australian Sports Commission",
        "url": "https://www.ausport.gov.au/athlete_development/top_10_tips_for_parents/smart_bullets/tip_2",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Fundamental movement skills from the parent tip and the object-manipulation framework.",
        "limits": "Sport names in the transfer column were not imported. Running was skipped because that exact title already exists. Stages 0–4 are levels and were not imported.",
        "license": "Copyright Australian Sports Commission. Skill names as published.",
        "also_url": "https://www.ausport.gov.au/physical_literacy/physical/framework/object_manipulation",
        "framework_url": "https://www.ausport.gov.au/clearinghouse/evidence/physical-literacy",
    },
    {
        "source_id": "olympic-education-fundamentals-2023",
        "name": "Olympic Education Programme — OVEP Fundamentals 2023",
        "organization": "International Olympic Committee",
        "url": "https://gstatic.olympics.com/s3/mc2026/documents/Education%20Programme/OVEP/English%20Toolkit/OVEP-Fundamentals-2023%20-%20English.pdf",
        "retrieved_on": TODAY,
        "language": "en",
        "use": "Beginner-accessible practices described in the sports-programme section. Names alone were not imported.",
        "limits": "Most listed Olympic sports were not imported. Breaking was not repeated because WDSF already records it.",
        "license": "IOC material. The toolkit permits non-commercial educational use and says the material must not be modified or sublicensed. Short quotations only.",
    },
]


def update_sources(added_counts: dict[str, int]) -> None:
    path = OUT / "sources.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    known = {item["source_id"] for item in data["sources"]}
    for item in data["sources"]:
        if item["source_id"] == "astronomical-league-observing-programs":
            item["records_written"] = added_counts.get(item["source_id"], 0)
            item["access_status"] = "downloaded"
            item["completeness"] = (
                "Consolidated observing practices from the four specified program pages. "
                "Variants that differ only by level, equipment, or object list were not added. "
                "Youth and master awards were not imported."
            )
            item["license"] = "Copyright Astronomical League. Program names only."
            item["attribution_required"] = "Astronomical League"
            item["notes"] = (
                "Stage 1 left this source unused because the A-to-C page is an object-class list. "
                "Stage 2 recorded one candidate per observing practice. "
                "https://www.astroleague.org/observing-program-division/ "
                "https://www.astroleague.org/observing-programs-a-to-c/ "
                "https://www.astroleague.org/observing-programs-arranged-by-equipment-needed/ "
                "https://www.astroleague.org/observing-programs-by-experience-level-of-observer/"
            )
    for source in NEW_SOURCES:
        if source["source_id"] in known:
            raise SystemExit(f"Source id already exists: {source['source_id']}")
        count = added_counts.get(source["source_id"], 0)
        notes = source["use"]
        if source.get("accessed_via"):
            notes += " Accessed via " + source["accessed_via"] + "."
        if source.get("also_url"):
            notes += " Also read: " + source["also_url"] + "."
        if source.get("framework_url"):
            notes += " Framework page checked and not used as a skill list: " + source["framework_url"] + "."
        data["sources"].append(
            {
                "source_id": source["source_id"],
                "title": source["name"],
                "publisher": source["organization"],
                "organization": source["organization"],
                "url": source["url"],
                "download_url": source.get("accessed_via", source["url"]),
                "source_type": "catalog-002 source",
                "domains": [],
                "retrieved_on": source["retrieved_on"],
                "language": source["language"],
                "access_status": "not read" if source["license"] == "Not read." else "downloaded",
                "completeness": source["limits"],
                "license": source["license"],
                "attribution_required": source["organization"],
                "notes": notes,
                "use": source["use"],
                "records_written": count,
            }
        )
        known.add(source["source_id"])
    data["catalog_002_retrieved_on"] = TODAY
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def update_report(before: int, added: list[dict], skipped: list[str]) -> None:
    counts: dict[str, int] = {}
    for row in added:
        counts[row["source_id"]] = counts.get(row["source_id"], 0) + 1
    lines = [
        "",
        "## Etap T4S-CATALOG-002",
        "",
        f"Stan przed tym etapem: {before} rekordów surowych i {before} rekordów znormalizowanych.",
        f"Nowe rekordy: {len(added)}.",
        f"Stan po tym etapie: {before + len(added)} rekordów surowych i tyle samo znormalizowanych.",
        "To nadal są kandydatury, nie unikalne umiejętności. Deduplikacja nie została uruchomiona.",
        "Cel roboczy 500 nowych kandydatur nie został osiągnięty. Źródła nie zawierają 500 odrębnych czynności bez dzielenia gatunków, dań, produktów, poziomów i nazw dyscyplin.",
        "",
        "| Źródło | Nowe rekordy |",
        "| --- | ---: |",
    ]
    for source_id, count in sorted(counts.items()):
        lines.append(f"| `{source_id}` | {count} |")
    lines.extend(
        [
            "",
            "Źródła bez nowych rekordów: iNaturalist Getting Started, iNaturalist birdwatching, CFPB Financial Well-Being Resources, CFPB adult financial-education tools, Learning Scientists concrete-examples episode, PMC review. Dwa ostatnie powtarzają strategie już zapisane.",
            "",
            "Dziedziny nowych rekordów: mapa i kompas, orientacja sportowa, astronomia amatorska, typy działań nauki obywatelskiej, strategie uczenia się, techniki gotowania, finanse osobiste, pisanie, taniec, podstawowe umiejętności ruchowe i kilka opisanych praktyk sportowych.",
            "",
            "Możliwe nakładanie, zostawione do późniejszego porównania:",
            "- czytanie mapy USGS i czytanie mapy orientacyjnej;",
            "- symbole USGS i legenda mapy orientacyjnej;",
            "- łacina, Rhythm i Smooth;",
            "- breaking w WDSF i na liście olimpijskiej;",
            "- sześć strategii Learning Scientists i te same nagłówki artykułu PMC;",
            "- budżet i plan wydatków w raporcie CFPB, zapisane jako jeden rekord;",
            "- striking i hitting, zapisane jako jeden rekord;",
            "- bieg ASC nie został dodany, bo tytuł `running` już istnieje.",
            "",
            "Nadal słabo reprezentowane: rozpoznawanie organizmów po wyglądzie i głosie, oszustwa finansowe, przyprawianie i organizacja stanowiska kuchennego, choreografia jako osobna praktyka oraz większość dyscyplin, których źródło podaje tylko nazwę.",
            "",
            "Nieodczytane:",
            "- https://www.inaturalist.org/pages/getting-started — HTTP 403, brak migawki archiwum;",
            "- https://www.inaturalist.org/pages/birdsaroundyou — HTTP 403, brak migawki archiwum;",
            "- https://www.consumerfinance.gov/consumer-tools/educator-tool/financial-well-being-resources/ — HTTP 403;",
            "- https://www.consumerfinance.gov/consumer-tools/educator-tool/adult-financial-education/tools-and-resources/ — HTTP 403.",
            "",
        ]
    )
    if skipped:
        lines.append("Pominięte identyczne tytuły: " + "; ".join(skipped) + ".")
        lines.append("")
    path = DOC_DIR / "coverage-report.md"
    text = path.read_text(encoding="utf-8")
    marker = "## Etap T4S-CATALOG-002"
    if marker in text:
        text = text.split(marker)[0].rstrip() + "\n"
    note = (
        "Liczby w sekcjach przed etapem T4S-CATALOG-002 opisują stan 15162 rekordów. "
        "Aktualna suma jest w sekcji tego etapu.\n\n"
    )
    if "Aktualna suma jest w sekcji tego etapu." not in text:
        text = text.replace(
            "Data generacji: 2026-10-18. ",
            "Data generacji pierwszego etapu: 2026-10-18. " + note,
            1,
        )
    path.write_text(text.rstrip() + "\n" + "\n".join(lines), encoding="utf-8")


def update_readme(total: int) -> None:
    path = DOC_DIR / "README.md"
    text = path.read_text(encoding="utf-8")
    old_count = "Aktualna liczba surowych kandydatur: **15162**."
    new_count = (
        f"Aktualna liczba surowych kandydatur: **{total}**. "
        "Przed etapem T4S-CATALOG-002 było ich 15162."
    )
    old_rerun = "Nie edytuj tysięcy wierszy ręcznie; zmień regułę w skrypcie i uruchom go ponownie."
    new_rerun = (
        "Nie edytuj tysięcy wierszy ręcznie. "
        "`build_catalog_research.py` odtwarza tylko pierwszy etap i odmawia nadpisania, "
        "gdy plik zawiera rekordy dodane później. "
        "Etap T4S-CATALOG-002 dopisuje `python3 scripts/catalog/append_catalog_002.py`."
    )
    if old_count not in text or old_rerun not in text:
        raise SystemExit("README sentences not found")
    path.write_text(text.replace(old_count, new_count).replace(old_rerun, new_rerun), encoding="utf-8")


def main() -> None:
    check_only(
        [
            OUT / "candidates-raw.jsonl",
            OUT / "candidates-normalized.jsonl",
            OUT / "sources.json",
            DOC_DIR / "coverage-report.md",
            DOC_DIR / "README.md",
        ]
    )
    evidence = load_evidence()
    raw_path = OUT / "candidates-raw.jsonl"
    norm_path = OUT / "candidates-normalized.jsonl"
    raw_before = raw_path.read_bytes()
    norm_before = norm_path.read_bytes()
    existing_ids = set()
    existing_keys = set()
    for line in raw_before.decode("utf-8").splitlines():
        row = json.loads(line)
        existing_ids.add(row["candidate_id"])
        existing_keys.add(comparison_key(row["source_title"]))
    added = []
    skipped = []
    missing = []
    for row in records():
        haystack = evidence[row["evidence_file"]].casefold()
        if row["evidence"].casefold() not in haystack:
            missing.append(row["source_title"])
            continue
        key = comparison_key(row["source_title"])
        if key in existing_keys:
            skipped.append(row["source_title"])
            continue
        if row["candidate_id"] in existing_ids:
            raise SystemExit(f"Duplicate candidate_id: {row['candidate_id']}")
        existing_ids.add(row["candidate_id"])
        existing_keys.add(key)
        added.append(row)
    if missing:
        raise SystemExit("Evidence missing for: " + "; ".join(missing))
    raw_lines = []
    norm_lines = []
    for row in added:
        raw = {key: row.get(key) for key in RAW_KEYS}
        raw_lines.append(json.dumps(raw, ensure_ascii=False, separators=(",", ":")))
        norm = {
            "candidate_id": row["candidate_id"] + ":normalized",
            "raw_candidate_id": row["candidate_id"],
            "source_id": row["source_id"],
            "source_item_id": row["source_item_id"],
            "source_title": norm_text(row["source_title"]),
            "normalized_title": norm_text(row["source_title"]),
            "comparison_key": comparison_key(row["source_title"]),
            "source_description": norm_text(row["source_description"]) or None,
            "source_url": row["source_url"],
            "source_language": row["source_language"],
            "source_category": row["source_category"],
            "candidate_type": row["candidate_type"],
            "consumer_relevance": row["consumer_relevance"],
            "adaptation_hint": None,
            "provenance_note": NORM_NOTE,
        }
        norm_lines.append(json.dumps(norm, ensure_ascii=False, separators=(",", ":")))
    raw_path.write_bytes(raw_before + ("\n".join(raw_lines) + "\n").encode("utf-8"))
    norm_path.write_bytes(norm_before + ("\n".join(norm_lines) + "\n").encode("utf-8"))
    if not raw_path.read_bytes().startswith(raw_before):
        raise SystemExit("Raw prefix changed")
    if not norm_path.read_bytes().startswith(norm_before):
        raise SystemExit("Normalized prefix changed")
    counts: dict[str, int] = {}
    for row in added:
        counts[row["source_id"]] = counts.get(row["source_id"], 0) + 1
    update_sources(counts)
    before = raw_before.count(b"\n")
    update_report(before, added, skipped)
    update_readme(before + len(added))
    digest = hashlib.sha256(raw_before).hexdigest()
    print(f"added={len(added)} before={before} after={before + len(added)} prefix_sha256={digest}")
    for source_id, count in sorted(counts.items()):
        print(f"{source_id} {count}")
    if skipped:
        print("skipped " + "; ".join(skipped))


if __name__ == "__main__":
    main()
