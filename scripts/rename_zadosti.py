import os
import re
from PyPDF2 import PdfReader

def rename_pdfs_in_folder(folder_path):
    # List all PDF files in the specified folder
    for filename in os.listdir(folder_path):
        if filename.endswith('.pdf'):
            file_path = os.path.join(folder_path, filename)
            try:
                # Read the PDF file
                with open(file_path, 'rb') as file:
                    reader = PdfReader(file)
                    text = ''
                    for page in reader.pages:
                        text += page.extract_text() or ''
                
                # Search for the string pattern
                match = re.search(r'IČO: ([0-9]+)', text)
                if match:
                    # Get the matched IČO number
                    ico_number = match.group(1)
                    # Create a new filename
                    new_filename = f'{ico_number}.pdf'
                    new_file_path = os.path.join(folder_path, new_filename)

                    # Rename the file
                    os.rename(file_path, new_file_path)
                    print(f'Renamed: {filename} to {new_filename}')
                else:
                    print(f'No IČO found in: {filename}')

            except Exception as e:
                print(f'Error processing {filename}: {e}')

# Specify your folder path
rename_pdfs_in_folder('../outcomes/zadosti/')

