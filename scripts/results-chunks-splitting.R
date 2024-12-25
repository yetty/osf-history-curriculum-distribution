library(readr)    # For reading CSV files
library(dplyr)    # For data manipulation
library(tidyr)    # For tidying data
library(stringr)  # For string operations
library(writexl)  # For writing Excel files
library(stringi)  # For string operations, including handling non-ASCII characters

# Load human-coded data
human_raw <- read_csv("data/ucivo.sample-chunks-human.csv")

# Process the human-coded dataset
human_processed <- human_raw %>%
  separate_rows(ucivo, sep = "\n") %>%  # Split `ucivo` column into separate rows
  mutate(ucivo = str_trim(ucivo)) %>%   # Trim whitespace from each line
  filter(ucivo != "") %>%               # Remove empty lines
  select(izo, rocnik, ucivo) %>%        # Select relevant columns
  distinct(izo, rocnik, ucivo, .keep_all = TRUE) %>%  # Remove duplicate rows
  mutate(rocnik = as.character(rocnik)) %>%  # Ensure `rocnik` is a character
  rename(human_ucivo = ucivo)           # Rename column for clarity

# View the processed dataset
print(human_processed)

# Load GPT-4 processed data
gpt4 <- read_csv("data/ucivo.gpt-4o-2024-08-06.csv") %>%
  select(izo, rocnik, ucivo) %>%
  distinct(izo, rocnik, ucivo, .keep_all = TRUE) %>%
  filter(!is.na(ucivo))

# Load GPT-4 mini processed data
gpt4mini <- read_csv("data/ucivo.gpt-4o-mini-2024-07-18.csv") %>%
  select(izo, rocnik, ucivo) %>%
  distinct(izo, rocnik, ucivo, .keep_all = TRUE) %>%
  filter(!is.na(ucivo))

# Get unique combinations of `izo` and `rocnik` from human data
human_combinations <- human_processed %>%
  select(izo, rocnik) %>%
  distinct()

# Filter GPT-4 data to match human data combinations
gpt4_sample <- gpt4 %>%
  semi_join(human_combinations, by = c("izo", "rocnik")) %>%
  rename(gpt4_ucivo = ucivo)

# Filter GPT-4 mini data to match human data combinations
gpt4mini_sample <- gpt4mini %>%
  semi_join(human_combinations, by = c("izo", "rocnik")) %>%
  rename(gpt4mini_ucivo = ucivo)

# Function to normalize strings for comparison
normalize_string <- function(input_string) {
  normalized <- tolower(input_string)  # Convert to lowercase
  normalized <- stringi::stri_trans_general(normalized, "Latin-ASCII")  # Convert to ASCII
  normalized <- gsub("[^a-z0-9 ]", "", normalized)  # Remove non-alphanumeric characters
  normalized <- gsub(" +", " ", normalized)  # Replace multiple spaces with a single space
  normalized <- trimws(normalized)  # Trim leading and trailing spaces
  return(normalized)
}

# Initialize a dataframe to store comparison results
result_data <- data.frame(
  izo = integer(0),
  rocnik = integer(0),
  true_positive_gpt4 = integer(0),
  false_positive_gpt4 = integer(0),
  false_negative_gpt4 = integer(0),
  precision_gpt4 = integer(0),
  recall_gpt4 = integer(0),
  f1_score_gpt4 = integer(0),
  true_positive_gpt4mini = integer(0),
  false_positive_gpt4mini = integer(0),
  false_negative_gpt4mini = integer(0),
  precision_gpt4mini = integer(0),
  recall_gpt4mini = integer(0),
  f1_score_gpt4mini = integer(0)
)

