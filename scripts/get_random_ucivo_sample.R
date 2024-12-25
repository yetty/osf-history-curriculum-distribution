library(readr)    # For reading CSV files
library(dplyr)    # For data manipulation
library(sampling) # For sampling functions

# Set the seed for reproducibility
set.seed(20241216) # Ensures that the random sampling can be reproduced

# Specify the file path to the data
file_path <- "data/ucivo.raw.csv"

# Load the CSV file into a dataframe
# 'read_csv' is used from the readr package for efficient reading
data <- read_csv(file_path)

# Filter the data to include only specific grades (6 to 9)
filtered_data <- data %>%
  filter(rocnik %in% c("6", "7", "8", "9"))

# Create a table of counts for each grade level
strata <- table(filtered_data$rocnik)

# Calculate the total number of entries in the filtered data
total_population <- nrow(filtered_data)

# Define the total number of samples you want to draw
total_sample_size <- 20

# Calculate the proportional sample size for each grade level
stratum_sizes <- filtered_data %>%
  group_by(rocnik) %>% # Group data by grade level
  summarise(count = n()) %>% # Count the number of entries in each group
  mutate(proportion = count / total_population) %>% # Calculate the proportion of each group
  mutate(sample_size = floor(proportion * total_sample_size)) # Calculate the sample size for each group

# Perform stratified sampling using the calculated sizes
# 'strata' function is used to ensure each grade level is proportionally represented
stratified_sample <- strata(filtered_data, 
                            stratanames = "rocnik", # The variable used for stratification
                            size = stratum_sizes$sample_size, # Sample sizes for each stratum
                            method = "srswor") # Simple random sampling without replacement

# Extract the sampled data based on the IDs obtained from stratified sampling
sampled_data <- filtered_data[stratified_sample$ID_unit, ]

# Save the sampled data to a new CSV file
write.csv(sampled_data, "data/ucivo.sample.csv", row.names = FALSE)