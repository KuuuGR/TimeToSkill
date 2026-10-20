#!/usr/bin/env python3
"""Write eo/isv interface files, fill Spanish gaps, and add the language picker keys."""

from __future__ import annotations

import re
import sys
from pathlib import Path

from ui_041_data import T

ROOT = Path(__file__).resolve().parents[2] / "TimeToSkill/TimeToSkill/Resources/Localization"
LINE = re.compile(r'^("(?:\\.|[^"\\])*")\s*=\s*("(?:\\.|[^"\\])*")\s*;\s*$')
KEY = re.compile(r'^"(?P<key>(?:\\.|[^"\\])*)"\s*=\s*"(?P<val>(?:\\.|[^"\\])*)"\s*;', re.M)

PICKER = {
    "en": {
        "language_picker_title": "Language",
        "language_phone": "Phone language",
        "language_phone_detail": "Uses the language of this device. English is used when that language has no translation.",
        "language_name_polish": "Polish",
        "language_name_english": "English",
        "language_name_spanish": "Spanish",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslavic",
        "language_script_latin": "Latin script",
        "language_script_cyrillic": "Cyrillic script",
        "language_script_glagolitic": "Glagolitic script",
    },
    "pl": {
        "language_picker_title": "Język",
        "language_phone": "Język telefonu",
        "language_phone_detail": "Używa języka tego urządzenia. Gdy nie ma tłumaczenia, aplikacja przechodzi na angielski.",
        "language_name_polish": "Polski",
        "language_name_english": "Angielski",
        "language_name_spanish": "Hiszpański",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Międzysłowiański",
        "language_script_latin": "Alfabet łaciński",
        "language_script_cyrillic": "Alfabet cyryliczny",
        "language_script_glagolitic": "Alfabet głagolicki",
    },
    "es": {
        "language_picker_title": "Idioma",
        "language_phone": "Idioma del teléfono",
        "language_phone_detail": "Usa el idioma de este dispositivo. Si no hay traducción, la aplicación usa el inglés.",
        "language_name_polish": "Polaco",
        "language_name_english": "Inglés",
        "language_name_spanish": "Español",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Intereslavo",
        "language_script_latin": "Alfabeto latino",
        "language_script_cyrillic": "Alfabeto cirílico",
        "language_script_glagolitic": "Alfabeto glagolítico",
    },
    "eo": {
        "language_picker_title": "Lingvo",
        "language_phone": "Lingvo de la telefono",
        "language_phone_detail": "Uzas la lingvon de ĉi tiu aparato. Se tiu lingvo ne estas tradukita, la apo uzas la anglan.",
        "language_name_polish": "Pola",
        "language_name_english": "Angla",
        "language_name_spanish": "Hispana",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslava",
        "language_script_latin": "Latina skribo",
        "language_script_cyrillic": "Cirila skribo",
        "language_script_glagolitic": "Glagolica skribo",
    },
    "isv": {
        "language_picker_title": "Jezyk",
        "language_phone": "Jezyk telefona",
        "language_phone_detail": "Upotrěblja jezyk tutogo ustrojstva. Kogda prěvoda nema, program upotrěblja anglijsky.",
        "language_name_polish": "Poljsky",
        "language_name_english": "Anglijsky",
        "language_name_spanish": "Ispansky",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Medžuslovjansky",
        "language_script_latin": "Latinsko pismo",
        "language_script_cyrillic": "Kirilsko pismo",
        "language_script_glagolitic": "Glagolsko pismo",
    },
    "de": {
        "language_picker_title": "Sprache",
        "language_phone": "Telefonsprache",
        "language_phone_detail": "Verwendet die Sprache dieses Geräts. Fehlt eine Übersetzung, wird Englisch verwendet.",
        "language_name_polish": "Polnisch",
        "language_name_english": "Englisch",
        "language_name_spanish": "Spanisch",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslawisch",
        "language_script_latin": "Lateinische Schrift",
        "language_script_cyrillic": "Kyrillische Schrift",
        "language_script_glagolitic": "Glagolitische Schrift",
    },
    "fr": {
        "language_picker_title": "Langue",
        "language_phone": "Langue du téléphone",
        "language_phone_detail": "Utilise la langue de cet appareil. S'il n'y a pas de traduction, l'application passe à l'anglais.",
        "language_name_polish": "Polonais",
        "language_name_english": "Anglais",
        "language_name_spanish": "Espagnol",
        "language_name_esperanto": "Espéranto",
        "language_name_interslavic": "Interslave",
        "language_script_latin": "Écriture latine",
        "language_script_cyrillic": "Écriture cyrillique",
        "language_script_glagolitic": "Écriture glagolitique",
    },
    "it": {
        "language_picker_title": "Lingua",
        "language_phone": "Lingua del telefono",
        "language_phone_detail": "Usa la lingua di questo dispositivo. Se non c'è una traduzione, l'app usa l'inglese.",
        "language_name_polish": "Polacco",
        "language_name_english": "Inglese",
        "language_name_spanish": "Spagnolo",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslavo",
        "language_script_latin": "Scrittura latina",
        "language_script_cyrillic": "Scrittura cirillica",
        "language_script_glagolitic": "Scrittura glagolitica",
    },
    "pt": {
        "language_picker_title": "Idioma",
        "language_phone": "Idioma do telefone",
        "language_phone_detail": "Usa o idioma deste dispositivo. Se não houver tradução, a aplicação usa inglês.",
        "language_name_polish": "Polaco",
        "language_name_english": "Inglês",
        "language_name_spanish": "Espanhol",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Intereslavo",
        "language_script_latin": "Escrita latina",
        "language_script_cyrillic": "Escrita cirílica",
        "language_script_glagolitic": "Escrita glagolítica",
    },
    "nl": {
        "language_picker_title": "Taal",
        "language_phone": "Taal van de telefoon",
        "language_phone_detail": "Gebruikt de taal van dit apparaat. Als er geen vertaling is, wordt Engels gebruikt.",
        "language_name_polish": "Pools",
        "language_name_english": "Engels",
        "language_name_spanish": "Spaans",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslavisch",
        "language_script_latin": "Latijns schrift",
        "language_script_cyrillic": "Cyrillisch schrift",
        "language_script_glagolitic": "Glagolitisch schrift",
    },
    "sv": {
        "language_picker_title": "Språk",
        "language_phone": "Telefonens språk",
        "language_phone_detail": "Använder språket på den här enheten. Om översättning saknas används engelska.",
        "language_name_polish": "Polska",
        "language_name_english": "Engelska",
        "language_name_spanish": "Spanska",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslaviska",
        "language_script_latin": "Latinsk skrift",
        "language_script_cyrillic": "Kyrillisk skrift",
        "language_script_glagolitic": "Glagolitisk skrift",
    },
    "da": {
        "language_picker_title": "Sprog",
        "language_phone": "Telefonens sprog",
        "language_phone_detail": "Bruger sproget på denne enhed. Hvis der ikke findes en oversættelse, bruges engelsk.",
        "language_name_polish": "Polsk",
        "language_name_english": "Engelsk",
        "language_name_spanish": "Spansk",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslavisk",
        "language_script_latin": "Latinsk skrift",
        "language_script_cyrillic": "Kyrillisk skrift",
        "language_script_glagolitic": "Glagolitisk skrift",
    },
    "nb": {
        "language_picker_title": "Språk",
        "language_phone": "Telefonens språk",
        "language_phone_detail": "Bruker språket på denne enheten. Hvis oversettelse mangler, brukes engelsk.",
        "language_name_polish": "Polsk",
        "language_name_english": "Engelsk",
        "language_name_spanish": "Spansk",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslavisk",
        "language_script_latin": "Latinsk skrift",
        "language_script_cyrillic": "Kyrillisk skrift",
        "language_script_glagolitic": "Glagolittisk skrift",
    },
    "fi": {
        "language_picker_title": "Kieli",
        "language_phone": "Puhelimen kieli",
        "language_phone_detail": "Käyttää tämän laitteen kieltä. Jos käännöstä ei ole, sovellus käyttää englantia.",
        "language_name_polish": "Puola",
        "language_name_english": "Englanti",
        "language_name_spanish": "Espanja",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslaavi",
        "language_script_latin": "Latinalainen kirjaimisto",
        "language_script_cyrillic": "Kyrillinen kirjaimisto",
        "language_script_glagolitic": "Glagoliittinen kirjaimisto",
    },
    "cs": {
        "language_picker_title": "Jazyk",
        "language_phone": "Jazyk telefonu",
        "language_phone_detail": "Použije jazyk tohoto zařízení. Když překlad chybí, aplikace přejde na angličtinu.",
        "language_name_polish": "Polština",
        "language_name_english": "Angličtina",
        "language_name_spanish": "Španělština",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Mezislovanština",
        "language_script_latin": "Latinka",
        "language_script_cyrillic": "Cyrilice",
        "language_script_glagolitic": "Hlaholice",
    },
    "sk": {
        "language_picker_title": "Jazyk",
        "language_phone": "Jazyk telefónu",
        "language_phone_detail": "Použije jazyk tohto zariadenia. Keď preklad chýba, aplikácia prejde na angličtinu.",
        "language_name_polish": "Poľština",
        "language_name_english": "Angličtina",
        "language_name_spanish": "Španielčina",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Medzislovančina",
        "language_script_latin": "Latinka",
        "language_script_cyrillic": "Cyrilika",
        "language_script_glagolitic": "Hlaholika",
    },
    "hr": {
        "language_picker_title": "Jezik",
        "language_phone": "Jezik telefona",
        "language_phone_detail": "Koristi jezik ovog uređaja. Ako prijevoda nema, aplikacija prelazi na engleski.",
        "language_name_polish": "Poljski",
        "language_name_english": "Engleski",
        "language_name_spanish": "Španjolski",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Međuslavenski",
        "language_script_latin": "Latinica",
        "language_script_cyrillic": "Ćirilica",
        "language_script_glagolitic": "Glagoljica",
    },
    "hu": {
        "language_picker_title": "Nyelv",
        "language_phone": "A telefon nyelve",
        "language_phone_detail": "Az eszköz nyelvét használja. Ha nincs fordítás, az alkalmazás angolra vált.",
        "language_name_polish": "Lengyel",
        "language_name_english": "Angol",
        "language_name_spanish": "Spanyol",
        "language_name_esperanto": "Eszperantó",
        "language_name_interslavic": "Interszláv",
        "language_script_latin": "Latin írás",
        "language_script_cyrillic": "Cirill írás",
        "language_script_glagolitic": "Glagolita írás",
    },
    "ro": {
        "language_picker_title": "Limbă",
        "language_phone": "Limba telefonului",
        "language_phone_detail": "Folosește limba acestui dispozitiv. Dacă nu există traducere, aplicația trece la engleză.",
        "language_name_polish": "Poloneză",
        "language_name_english": "Engleză",
        "language_name_spanish": "Spaniolă",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslavă",
        "language_script_latin": "Scriere latină",
        "language_script_cyrillic": "Scriere chirilică",
        "language_script_glagolitic": "Scriere glagolitică",
    },
    "ru": {
        "language_picker_title": "Язык",
        "language_phone": "Язык телефона",
        "language_phone_detail": "Использует язык этого устройства. Если перевода нет, приложение переходит на английский.",
        "language_name_polish": "Польский",
        "language_name_english": "Английский",
        "language_name_spanish": "Испанский",
        "language_name_esperanto": "Эсперанто",
        "language_name_interslavic": "Межславянский",
        "language_script_latin": "Латиница",
        "language_script_cyrillic": "Кириллица",
        "language_script_glagolitic": "Глаголица",
    },
    "uk": {
        "language_picker_title": "Мова",
        "language_phone": "Мова телефону",
        "language_phone_detail": "Використовує мову цього пристрою. Якщо перекладу немає, застосунок переходить на англійську.",
        "language_name_polish": "Польська",
        "language_name_english": "Англійська",
        "language_name_spanish": "Іспанська",
        "language_name_esperanto": "Есперанто",
        "language_name_interslavic": "Міжслов'янська",
        "language_script_latin": "Латиниця",
        "language_script_cyrillic": "Кирилиця",
        "language_script_glagolitic": "Глаголиця",
    },
    "el": {
        "language_picker_title": "Γλώσσα",
        "language_phone": "Γλώσσα τηλεφώνου",
        "language_phone_detail": "Χρησιμοποιεί τη γλώσσα αυτής της συσκευής. Αν δεν υπάρχει μετάφραση, η εφαρμογή περνά στα αγγλικά.",
        "language_name_polish": "Πολωνικά",
        "language_name_english": "Αγγλικά",
        "language_name_spanish": "Ισπανικά",
        "language_name_esperanto": "Εσπεράντο",
        "language_name_interslavic": "Διασλαβικά",
        "language_script_latin": "Λατινική γραφή",
        "language_script_cyrillic": "Κυριλλική γραφή",
        "language_script_glagolitic": "Γλαγολιτική γραφή",
    },
    "tr": {
        "language_picker_title": "Dil",
        "language_phone": "Telefon dili",
        "language_phone_detail": "Bu aygıtın dilini kullanır. Çeviri yoksa uygulama İngilizceye geçer.",
        "language_name_polish": "Lehçe",
        "language_name_english": "İngilizce",
        "language_name_spanish": "İspanyolca",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "İnterslavca",
        "language_script_latin": "Latin yazı",
        "language_script_cyrillic": "Kiril yazı",
        "language_script_glagolitic": "Glagol yazısı",
    },
    "ar": {
        "language_picker_title": "اللغة",
        "language_phone": "لغة الهاتف",
        "language_phone_detail": "تستخدم لغة هذا الجهاز. إذا لم توجد ترجمة، ينتقل التطبيق إلى الإنجليزية.",
        "language_name_polish": "البولندية",
        "language_name_english": "الإنجليزية",
        "language_name_spanish": "الإسبانية",
        "language_name_esperanto": "إسبرانتو",
        "language_name_interslavic": "السلافية المشتركة",
        "language_script_latin": "الكتابة اللاتينية",
        "language_script_cyrillic": "الكتابة السيريلية",
        "language_script_glagolitic": "الكتابة الغلاغوليتسية",
    },
    "he": {
        "language_picker_title": "שפה",
        "language_phone": "שפת הטלפון",
        "language_phone_detail": "משתמשת בשפת המכשיר. אם אין תרגום, היישומון עובר לאנגלית.",
        "language_name_polish": "פולנית",
        "language_name_english": "אנגלית",
        "language_name_spanish": "ספרדית",
        "language_name_esperanto": "אספרנטו",
        "language_name_interslavic": "אינטר-סלאבית",
        "language_script_latin": "כתב לטיני",
        "language_script_cyrillic": "כתב קירילי",
        "language_script_glagolitic": "כתב גלגוליטי",
    },
    "ja": {
        "language_picker_title": "言語",
        "language_phone": "端末の言語",
        "language_phone_detail": "この端末の言語を使います。翻訳がない場合は英語になります。",
        "language_name_polish": "ポーランド語",
        "language_name_english": "英語",
        "language_name_spanish": "スペイン語",
        "language_name_esperanto": "エスペラント",
        "language_name_interslavic": "インタースラヴィック",
        "language_script_latin": "ラテン文字",
        "language_script_cyrillic": "キリル文字",
        "language_script_glagolitic": "グラゴル文字",
    },
    "ko": {
        "language_picker_title": "언어",
        "language_phone": "휴대전화 언어",
        "language_phone_detail": "이 기기의 언어를 사용합니다. 번역이 없으면 영어로 바뀝니다.",
        "language_name_polish": "폴란드어",
        "language_name_english": "영어",
        "language_name_spanish": "스페인어",
        "language_name_esperanto": "에스페란토",
        "language_name_interslavic": "인터슬라브어",
        "language_script_latin": "로마자",
        "language_script_cyrillic": "키릴 문자",
        "language_script_glagolitic": "글라골 문자",
    },
    "zh-Hans": {
        "language_picker_title": "语言",
        "language_phone": "手机语言",
        "language_phone_detail": "使用这台设备的语言。如果没有译文，应用会改用英语。",
        "language_name_polish": "波兰语",
        "language_name_english": "英语",
        "language_name_spanish": "西班牙语",
        "language_name_esperanto": "世界语",
        "language_name_interslavic": "国际斯拉夫语",
        "language_script_latin": "拉丁字母",
        "language_script_cyrillic": "西里尔字母",
        "language_script_glagolitic": "格拉哥里字母",
    },
    "zh-Hant": {
        "language_picker_title": "語言",
        "language_phone": "手機語言",
        "language_phone_detail": "使用這台裝置的語言。如果沒有譯文，應用程式會改用英語。",
        "language_name_polish": "波蘭語",
        "language_name_english": "英語",
        "language_name_spanish": "西班牙語",
        "language_name_esperanto": "世界語",
        "language_name_interslavic": "國際斯拉夫語",
        "language_script_latin": "拉丁字母",
        "language_script_cyrillic": "西里爾字母",
        "language_script_glagolitic": "格拉哥里字母",
    },
    "vi": {
        "language_picker_title": "Ngôn ngữ",
        "language_phone": "Ngôn ngữ điện thoại",
        "language_phone_detail": "Dùng ngôn ngữ của thiết bị này. Nếu không có bản dịch, ứng dụng chuyển sang tiếng Anh.",
        "language_name_polish": "Tiếng Ba Lan",
        "language_name_english": "Tiếng Anh",
        "language_name_spanish": "Tiếng Tây Ban Nha",
        "language_name_esperanto": "Quốc tế ngữ",
        "language_name_interslavic": "Liên Slav",
        "language_script_latin": "Chữ Latinh",
        "language_script_cyrillic": "Chữ Kirin",
        "language_script_glagolitic": "Chữ Glagolitic",
    },
    "th": {
        "language_picker_title": "ภาษา",
        "language_phone": "ภาษาของโทรศัพท์",
        "language_phone_detail": "ใช้ภาษาของอุปกรณ์นี้ หากไม่มีคำแปล แอปจะใช้ภาษาอังกฤษ",
        "language_name_polish": "โปแลนด์",
        "language_name_english": "อังกฤษ",
        "language_name_spanish": "สเปน",
        "language_name_esperanto": "เอสเปรันโต",
        "language_name_interslavic": "อินเตอร์สลาวิก",
        "language_script_latin": "อักษรละติน",
        "language_script_cyrillic": "อักษรซีริลลิก",
        "language_script_glagolitic": "อักษรกลาโกลิติก",
    },
    "id": {
        "language_picker_title": "Bahasa",
        "language_phone": "Bahasa ponsel",
        "language_phone_detail": "Memakai bahasa perangkat ini. Jika terjemahan tidak ada, aplikasi memakai bahasa Inggris.",
        "language_name_polish": "Polski",
        "language_name_english": "Inggris",
        "language_name_spanish": "Spanyol",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslavik",
        "language_script_latin": "Aksara Latin",
        "language_script_cyrillic": "Aksara Kiril",
        "language_script_glagolitic": "Aksara Glagolitik",
    },
    "ms": {
        "language_picker_title": "Bahasa",
        "language_phone": "Bahasa telefon",
        "language_phone_detail": "Menggunakan bahasa peranti ini. Jika tiada terjemahan, aplikasi menggunakan bahasa Inggeris.",
        "language_name_polish": "Poland",
        "language_name_english": "Inggeris",
        "language_name_spanish": "Sepanyol",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Interslavik",
        "language_script_latin": "Tulisan Latin",
        "language_script_cyrillic": "Tulisan Siril",
        "language_script_glagolitic": "Tulisan Glagolitik",
    },
    "hi": {
        "language_picker_title": "भाषा",
        "language_phone": "फ़ोन की भाषा",
        "language_phone_detail": "इस डिवाइस की भाषा का उपयोग करता है। अनुवाद न होने पर ऐप अंग्रेज़ी पर चला जाता है।",
        "language_name_polish": "पोलिश",
        "language_name_english": "अंग्रेज़ी",
        "language_name_spanish": "स्पेनिश",
        "language_name_esperanto": "एस्पेरांतो",
        "language_name_interslavic": "इंटरस्लाविक",
        "language_script_latin": "लैटिन लिपि",
        "language_script_cyrillic": "सिरिलिक लिपि",
        "language_script_glagolitic": "ग्लैगोलिटिक लिपि",
    },
    "ca": {
        "language_picker_title": "Llengua",
        "language_phone": "Llengua del telèfon",
        "language_phone_detail": "Fa servir la llengua d'aquest dispositiu. Si no hi ha traducció, l'aplicació passa a l'anglès.",
        "language_name_polish": "Polonès",
        "language_name_english": "Anglès",
        "language_name_spanish": "Espanyol",
        "language_name_esperanto": "Esperanto",
        "language_name_interslavic": "Intereslau",
        "language_script_latin": "Escriptura llatina",
        "language_script_cyrillic": "Escriptura ciríl·lica",
        "language_script_glagolitic": "Escriptura glagolítica",
    },
}

