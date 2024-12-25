import csv
import re
from typing import List, Literal

from decouple import config
from openai import OpenAI
from pydantic import BaseModel

OPENAI_API_KEY = config("OPENAI_API_KEY")
openai = OpenAI(api_key=OPENAI_API_KEY)

UCIVO = {}

PROMPT = """
Uzivatel ti poskytne ucivo dejepisu zakladni skoly, ktere ma ale rozbite formatovani, chyby v prepisu atd.
Prepis ucivo tak, aby na kazdem radku byl jeden vyznamovy celek, ktery je soucasti uciva. Oddeluj vyznamove 
celky co nejvice (napr. z "křesťanství, papežství, císařství, křížové výpravy" udelej samostatne pojmy
"křesťanství", "papežství", "císařství" a "křížové výpravy").

Pokud se nektere pojmy opakuji, zarad je pouze jednou. Pokud ze samotneho pojmu neni jasne casove zarazeni, dopln mu chybejici
casove zarazeni na zaklade okolniho uciva. Predpokladej, ze ucivo je chronologicky razene. 
"""

PROMPT_ROCNIKY = {
    "6": """
Zarad ucivo do nasledujicich bloku a temat RVP:

- ČLOVĚK V DĚJINÁCH
  - význam zkoumání dějin, získávání informací o dějinách; historické prameny
  - historický čas a prostor
  - jiné
- POČÁTKY LIDSKÉ SPOLEČNOSTI
  - člověk a lidská společnost v pravěku
  - jiné
- NEJSTARŠÍ CIVILIZACE. KOŘENY EVROPSKÉ KULTURY
  - nejstarší starověké civilizace a jejich kulturní odkaz
  - antické Řecko a Řím
  - střední Evropa a její styky s antickým Středomořím
  - jiné
- KŘESŤANSTVÍ A STŘEDOVĚKÁ EVROPA
  - nový etnický obraz Evropy
  - utváření států ve východoevropském a západoevropském kulturním okruhu a jejich specifický vývoj
  - islám a islámské říše ovlivňující Evropu (Arabové, Turci)
  - Velká Morava a český stát, jejich vnitřní vývoj a postavení v Evropě
  - křesťanství, papežství, císařství, křížové výpravy
  - struktura středověké společnosti, funkce jednotlivých vrstev
  - kultura středověké společnosti - románské a gotické umění a vzdělanost
  - jiné
- JINÉ
  - jiné dějepisné téma
  - téma mimo dějepis
""",
    "7": """
Zarad ucivo do nasledujicich bloku a temat RVP:

- NEJSTARŠÍ CIVILIZACE. KOŘENY EVROPSKÉ KULTURY
  - nejstarší starověké civilizace a jejich kulturní odkaz
  - antické Řecko a Řím
  - střední Evropa a její styky s antickým Středomořím
  - jiné
- KŘESŤANSTVÍ A STŘEDOVĚKÁ EVROPA
  - nový etnický obraz Evropy
  - utváření států ve východoevropském a západoevropském kulturním okruhu a jejich specifický vývoj
  - islám a islámské říše ovlivňující Evropu (Arabové, Turci)
  - Velká Morava a český stát, jejich vnitřní vývoj a postavení v Evropě
  - křesťanství, papežství, císařství, křížové výpravy
  - struktura středověké společnosti, funkce jednotlivých vrstev
  - kultura středověké společnosti - románské a gotické umění a vzdělanost
  - jiné
- OBJEVY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY
  - renesance, humanismus, husitství, reformace a jejich šíření Evropou
  - zámořské objevy a počátky dobývání světa
  - český stát a velmoci v 15.-18. století
  - barokní kultura a osvícenství
  - jiné
- MODERNIZACE SPOLEČNOSTI
  - Velká francouzská revoluce a napoleonské období, jejich vliv na Evropu a svět; vznik USA
  - industrializace a její důsledky pro společnost; sociální otázka
  - národní hnutí velkých a malých národů; utváření novodobého českého národa
  - revoluce 19. století jako prostředek řešení politických, sociálních a národnostních problémů
  - politické proudy (konzervativismus, liberalismus, demokratismus, socialismus), ústava, politické
strany, občanská práva
  - kulturní rozrůzněnost doby
  - konflikty mezi velmocemi, kolonialismus
  - jiné
- JINÉ
  - jiné dějepisné téma
  - téma mimo dějepis
""",
    "8": """
Zarad ucivo do nasledujicich bloku a temat RVP:
- OBJEVY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY
  - renesance, humanismus, husitství, reformace a jejich šíření Evropou
  - zámořské objevy a počátky dobývání světa
  - český stát a velmoci v 15.-18. století
  - barokní kultura a osvícenství
  - jiné
- MODERNIZACE SPOLEČNOSTI
  - Velká francouzská revoluce a napoleonské období, jejich vliv na Evropu a svět; vznik USA
  - industrializace a její důsledky pro společnost; sociální otázka
  - národní hnutí velkých a malých národů; utváření novodobého českého národa
  - revoluce 19. století jako prostředek řešení politických, sociálních a národnostních problémů
  - politické proudy (konzervativismus, liberalismus, demokratismus, socialismus), ústava, politické
strany, občanská práva
  - kulturní rozrůzněnost doby
  - konflikty mezi velmocemi, kolonialismus
  - jiné
- MODERNÍ DOBA
  - první světová válka a její politické, sociální a kulturní důsledky
  - nové politické uspořádání Evropy a úloha USA ve světě; vznik Československa, jeho hospodářsko-
politický vývoj, sociální a národnostní problémy
  - mezinárodněpolitická a hospodářská situace ve 20. a 30. letech; totalitní systémy - komunismus,
fašismus, nacismus - důsledky pro Československo a svět
  - druhá světová válka, holokaust; situace v našich zemích, domácí a zahraniční odboj; politické,
mocenské a ekonomické důsledky války
  - jiné
- ROZDĚLENÝ A INTEGRUJÍCÍ SE SVĚT
  - studená válka, rozdělení světa do vojenských bloků reprezentovaných supervelmocemi; politické,
hospodářské, sociální a ideologické soupeření
  - vnitřní situace v zemích východního bloku (na vybraných příkladech srovnání s charakteristikou
západních zemí)
  - vývoj Československa od roku 1945 do roku 1989, vznik České republiky
  - rozpad koloniálního systému, mimoevropský svět
  - problémy současnosti
  - věda, technika a vzdělání jako faktory vývoje; sport a zábava
  - jiné
- JINÉ
  - jiné dějepisné téma
  - téma mimo dějepis
""",
    "9": """
Zarad ucivo do nasledujicich bloku a temat RVP:

- MODERNIZACE SPOLEČNOSTI
  - Velká francouzská revoluce a napoleonské období, jejich vliv na Evropu a svět; vznik USA
  - industrializace a její důsledky pro společnost; sociální otázka
  - národní hnutí velkých a malých národů; utváření novodobého českého národa
  - revoluce 19. století jako prostředek řešení politických, sociálních a národnostních problémů
  - politické proudy (konzervativismus, liberalismus, demokratismus, socialismus), ústava, politické
strany, občanská práva
  - kulturní rozrůzněnost doby
  - konflikty mezi velmocemi, kolonialismus
  - jiné
- MODERNÍ DOBA
  - první světová válka a její politické, sociální a kulturní důsledky
  - nové politické uspořádání Evropy a úloha USA ve světě; vznik Československa, jeho hospodářsko-
politický vývoj, sociální a národnostní problémy
  - mezinárodněpolitická a hospodářská situace ve 20. a 30. letech; totalitní systémy - komunismus,
fašismus, nacismus - důsledky pro Československo a svět
  - druhá světová válka, holokaust; situace v našich zemích, domácí a zahraniční odboj; politické,
mocenské a ekonomické důsledky války
  - jiné
- ROZDĚLENÝ A INTEGRUJÍCÍ SE SVĚT
  - studená válka, rozdělení světa do vojenských bloků reprezentovaných supervelmocemi; politické,
hospodářské, sociální a ideologické soupeření
  - vnitřní situace v zemích východního bloku (na vybraných příkladech srovnání s charakteristikou
západních zemí)
  - vývoj Československa od roku 1945 do roku 1989, vznik České republiky
  - rozpad koloniálního systému, mimoevropský svět
  - problémy současnosti
  - věda, technika a vzdělání jako faktory vývoje; sport a zábava
  - jiné
- JINÉ
  - jiné dějepisné téma
  - téma mimo dějepis
""",
}


