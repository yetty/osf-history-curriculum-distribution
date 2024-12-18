library(readxl)
library(dplyr)

# Specify the path to the Excel file
file_path <- "outcomes/sampled_schools.xlsx"

# Read the data from the Excel file
sampled_schools_data <- read_excel(file_path)

# Select and rename the columns
schools_with_curriculum_source <- sampled_schools_data %>%
  # Add the 'Curriculum Obtained' column
  mutate(
    source = case_when(
      `manually_found` ~ "website",                # If Website is TRUE, set Source to 'website'
      `poslano` ~ "mail request", # If Unofficial Request is TRUE, set Source to 'mail request'
      `datovkou` ~ "official request", # If Official Request is TRUE, set Source to 'official request'
      `refused` ~ "refused",
      TRUE ~ "no response"                  # If none are TRUE, set Source to NA
    )
  ) %>%
  select(izo, strata, source)

summary_data <- schools_with_curriculum_source %>%
  group_by(source) %>%
  summarize(count = n(), .groups = "drop") %>%
  # Add percentage column
  mutate(percentage = (count / sum(count)) * 100)

