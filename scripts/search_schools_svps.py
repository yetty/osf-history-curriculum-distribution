import openai
import requests
import fitz  # PyMuPDF
import pandas as pd
import os

# Set your OpenAI API key
openai.api_key = 'your_openai_api_key'

SCHOOLS_LIST_FILE_PATH = '../data/schools.csv'
DOWNLOAD_FOLDER_PATH = '../data/SVPs'


def search_svps(school_name, address):
    response = openai.Completion.create(
        engine="davinci",
        prompt=f"Find the 'ŠVP' document for the school '{school_name}' located at '{address}'. "
               f"Provide the URL of the PDF file only if available.",
        max_tokens=100,
        n=1,
        stop=None,
        temperature=0,
    )
    return response.choices[0].text.strip()


def download_file(url, filename):
    response = requests.get(url)
    with open(filename, 'wb') as file:
        file.write(response.content)


def check_izo_in_pdf(filename, izo_code):
    with fitz.open(filename) as pdf_document:
        for page_num in range(min(5, len(pdf_document))):
            page = pdf_document.load_page(page_num)
            text = page.get_text()
            if izo_code in text:
                return True
    return False


def main(csv_file):
    schools_df = pd.read_csv(csv_file)

    for index, row in schools_df.iterrows():
        school_name = row['school_name']
        address = row['address']
        izo_code = row['izo_code']

        svp_url = search_svps(school_name, address)

        if svp_url:
            filename = f"{DOWNLOAD_FOLDER_PATH}/{izo_code}.pdf"
            download_file(svp_url, filename)

            if check_izo_in_pdf(filename, izo_code):
                print(f"Correct ŠVP found for {school_name}. Downloaded file: {filename}")
            else:
                print(f"ŠVP found for {school_name} does not contain the correct IZO code.")
                os.remove(filename)


if __name__ == "__main__":
    main(SCHOOLS_LIST_FILE_PATH)
