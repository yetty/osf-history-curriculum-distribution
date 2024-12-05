import base64
import os
from typing import Any, List
from decouple import config
from openai import OpenAI
from openai.types.chat import (
    ChatCompletionUserMessageParam,
    ChatCompletionContentPartImageParam,
)
from pydantic import BaseModel
from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.core.credentials import AzureKeyCredential

BASE_IMG_PATH = "./data/svp-as-image"
OPENAI_API_KEY = config("OPENAI_API_KEY")
openai = OpenAI(api_key=OPENAI_API_KEY)

docint = DocumentIntelligenceClient(
    endpoint=config("AZURE_DOC_ENDPOINT"),
    credential=AzureKeyCredential(config("AZURE_DOC_KEY")),
)


class Ucivo(BaseModel):
    rocnik: int
    ucivo: List[str]


class SVP(BaseModel):
    ucivo_list: List[Ucivo]


def extract_ucivo_from_images(path: str):
    images: List[ChatCompletionContentPartImageParam] = []
    for image in sorted(os.listdir(path)):
        if not image.endswith(".png"):
            continue

        image_path = f"{path}/{image}"
        with open(image_path, "rb") as image_file:
            base64_string = base64.b64encode(image_file.read()).decode("utf-8")
        images.append(
            ChatCompletionContentPartImageParam(
                type="image_url",
                image_url={"url": f"data:image/jpeg;base64,{base64_string}"},
            )
        )

    images_prompt = ChatCompletionUserMessageParam(
        role="user",
        content=images,
    )

    completion = openai.beta.chat.completions.parse(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": "Z nahraných obrázků vyextrahuj učivo předmětu dějepis a ročník, do kterých je zařazené. Učivo je obvykle v tabulce v samostatném sloupci nazvaném `Učivo`. Tabulka můze být rozdělena na víc obrázků, které jsou seřazeny po sobě. Pokud je v řádku více položek, rozděl je. Nezaměňuj učivo s 'výstupy' nebo 'cíli'.",
            },
            images_prompt,
        ],
        store=True,
        response_format=SVP,
    )
    items = completion.choices[0].message.parsed
    return items.ucivo_list if items else []


def convert_to_matrix(objects: List[Any], default_value: Any = None):
    # Find maximum row and column indices
    max_row = max(obj.row_index for obj in objects)
    max_col = max(obj.column_index for obj in objects)

    # Initialize the matrix with the default value
    matrix = [[default_value for _ in range(max_row + 1)] for _ in range(max_col + 1)]

    # Fill the matrix with the values
    for obj in objects:
        row, col, value = obj.row_index, obj.column_index, obj.content
        matrix[col][row] = value

    return matrix


def extract_ucivo_from_images_docint(path: str):
    pdf_path = f"{path}/svp.pdf"
    with open(pdf_path, "rb") as pdf_file:
        poller = docint.begin_analyze_document(
            "prebuilt-layout", pdf_file, content_type="application/octet-stream"
        )

    result = poller.result()

    if result.tables:
        for table in result.tables:
            matrix = convert_to_matrix(table.cells)

            for column in matrix:
                print(column)


def main():
    for svp in os.listdir(BASE_IMG_PATH)[:2]:
        path = f"{BASE_IMG_PATH}/{svp}"
        if not os.path.isdir(path):
            continue

        print(path)
        ucivo = extract_ucivo_from_images_docint(path)
        print(ucivo)


if __name__ == "__main__":
    main()
