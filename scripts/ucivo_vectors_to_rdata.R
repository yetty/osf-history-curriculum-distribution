# Load necessary libraries
install.packages("tidyverse")
library(tidyverse)

# Path to your CSV file
csv_file <- "data/ucivo.embeddings.csv"

# Read the CSV file
data <- read.csv(csv_file, stringsAsFactors = FALSE)

# Parse the ucivo_vector column for the first 10 items
data$ucivo_vector <- lapply(data$ucivo_vector, function(x) {
  # Remove square brackets and extra spaces using a correct escape
  cleaned_x <- gsub("\\[|\\]", "", x)  # Remove brackets correctly
  
  # Remove any unwanted spaces
  cleaned_x <- gsub("\\s", "", cleaned_x)  # Remove spaces

  # Split by commas and convert to numeric
  numeric_values <- as.numeric(strsplit(cleaned_x, ",")[[1]])

  # Check for any NA values and print a warning if they appear
  if (any(is.na(numeric_values))) {
    warning("NA values detected in the vector: ", x)
  }

  return(numeric_values)
})

save(data, file="data/ucivo.embeddings.RData")