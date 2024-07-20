import requests
import pandas as pd
import os
from urllib.parse import urlparse
from dotenv import load_dotenv

load_dotenv()

BING_API_KEY = os.environ['BING_SEARCH_V7_SUBSCRIPTION_KEY']
BING_ENDPOINT = "https://api.bing.microsoft.com/v7.0/search"


def find_school_website(school_name, school_street, school_town):
    query = f"{school_name} {school_street} {school_town} site:.cz"
    headers = {"Ocp-Apim-Subscription-Key": BING_API_KEY}
    params = {"q": query, "textDecorations": True, "textFormat": "HTML"}

    response = requests.get(BING_ENDPOINT, headers=headers, params=params)
    response.raise_for_status()
    search_results = response.json()

    if 'webPages' in search_results:
        for result in search_results['webPages']['value']:
            url = result['url']
            domain = urlparse(url).netloc
            return domain
    return None


def process_school(row):
    if pd.notna(row['website']):
        print(f"Skipping school (already has website): {row['zar_naz']} (IZO: {row['izo']})")
        return row['website']

    print(f"Processing school: {row['zar_naz']} (IZO: {row['izo']})")
    try:
        website = find_school_website(row['zar_naz'], row['ulice'], row['misto'])
        print(f"Found website: {website}" if website else "Website not found")
        return website
    except Exception as e:
        print(f"Error processing school: {row['zar_naz']} (IZO: {row['izo']}) - {e}")
        return None


# Load the CSV file
schools = pd.read_csv('../outcomes/sampled_schools.csv')

# Ensure 'website' column exists
if 'website' not in schools.columns:
    schools['website'] = None

# Limit the number of rows processed
limit = 400
schools_limited = schools.head(limit)

# Apply processing to rows without websites
schools_limited['website'] = schools_limited.apply(process_school, axis=1)

# Update the original dataframe with new websites
schools.set_index('izo', inplace=True)
schools_limited.set_index('izo', inplace=True)

# Update only the 'website' column with new values
schools.update(schools_limited[['website']])

# Reset index to default
schools.reset_index(inplace=True)

# Save the results to the same CSV file
schools.to_csv('../outcomes/sampled_schools.csv', index=False)

print("Script completed.")