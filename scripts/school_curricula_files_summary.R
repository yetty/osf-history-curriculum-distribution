if (!require(pdftools)) install.packages("pdftools")
library(pdftools)
library(ggplot2)

# Set the folder path where the PDFs are located
folder_path <- "data/SVPs" # Replace with your folder path

# Get a list of all PDF files in the folder
pdf_files <- list.files(folder_path, pattern = "\\.pdf$", full.names = TRUE)


# Initialize a data frame to store results
pdf_dataset <- data.frame(FileName = character(), FileSize = numeric(), NumPages = integer(), stringsAsFactors = FALSE)

# Loop over each PDF file and get the number of pages and file size
for (pdf_file in pdf_files) {
  # Try to get the number of pages, handle errors if reading fails
  tryCatch({
    # Get the number of pages using pdf_info
    pdf_info <- pdf_info(pdf_file)
    num_pages <- pdf_info$pages
    
    # Get the file size in bytes
    file_size <- file.info(pdf_file)$size
    
    # Extract the file name (without the path)
    file_name <- basename(pdf_file)
    
    # Append the results to the dataset
    pdf_dataset <- rbind(pdf_dataset, data.frame(FileName = file_name, FileSize = file_size, NumPages = num_pages))
  }, error = function(e) {
    # If an error occurs, append the file name with NA for NumPages and FileSize
    file_name <- basename(pdf_file)
    file_size <- file.info(pdf_file)$size
    pdf_dataset <- rbind(pdf_dataset, data.frame(FileName = file_name, FileSize = file_size, NumPages = NA))
    message(paste("Failed to process", file_name, ":", e$message))
  })
}

# Print the resulting dataset
print(pdf_dataset)

# Compute average file size and number of pages
avg_file_size <- mean(pdf_dataset$FileSize, na.rm = TRUE)
avg_num_pages <- mean(pdf_dataset$NumPages, na.rm = TRUE)

cat("Average file size (bytes):", avg_file_size, "\n")
cat("Average number of pages:", avg_num_pages, "\n")


# Print the resulting dataset
print(pdf_dataset)

pdf_dataset_clean <- pdf_dataset %>%
  filter(!is.na(NumPages) & !is.na(FileSize) & NumPages > 100)

# Create a histogram for the distribution of pages number and file size
ggplot(pdf_dataset_clean, aes(x = NumPages)) +
  geom_histogram(binwidth = 20, fill = "white", color = "black", alpha = 1) +
  labs(
    title = "Distribution of Number of Pages in complete School Curricula",
    x = "Number of Pages",
    y = "Count of PDFs",
    caption = "Note: Only complete curricula were included in the dataset, excluding extracted parts."
  ) +
  scale_x_continuous(
    breaks = seq(0, max(pdf_dataset_clean$NumPages, na.rm = TRUE), by = 200)  # Adjust `by` as needed
  ) +
  scale_y_continuous(
    breaks = seq(0, max(pdf_dataset_clean$NumPages, na.rm = TRUE), by = 5
                 )  # Adjust `by` as needed
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.title = element_text(face = "bold"),
    axis.text = element_text(color = "black"),
    panel.grid.major = element_line(color = "grey80"),
    panel.grid.minor = element_blank()
  )

# Optionally save the plot
ggsave("curricula_pages_distribution_plot.pdf", width = 8, height = 6, device = "pdf")