# Compare human and GPT-4 results for each combination of `izo` and `rocnik`
for (i in 1:nrow(human_combinations)) {
  current_izo <- human_combinations$izo[i]
  current_rocnik <- human_combinations$rocnik[i]
  
  filtered_rows_human <- human_processed %>%
    filter(izo == current_izo, rocnik == current_rocnik)
  filtered_rows_gpt4 <- gpt4_sample %>%
    filter(izo == current_izo, rocnik == current_rocnik)
  filtered_rows_gpt4mini <- gpt4mini_sample %>%
    filter(izo == current_izo, rocnik == current_rocnik)  

  found_rows_gpt4 <- c()
  found_rows_gpt4mini <- c()
  
  false_negative_gpt4 <- 0
  false_negative_gpt4mini <- 0

  for (j in 1:nrow(filtered_rows_human)) {
    found <- FALSE
    current_human_ucivo <- normalize_string(filtered_rows_human$human_ucivo[j])
    
    for (k in 1:nrow(filtered_rows_gpt4)) {
      current_gpt4_ucivo <- normalize_string(filtered_rows_gpt4$gpt4_ucivo[k])
      
      if (grepl(current_gpt4_ucivo, current_human_ucivo) == TRUE) {
        found <- TRUE
        found_rows_gpt4 <- c(found_rows_gpt4, k)
      }
    }
    
    if (found == FALSE) {
      false_negative_gpt4 <- false_negative_gpt4 + 1
    }
    
    found <- FALSE
    for (k in 1:nrow(filtered_rows_gpt4mini)) {
      current_gpt4mini_ucivo <- normalize_string(filtered_rows_gpt4mini$gpt4mini_ucivo[k])
      
      if (grepl(current_gpt4_ucivo, current_human_ucivo) == TRUE) {
        found <- TRUE
        found_rows_gpt4mini <- c(found_rows_gpt4mini, k)
      }
    }
    
    if (found == FALSE) {
      false_negative_gpt4mini <- false_negative_gpt4mini + 1
    }
  }
  
  true_positive_gpt4 <- length(found_rows_gpt4)
  false_positive_gpt4 <- pmax(nrow(filtered_rows_gpt4) - length(found_rows_gpt4), 0)
  precision_gpt4 = true_positive_gpt4 / (true_positive_gpt4 + false_positive_gpt4)
  recall_gpt4 = true_positive_gpt4 / (true_positive_gpt4 + false_negative_gpt4)
  f1_score_gpt = 2 * (precision_gpt4 * recall_gpt4) / (precision_gpt4 + recall_gpt4)
  
  true_positive_gpt4mini <- length(found_rows_gpt4mini)
  false_positive_gpt4mini <- nrow(filtered_rows_gpt4mini) - length(found_rows_gpt4mini)
  precision_gpt4mini = true_positive_gpt4mini / (true_positive_gpt4mini + false_positive_gpt4mini)
  recall_gpt4mini = true_positive_gpt4mini / (true_positive_gpt4mini + false_negative_gpt4mini)
  f1_score_gptmini = 2 * (precision_gpt4mini * recall_gpt4mini) / (precision_gpt4mini + recall_gpt4mini)
  
  new_row <- data.frame(
    izo = current_izo,
    rocnik = current_rocnik,
    true_positive_gpt4 = true_positive_gpt4,
    false_positive_gpt4 = false_positive_gpt4,
    false_negative_gpt4 = false_negative_gpt4,
    precision_gpt4 = precision_gpt4,
    recall_gpt4 = recall_gpt4,
    f1_score_gpt4 = f1_score_gpt,
    true_positive_gpt4mini = true_positive_gpt4mini,
    false_positive_gpt4mini = false_positive_gpt4mini,
    false_negative_gpt4mini = false_negative_gpt4mini,
    precision_gpt4mini = precision_gpt4mini,
    recall_gpt4mini = recall_gpt4mini,
    f1_score_gpt4mini = f1_score_gptmini
  )
  
  # Append the new row to the result_data
  result_data <- rbind(result_data, new_row)
}

# Calculate overall precision, recall, and F1-score for GPT-4
TP <- sum(result_data$true_positive_gpt4)
FP <- sum(result_data$false_positive_gpt4)
FN <- sum(result_data$false_negative_gpt4)

precision <- TP / (TP + FP)
recall <- TP / (TP + FN)
f1_score <- 2 * (precision * recall) / (precision + recall)

cat("GPT4\n")
cat("Precision: ", precision, "\n")
cat("Recall: ", recall, "\n")
cat("F1-Score: ", f1_score, "\n")

# Calculate overall precision, recall, and F1-score for GPT-4 mini
TP <- sum(result_data$true_positive_gpt4mini)
FP <- sum(result_data$false_positive_gpt4mini)
FN <- sum(result_data$false_negative_gpt4mini)

precision <- TP / (TP + FP)
recall <- TP / (TP + FN)
f1_score <- 2 * (precision * recall) / (precision + recall)

cat("GPT4 mini\n")
cat("Precision: ", precision, "\n")
cat("Recall: ", recall, "\n")
cat("F1-Score: ", f1_score, "\n")