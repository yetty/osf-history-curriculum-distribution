# Load required libraries
library(dplyr)         # For data manipulation (filtering, mutating, joining, etc.)
library(readr)         # For reading CSV files
library(writexl)       # For writing Excel files
library(readxl)        # For reading Excel files
library(tidyr)         # For handling NA values and reshaping data

# Load the datasets
load("outcomes/sampled_schools.RData")  # Load pre-existing dataset of sampled schools

ucivo <- read_csv("data/ucivo.gpt-4o-2024-08-06.csv")  # Main curriculum dataset
# This dataset contains information about different curriculum topics and themes.

# Clean the `ucivo` dataset
ucivo_cleaned <- ucivo %>%
  filter(!is.na(ucivo), rocnik %in% c("6", "7", "8", "9")) %>%  # Filter out rows with NA in `ucivo` and only include grades 6 to 9
  mutate(
    # Standardizing values in the `blok RVP` column for consistency
    `blok RVP` = case_when(
      `blok RVP` == "Jiné" ~ "JINÉ",  # Standardize the "Jiné" value to "JINÉ" to avoid inconsistencies
      `blok RVP` %in% c(
        "OBJE VY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY",
        "OBJEVA A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY",
        "OBJEWY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY",
        "OBJEY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY",
        "OBRATY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY"
      ) ~ "OBJEVY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY",  # Replace the various misspellings of the same phrase with a single standard value
      TRUE ~ `blok RVP`  # Keep other values in the `blok RVP` column unchanged
    )
  )

distinct_topics <- sort(unique(ucivo_cleaned$`ucivo RVP`))
write_xlsx(as.data.frame(distinct_topics), "data/distinct_topics_pre.xlsx")

# Clean the `ucivo RVP` column using a mapping from an external Excel file
# The external Excel file (`distinct_ucivo_rvp.xlsx`) contains a mapping of values to standardize
mapping_df <- read_excel("data/distinct_ucivo_rvp.xlsx")  # Load the mapping of values from Excel
value_mapping <- setNames(mapping_df[[2]], mapping_df[[1]])  # Create a named vector for value mapping
english_mapping <- setNames(mapping_df[[3]], mapping_df[[1]])  # Create a named vector for value mapping
order_mapping <- setNames(mapping_df[[4]], mapping_df[[1]])
ucivo_cleaned$`ucivo RVP` <- recode(ucivo_cleaned$`ucivo RVP`, !!!value_mapping)  # Replace values in `ucivo RVP` column based on the mapping
ucivo_cleaned$topic_en <- recode(ucivo_cleaned$`ucivo RVP`, !!!english_mapping)  # Replace values in `ucivo RVP` column based on the mapping
ucivo_cleaned$order <- recode(ucivo_cleaned$`ucivo RVP`, !!!order_mapping) 

custom_theme_order <- c(
  "ČLOVĚK V DĚJINÁCH",
  "POČÁTKY LIDSKÉ SPOLEČNOSTI",
  "NEJSTARŠÍ CIVILIZACE. KOŘENY EVROPSKÉ KULTURY",
  "KŘESŤANSTVÍ A STŘEDOVĚKÁ EVROPA",
  "OBJEVY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY",
  "MODERNIZACE SPOLEČNOSTI",
  "MODERNÍ DOBA",
  "ROZDĚLENÝ A INTEGRUJÍCÍ SE SVĚT",
  "JINÉ"
) 

english_themes <- c(
  "A. HUMANITY IN HISTORY",
  "B. THE ORIGINS OF HUMAN SOCIETY",
  "C. EARLIEST CIVILIZATIONS. ROOTS OF EUROPEAN CULTURE",
  "D. CHRISTIANITY AND MEDIEVAL EUROPE",
  "E. DISCOVERIES AND CONQUESTS. BEGINNINGS OF THE MODERN ERA",
  "F. MODERNIZATION OF SOCIETY",
  "G. THE MODERN ERA",
  "H. A DIVIDED AND INTEGRATING WORLD",
  "OTHER"
)

theme_mapping <- setNames(english_themes, custom_theme_order)
ucivo_cleaned$theme_en <- recode(ucivo_cleaned$`blok RVP`, !!!theme_mapping) 


# load("data/content_with_schools.RData")

# Merge the cleaned `ucivo` dataset with the `sampled_schools` dataset using the `izo` column
content_with_schools <- ucivo_cleaned %>%
  inner_join(sampled_schools, by = "izo") %>%  # Perform an inner join to merge the datasets by the `izo` column
  rename(schoolId=`izo`, grade=`rocnik`, content=`ucivo`, theme=`blok RVP`, topic=`ucivo RVP`) %>%  # Rename the columns for clarity and consistency
  mutate(schoolId=as.factor(schoolId), grade=as.factor(grade), theme=as.factor(theme), topic=as.factor(topic)) %>%  # Convert `rocnik`, `theme`, and `topic` to factors for better handling in statistical models
  filter(!is.na(strata) & !is.na(theme) & !is.na(topic)) %>%  # Remove rows with missing values in the relevant columns (`strata`, `theme`, and `topic`)
  dplyr::select(schoolId, strata, grade, content, theme, theme_en, topic, topic_en, order) # Select only relevant columns

# Save the cleaned and merged dataset for future use
save(content_with_schools, file="data/content_with_schools.RData")
