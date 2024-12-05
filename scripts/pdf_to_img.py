import os
import fitz
from pdf_list import pdf_list

BASE_PDF_PATH = "data/SVPs"
BASE_IMG_PATH = "data/svp-as-image"

zoom = 2  # Set the zoom level to increase DPI
mat = fitz.Matrix(zoom, zoom)


def pdf_to_img(pdf_name: str, start: int, end: str):
    pdf_path = f"{BASE_PDF_PATH}/{pdf_name}"
    img_path = f"{BASE_IMG_PATH}/{pdf_name}"

    os.makedirs(img_path, exist_ok=True)

    pages = []
    pdf = fitz.open(pdf_path)
    for page_number in range(start, end):
        page = pdf[page_number]
        pages.append(page)
        image = page.get_pixmap(matrix=mat)
        image.save(f"{img_path}/{page_number}.png")

    if pages:
        new_pdf = fitz.open()  # Create a new PDF object
        for page_number in range(start, end):
            new_pdf.insert_pdf(pdf, from_page=page_number, to_page=page_number)
        new_pdf.save(f"{img_path}/svp.pdf")  # Save the new PDF
        new_pdf.close()

    pdf.close()


def main():
    for pdf in pdf_list[:10]:
        print(pdf)
        if pdf["page_start"] and pdf["page_end"]:
            pdf_to_img(pdf["filename"], pdf["page_start"], pdf["page_end"])


if __name__ == "__main__":
    main()