ALIASES = {
    "en-AU": "en",
    "en-CA": "en",
    "en-GB": "en",
    "en-IN": "en",
    "es-419": "es",
    "fr-CA": "fr",
    "pt-BR": "pt",
    "pt-PT": "pt",
}


def unescape(value: str) -> str:
    output = []
    index = 0
    while index < len(value):
        if value[index] == "\\" and index + 1 < len(value):
            nxt = value[index + 1]
            output.append({"n": "\n", "t": "\t", "\\": "\\", '"': '"'}.get(nxt, nxt))
            index += 2
        else:
            output.append(value[index])
            index += 1
    return "".join(output)


def escape(value: str) -> str:
    value = value.replace("\\n", "\n").replace("\\t", "\t")
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")


def parse(text: str) -> dict[str, str]:
    found = {}
    for match in KEY.finditer(text):
        found[match.group("key")] = unescape(match.group("val"))
    return found


def rewrite(text: str, updates: dict[str, str]) -> str:
    lines = []
    for line in text.splitlines(keepends=True):
        stripped = line.rstrip("\n")
        newline = "\n" if line.endswith("\n") else ""
        match = LINE.match(stripped)
        if not match:
            lines.append(line)
            continue
        key = unescape(match.group(1)[1:-1])
        if key not in updates:
            lines.append(line)
            continue
        lines.append(f'"{key}" = "{escape(updates[key])}";{newline}')
    return "".join(lines)


