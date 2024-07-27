# Load required libraries
library(readxl)
library(httr)
library(pdftools)
library(dplyr)
library(openxlsx)

# 1. Load data and normalize column 'svp'
data <- read_excel("outcomes/sampled_schools.xlsx")

# Ensure the izo column is a character and normalize to 9 digits with leading zeros
data$izo <- sprintf("%09s", as.character(data$izo))

# Initialize new columns
data$svp_filename <- NA
data$download_error <- NA

# Create a directory for downloaded files
if(!dir.exists("tmp_downloads")) dir.create("tmp_downloads")

# 2. Download all files from column 'svp_pdf'
for (i in 1:nrow(data)) {
  url <- data$svp_pdf[i]
  filename <- paste0(data$izo[i], ".pdf")
  filepath <- file.path("tmp_downloads", filename)
  final_filepath <- paste0("data/SVPs/", filename)
  
  # Attempt to download the file
  tryCatch({
    # Download the file
    response <- GET(url)
    
    # Check if download was successful
    if (status_code(response) == 200) {
      # Save the file
      temp_file <- tempfile(fileext = tools::file_ext(url))
      writeBin(content(response, "raw"), temp_file)
      
      # 3. If the file is in other format than PDF, then convert it into PDF
      if (tools::file_ext(url) != "pdf") {
        # Convert to PDF
        converted_pdf <- tempfile(fileext = ".pdf")
        pdf_convert(temp_file, output = converted_pdf)
        file.copy(converted_pdf, filepath)
      } else {
        file.copy(temp_file, filepath)
      }
      
      # 4. Save the file to 'data/SVPs'
      file.copy(filepath, final_filepath)
      
      # 5. Use value in column 'izo' + suffix '.pdf' as a filename
      data$svp_filename[i] <- filename
      
    } else {
      data$download_error[i] <- paste("Failed to download file: HTTP status", status_code(response))
    }
  }, error = function(e) {
    data$download_error[i] <- e$message
  })
}

# 6. Write the filename into new column 'svp_filename' and 7. If the process fails, write error message into new 'download_error' column
write.xlsx(data, "outcomes/processed_data.xlsx")
