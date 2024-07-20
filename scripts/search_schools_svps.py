import requests
import pandas as pd
import os
from urllib.parse import urlparse
from dotenv import load_dotenv

load_dotenv()

BING_API_KEY = os.environ['BING_SEARCH_V7_SUBSCRIPTION_KEY']
BING_ENDPOINT = "https://api.bing.microsoft.com/v7.0/search"


def find_svp_pdf(row):
    query = f"site:{row['website']} \"školní vzdělávací program\" \"základní vzdělávání\" \"Učební osnovy\" \"Učební plán\" filetype:pdf"
    headers = {"Ocp-Apim-Subscription-Key": BING_API_KEY}
    params = {"q": query, "textDecorations": True, "textFormat": "HTML"}

    response = requests.get(BING_ENDPOINT, headers=headers, params=params)
    response.raise_for_status()
    search_results = response.json()

    if 'webPages' in search_results:
        for result in search_results['webPages']['value']:
            url = result['url']
            if url.endswith('.pdf'):
                return url

    query = f"{row['izo']} \"{row['zar_nazev']}\" \"{row['ulice']}\" \"{row['misto']}\" \"školní vzdělávací program\" \"základní vzdělávání\" \"Učební osnovy\" \"Učební plán\" filetype:pdf"
    params = {"q": query, "textDecorations": True, "textFormat": "HTML"}

    response = requests.get(BING_ENDPOINT, headers=headers, params=params)
    response.raise_for_status()
    search_results = response.json()

    if 'webPages' in search_results:
        for result in search_results['webPages']['value']:
            url = result['url']
            if url.endswith('.pdf'):
                return url
    return None


def process_school(row):
    if not pd.notna(row['svp_bing_found']) or row['svp_bing_found'] is False:
        print(f"Processing school: {row['zar_nazev']} (IZO: {row['izo']})")
        try:
            svp_pdf = find_svp_pdf(row)
            print(f"Found SVP PDF: {svp_pdf}" if svp_pdf else "SVP PDF not found")
            return svp_pdf
        except Exception as e:
            print(f"Error processing school: {row['zar_nazev']} (IZO: {row['izo']}) - {e}")
            return None
    else:
        print(f"Skipping: {row['zar_nazev']} (IZO: {row['izo']})")
        return None


# Load the CSV file
schools = pd.read_csv('../outcomes/sampled_schools.csv')

# Ensure 'svp_pdf' column exists
if 'svp_pdf' not in schools.columns:
    schools['svp_pdf'] = None
if 'svp_bing_found' not in schools.columns:
    schools['svp_bing_found'] = None

# Limit the number of rows processed
limit = 400
schools_limited = schools.head(limit)


# Process each school and save the CSV file after each 10 rows
for i, row in schools_limited.iterrows():
    svp_pdf = process_school(row)
    schools.at[i, 'svp_bing_found'] = svp_pdf is not None
    schools.at[i, 'svp_pdf'] = svp_pdf

    if (i + 1) % 10 == 0:
        print(f"Saving CSV file after processing {i + 1} rows")
        schools.to_csv('../outcomes/sampled_schools.csv', index=False)

# Save the final results
schools.to_csv('../outcomes/sampled_schools.csv', index=False)

print("Script completed.")