def append_missing(path: Path, strings: dict[str, str]) -> int:
    text = path.read_text(encoding="utf-8")
    existing = parse(text)
    missing = {key: value for key, value in strings.items() if key not in existing}
    if not missing:
        return 0
    block = "\n/* T4S-041 language picker */\n"
    for key, value in missing.items():
        block += f'"{key}" = "{escape(value)}";\n'
    if not text.endswith("\n"):
        text += "\n"
    path.write_text(text + block, encoding="utf-8")
    return len(missing)


def main() -> int:
    en_path = ROOT / "en.lproj/Localizable.strings"
    en_text = en_path.read_text(encoding="utf-8")
    en = parse(en_text)
    missing = [key for key in en if key not in T]
    extra = [key for key in T if key not in en]
    if missing or extra:
        print("missing", missing)
        print("extra", extra)
        return 1

    same_eo = []
    for key, english in en.items():
        eo, isv, _es = T[key]
        kept_names = {
            "ab_app_name", "theory_20_author", "skill_emoji_section_fitness",
            "cat_fitness", "theory_link_pubmed",
        }
        if key not in kept_names and eo.strip() == english.strip() and re.search(r"[A-Za-z]{5,}", english):
            same_eo.append(key)
    if same_eo:
        print("esperanto still identical to english:", same_eo)
        return 1

    def render(index: int) -> str:
        updates = {key: T[key][index] for key in en}
        return rewrite(en_text, updates)

    (ROOT / "eo.lproj").mkdir(exist_ok=True)
    (ROOT / "isv.lproj").mkdir(exist_ok=True)
    (ROOT / "eo.lproj/Localizable.strings").write_text("// Esperanto\n" + render(0), encoding="utf-8")
    (ROOT / "isv.lproj/Localizable.strings").write_text("// Medžuslovjansky (Latin)\n" + render(1), encoding="utf-8")

    es_path = ROOT / "es.lproj/Localizable.strings"
    es = parse(es_path.read_text(encoding="utf-8"))
    es_updates = {}
    for key, english in en.items():
        _eo, _isv, spanish = T[key]
        if spanish and es.get(key) == english:
            es_updates[key] = spanish
    es_path.write_text(rewrite(es_path.read_text(encoding="utf-8"), es_updates), encoding="utf-8")

    added = 0
    for folder in sorted(ROOT.glob("*.lproj")):
        code = folder.name.removesuffix(".lproj")
        source = PICKER.get(code) or PICKER.get(ALIASES.get(code, ""), PICKER["en"])
        added += append_missing(folder / "Localizable.strings", source)

    print(f"keys {len(en)} eo {len(en)} isv {len(en)} es_updated {len(es_updates)} picker_lines {added}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
