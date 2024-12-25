# Install and load necessary packages
install.packages("writexl")  # Install the writexl package for writing Excel files

library(readr)    # For reading CSV files
library(dplyr)    # For data manipulation
library(sampling) # For sampling functions
library(writexl)  # For writing Excel files
library(tidyr)    # For tidying data

# Set the seed for reproducibility
set.seed(20241216) # Ensures that the random sampling can be reproduced

# Specify the file path to the data
file_path <- "data/ucivo.gpt-4o-2024-08-06.csv"

# Load the CSV file into a dataframe
data <- read_csv(file_path)

# Filter the data to include only specific grades (6 to 9) and non-missing content
filtered_data <- data %>%
  filter(rocnik %in% c("6", "7", "8", "9")) %>%
  filter(!is.na(ucivo))

# Create a table of counts for each grade level
strata <- table(filtered_data$rocnik)

# Set up parameters for 95% confidence and 5% margin of error
confidence_level <- 0.95
Z <- 1.96  # Z-score for 95% confidence level
E <- 0.05  # 5% margin of error
p <- 0.5   # Proportion (assuming maximum variability)

# Calculate the total sample size using the formula for sample size
total_population <- nrow(filtered_data)
total_sample_size <- floor((Z^2 * p * (1 - p)) / (E^2))

# Calculate the proportional sample size for each stratum
stratum_sizes <- filtered_data %>%
  group_by(rocnik) %>%
  summarise(count = n()) %>%
  mutate(proportion = count / total_population) %>%
  mutate(sample_size = floor(proportion * total_sample_size))

# Perform stratified sampling using the calculated sizes
stratified_sample <- strata(filtered_data, 
                            stratanames = "rocnik", 
                            size = stratum_sizes$sample_size, 
                            method = "srswor")

# Extract the sampled data
sampled_data_llm <- filtered_data %>%
  slice(stratified_sample$ID_unit)  # Select rows by ID_unit

# Save the sampled data to an RData file
save(sampled_data_llm, file="data/ucivo.sample-topics-gpt-4o.RData")

# Prepare the sampled data for Excel output
sampled_data <- filtered_data %>%
  slice(stratified_sample$ID_unit) %>%  # Select rows by ID_unit
  select(rocnik, ucivo)                 # Keep only the desired columns

# Write the sampled data to an Excel file
write_xlsx(sampled_data, "data/ucivo.sample-topics.xlsx")

# Load additional data for comparison
gptmini_data <- read_csv("data/ucivo.gpt-4o-mini-2024-07-18.csv")

# Initialize an empty list to store results
results <- list()

# Loop through each row in `sampled_data_llm`
for (i in 1:nrow(sampled_data_llm)) {
  current_row <- sampled_data_llm[i, ]
  
  # 1. Match all three columns: `izo`, `rocnik`, `ucivo`
  match <- gptmini_data %>%
    filter(
      izo == current_row$izo & 
      rocnik == current_row$rocnik & 
      ucivo == current_row$ucivo
    )
  
  # 2. If no match, match `rocnik` and `ucivo`
  if (nrow(match) == 0) {
    match <- gptmini_data %>%
      filter(
        rocnik == current_row$rocnik & 
        ucivo == current_row$ucivo
      )
  }
  
  # 3. If no match, match `ucivo` only
  if (nrow(match) == 0) {
    match <- gptmini_data %>%
      filter(
        ucivo == current_row$ucivo
      )
  }
  
  # 4. If still no match, create a row with NA for `blok RVP` and `ucivo RVP`
  if (nrow(match) == 0) {
    match <- tibble(
      izo = current_row$izo,
      rocnik = current_row$rocnik,
      ucivo = current_row$ucivo,
      `blok RVP` = NA,
      `ucivo RVP` = NA
    )
  }
  
  # Append the matched or created row to the results list
  results[[i]] <- match %>% slice(1)
}

# Combine all results into a single data frame
sampled_data_gpt4o_mini <- bind_rows(results)

# Save the combined results to an RData file
save(sampled_data_gpt4o_mini, file="data/ucivo.sample-topics-gpt-4o-mini.RData")