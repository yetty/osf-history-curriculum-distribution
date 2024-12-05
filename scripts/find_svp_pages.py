import os
import fitz  # PyMuPDF

# Define the path to the folder containing the PDF files
folder_path = "./data/SVPs"

# Initialize an empty list to store the PDF information
pdf_list = []

# Define search text markers as lists of separate lines
start_marker = ["dějepis", "6", "ročník", "učivo"]
end_marker = ["výchova k občanství"]

# Loop through each file in the folder
for filename in sorted(os.listdir(folder_path)):
    # Check if the file has a .pdf extension
    if filename.endswith(".pdf"):
        try:
            # Create a dictionary for each PDF file with initial None values for page_start and page_end
            pdf_info = {"filename": filename, "page_start": None, "page_end": None}

            # Open the PDF file
            file_path = os.path.join(folder_path, filename)
            doc = fitz.open(file_path)
            pages = doc.page_count

            if pages > 50:
                start = 50
            else:
                start = 0

            # Iterate through each page in the PDF
            for page_num in range(start, doc.page_count):
                page = doc[page_num]
                text = page.get_text()

                # Check for start marker
                if (
                    all(part in text.lower() for part in start_marker)
                    and pdf_info["page_start"] is None
                ):
                    pdf_info["page_start"] = page_num

                # Check for end marker
                if (
                    pdf_info["page_start"] is not None
                    and all(part in text.lower() for part in end_marker)
                    and pdf_info["page_end"] is None
                ):
                    pdf_info["page_end"] = page_num

                # If both start and end markers are found, no need to continue scanning this file
                if (
                    pdf_info["page_start"] is not None
                    and pdf_info["page_end"] is not None
                ):
                    break

            # Close the PDF file
            doc.close()

            # Append the dictionary to the pdf_list
            pdf_list.append(pdf_info)

            # Write the list to a Python file as code
            with open("scripts/pdf_list.py", "a") as f:
                # Start the list declaration
                # f.write("pdf_list = [\n")

                # Write each dictionary in the list
                f.write("    {\n")
                f.write(f"        'filename': '{pdf_info['filename']}',\n")
                f.write(f"        'page_start': {pdf_info['page_start']},\n")
                f.write(f"        'page_end': {pdf_info['page_end']}\n")
                f.write("    },\n")

                # End the list
                # f.write("]\n")
        except Exception as e:
            print(f"Error processing file: {filename} - {e}")

print("PDF list with page markers has been saved as 'pdf_list.py'")
