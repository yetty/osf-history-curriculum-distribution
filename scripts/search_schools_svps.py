import openai
import requests
import fitz  # PyMuPDF
import pandas as pd
import os

# Set your OpenAI API key
openai.api_key = 'your_openai_api_key'

SCHOOLS_LIST_FILE_PATH = '../outcomes/sampled_schools.csv'
DOWNLOAD_FOLDER_PATH = '../data/SVPs'

# Ensure the download folder exists
os.makedirs(DOWNLOAD_FOLDER_PATH, exist_ok=True)


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
    schools_df['status'] = ''  # Add a new column for status

    for index, row in schools_df.iterrows():
        school_name = row['zar_nazev']
        address = f"{row['ulice']}, {row['misto']}"
        izo_code = str(row['izo'])  # Ensure IZO code is a string

        try:
            svp_url = search_svps(school_name, address)

            if svp_url:
                filename = f"{DOWNLOAD_FOLDER_PATH}/{izo_code}.pdf"
                download_file(svp_url, filename)

                if check_izo_in_pdf(filename, izo_code):
                    print(f"Correct ŠVP found for {school_name}. Downloaded file: {filename}")
                    schools_df.at[index, 'status'] = 'downloaded'
                else:
                    print(f"ŠVP found for {school_name} does not contain the correct IZO code.")
                    schools_df.at[index, 'status'] = 'invalid izo'
                    os.remove(filename)
            else:
                print(f"No ŠVP URL found for {school_name}.")
                schools_df.at[index, 'status'] = 'not found'
        except Exception as e:
            print(f"Error processing {school_name}: {e}")
            schools_df.at[index, 'status'] = 'error'

    # Save the updated DataFrame back to the CSV file
    schools_df.to_csv(csv_file, index=False)


if __name__ == "__main__":
    main(SCHOOLS_LIST_FILE_PATH)
