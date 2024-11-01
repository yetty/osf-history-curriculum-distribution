import os
from typing import List, TypedDict
import pandas as pd
from decouple import config
from openai import OpenAI
from pydantic import BaseModel

DF_FILEPATH = "data/svps.feather"
SVP_FOLDER_PATH = "data/SVPs"

FILES_RANGE_FROM = 1
FILES_RANGE_TO = 10

OPENAI_API_KEY = config("OPENAI_API_KEY")

openai = OpenAI(OPENAI_API_KEY)


def main():
    if not os.path.exists(DF_FILEPATH):
        df = pd.DataFrame(
            {"file_name": [], "rocnik": [], "tematicky_celek": [], "ucivo": []}
        )
    else:
        df = pd.read_feather(DF_FILEPATH)

    load_all_svps(df)


def load_all_svps(df: pd.DataFrame):
    for file_name in os.listdir(SVP_FOLDER_PATH)[FILES_RANGE_FROM:FILES_RANGE_TO]:
        row = df.loc[df["file_name"] == file_name]

        if row.empty:
            print(f"File {file_name} not found in df")
            df = pd.concat([df, extract_ucivo_from_svp(file_name)], ignore_index=True)
        else:
            print(f"File {file_name} found in df")

        print(df.head())
        df.to_feather(DF_FILEPATH)


def extract_ucivo_from_svp(file_name: str) -> pd.DataFrame:
    return pd.DataFrame(
        {
            "file_name": file_name,
            "rocnik": 5,
            "tematicky_celek": "blabla",
            "ucivo": ["blablabl", "bolrthe"],
        }
    )


if __name__ == "__main__":
    main()
