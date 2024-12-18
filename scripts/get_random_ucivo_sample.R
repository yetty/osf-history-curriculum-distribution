
library(readr)
library(dplyr)
library(sampling)

# Set the seed for reproducibility
set.seed(20241216)

# Specify the file path
file_path <- "data/ucivo.raw.csv"

# Load the CSV file into a dataframe
# Replace 'read_csv' with 'read.csv' if you're not using the readr package
data <- read_csv(file_path)

filtered_data <- data %>%
  filter(rocnik %in% c("6", "7", "8", "9"))

strata <- table(filtered_data$rocnik)

# Set up parameters for 95% confidence and 5% margin of error
confidence_level <- 0.95
Z <- 1.96  # Z-score for 95% confidence level
E <- 0.05  # 5% margin of error
p <- 0.5  # Proportion (assuming maximum variability)

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
sampled_data <- filtered_data[stratified_sample$ID_unit, ]

# Save the sampled data to a CSV file
write.csv(sampled_data, "ucivo.sample.csv", row.names = FALSE)