class UcivoItem(BaseModel):
    ucivo: str
    blok_rvp: str | None = None
    tema_rvp: str | None = None


class Ucivo(BaseModel):
    ucivo: List[UcivoItem]


def process_grade(school, grade, ucivo, note=None):
    with open("data/ucivo.csv", mode="a", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)

        print(f"Processing {school} {grade} ({note})")

        if grade and ucivo:
            writer.writerow([school, grade, note, " - ".join(ucivo)])

        if not ucivo:
            return

        ucivo_parts = [ucivo[i : i + 20] for i in range(0, len(ucivo), 20)]

        print(
            f"Items: {len(ucivo)} / length: {len(' '.join(ucivo))} / parts: {len(ucivo_parts)}"
        )

        for j, part in enumerate(ucivo_parts):
            print(f"Processing part {j+1}/{len(ucivo_parts)}")

            completion = openai.beta.chat.completions.parse(
                model="gpt-4o-mini-2024-07-18",
                messages=[
                    {
                        "role": "system",
                        "content": PROMPT,
                    },
                    {
                        "role": "system",
                        "content": PROMPT_ROCNIKY.get(
                            grade,
                            "`blok_rvp` a `tema_rvp` nejsou definovány pro tento ročník, nech je prazdne",
                        ),
                    },
                    {
                        "role": "user",
                        "content": "\n".join(part),
                    },
                ],
                response_format=Ucivo,
                temperature=0.01,
            )

            items = completion.choices[0].message.parsed
            print(f"Items: {len(items.ucivo)}")

            for item in items.ucivo:
                writer.writerow(
                    [school, grade, note, item.ucivo, item.blok_rvp, item.tema_rvp]
                )


with open("data/ucivo.txt", "r") as file:
    lines = file.read().splitlines()
    school = None
    grade = None
    note = None
    tmp_ucivo = []

    start_line = 0

    for i, line in enumerate(lines[start_line:]):
        l = line.strip()

        if l == "":
            continue
        elif re.match(r"^\d{7,10}$", l):
            if school:
                process_grade(school, grade, tmp_ucivo, note)
            tmp_ucivo = []
            grade = None
            note = None
            school = l
            UCIVO[l] = []
            print(f"Detected school: {school} (row {i+start_line})")
        elif re.match(r"^\!", l):
            note = l[1:]
            print(f"Detected note {school}: {note}")
        elif re.match(r"^\d(\-\d)?$", l):
            if grade:
                process_grade(school, grade, tmp_ucivo, note)
            tmp_ucivo = []
            grade = l
        else:
            tmp_ucivo.append(l)

    process_grade(school, grade, tmp_ucivo, note)
