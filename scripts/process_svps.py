import json
import os
import re
from typing import List, TypedDict
import pandas as pd
from decouple import config
from openai import OpenAI
from openai.types.beta.threads.text_content_block import TextContentBlock
from pydantic import BaseModel

DF_FILEPATH = "data/svps.feather"
DF_UCIVO = "data/svps_ucivo.feather"
SVP_FOLDER_PATH = "data/SVPs"

FILES_RANGE_FROM = 1
FILES_RANGE_TO = 10

OPENAI_API_KEY = config("OPENAI_API_KEY")
OPENAI_ASSISTANT_ID = "asst_Qnt4eURvQ00XJcTQls5ixsk9"

PROMPT_EXTRACT_UCIVO = """
Z dokumentu mi vyextrahuj učivo dějepisu a vrať ho ve formátu JSON se strukturou:

Ročník, Tematický celek, Učivo

Dějepis se učí pouze v ročnících 6-9.

Každý bod učiva uveď na samostatném řádku. Buď důsledný, snaz se najít opravdu veškere učivo
předmětu dějepis.

Výstup by měl vypadat následovně:

[
    {
        "Ročník": 6,
        "Tematický celek": "Člověk v dějinách",
        "Učivo": "Význam zkoumání dějin"
    },
    {
        "Ročník": 6,
        "Tematický celek": "Člověk v dějinách",
        "Učivo": "Historické prameny"
    },
    {
        "Ročník": 7,
        "Tematický celek": "Počátky lidské společnosti",
        "Učivo": "Pravěk - lovci a sběrači"
    },
    {
        "Ročník": 7,
        "Tematický celek": "Křesťanství a středověká Evropa",
        "Učivo": "Nový etnický obraz Evropy"
    }
]

Vrať pouze JSON soubor, nic jiného. Pokud nenajdeš žádné učivo, vrať prázdný JSON soubor.

"""


openai = OpenAI(api_key=OPENAI_API_KEY)


def main():
    files = load_dataframe(DF_FILEPATH, ["file_name", "openai_file_id"])
    ucivo = load_dataframe(
        DF_UCIVO,
        ["file_name", "openai_file_id", "rocnik", "tematicky_celek", "ucivo"],
    )

    files = load_all_svps(files)
    ucivo = extract_ucivo_from_svps(files, ucivo)


def load_dataframe(path: str, columns: List[str]) -> pd.DataFrame:
    if os.path.exists(path):
        return pd.read_feather(path)
    else:
        return pd.DataFrame({column: [] for column in columns}).set_index(columns[0])


def load_all_svps(df: pd.DataFrame) -> pd.DataFrame:
    for file_name in os.listdir(SVP_FOLDER_PATH)[FILES_RANGE_FROM:FILES_RANGE_TO]:
        print(df.index)
        if not file_name in df.index:
            print(f"File {file_name} not found in df")
            df = pd.concat([df, upload_file_to_openai(file_name)])
        else:
            print(f"File {file_name} found in df")

        print(df.head())
        df.to_feather(DF_FILEPATH)
    return df


def upload_file_to_openai(file_name: str) -> pd.DataFrame:
    with open(f"{SVP_FOLDER_PATH}/{file_name}", "rb") as file:
        response = openai.files.create(purpose="assistants", file=file)

    return pd.DataFrame(
        {
            "file_name": [file_name],
            "openai_file_id": [response.id],
        }
    ).set_index("file_name")


def extract_ucivo_from_svps(files: pd.DataFrame, ucivo: pd.DataFrame) -> pd.DataFrame:
    for file_name, row in files.iterrows():
        if not file_name in ucivo.index:
            ucivo = pd.concat(
                [ucivo, extract_ucivo_from_svp(file_name, row["openai_file_id"])]
            )
        else:
            print(f"File {file_name} found in ucivo")

        print(ucivo.head())
        ucivo.to_feather(DF_UCIVO)

    return ucivo


def extract_ucivo_from_svp(file_name, file_id) -> pd.DataFrame:
    thread = openai.beta.threads.create()
    message = openai.beta.threads.messages.create(
        thread_id=str(thread.id),
        role="user",
        content=PROMPT_EXTRACT_UCIVO,
        attachments=[{"file_id": file_id, "tools": [{"type": "file_search"}]}],
    )

    run = openai.beta.threads.runs.create_and_poll(
        thread_id=thread.id, assistant_id=OPENAI_ASSISTANT_ID
    )

    if run.status == "completed":
        response = ""
        all_messages = openai.beta.threads.messages.list(
            thread_id=thread.id, before=message.id
        )
        for message in all_messages:
            if (
                message.role == "assistant"
                and message.content
                and isinstance(message.content[0], TextContentBlock)
            ):
                response += message.content[0].text.value

        cleaned_text = re.sub(r"^```json\s*|\s*```$", "", response, flags=re.DOTALL)
        data = json.loads(cleaned_text)

        if data:
            return pd.DataFrame(
                {
                    "file_name": file_name,
                    "rocnik": data["Ročník"],
                    "tematicky_celek": data["Tématický celek"],
                    "ucivo": data["Učivo"],
                }
            ).set_index("file_name")
    else:
        print(f"Nepovedlo se extrahovat učivo ze souboru {file_name}")


if __name__ == "__main__":
    main()
