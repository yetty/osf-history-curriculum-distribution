from decouple import config
from openai import OpenAI
import csv

OPENAI_API_KEY = config("OPENAI_API_KEY")
openai = OpenAI(api_key=OPENAI_API_KEY)

cache = {}


def create_embedding(text):
    lower_text = text.lower()

    if lower_text in cache:
        return cache[lower_text]

    response = openai.embeddings.create(
        model="text-embedding-3-large",
        input=lower_text,
        encoding_format="float",
    )
    embedding = response.data[0].embedding
    cache[lower_text] = embedding
    return embedding


with open("data/ucivo.embeddings.csv", mode="a") as output:
    csv_writer = csv.writer(output)
    csv_writer.writerow(["izo", "rocnik", "poznamka", "ucivo", "ucivo_vector"])

    start_row = 2

    with open("data/ucivo.gpt-4o-2024-08-06.csv", mode="r") as input:
        csv_reader = csv.reader(input)
        for row in csv_reader:
            if csv_reader.line_num < start_row or not row[3]:
                continue
            print(f"Processing row {csv_reader.line_num}: {row[3]}")
            embedding = create_embedding(row[3])
            csv_writer.writerow(row[0:4] + [embedding])
