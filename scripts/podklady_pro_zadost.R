# Install necessary packages if not already installed
# install.packages("dplyr")
# install.packages("readxl")

library(dplyr)
library(readxl)
library(xml2)
library(purrr)
library(writexl)

# Load the Excel file
data <- read_excel("outcomes/sampled_schools.xlsx")

# Filter rows where 'svp_filename' column is empty
filtered_data <- data %>%
  filter(is.na(svp_filename) | svp_filename == "") %>%
  select(izo, zar_naz, ulice, misto)

# View the filtered data
print(filtered_data)


xml_data <- read_xml("data/rejstrik.xml")

izo_list <- filtered_data$izo

# Extract and filter <PravniSubjekt> nodes where at least one <SkolaZarizeni> has an IZO in izo_list
pravni_subjekty <- xml_find_all(xml_data, "//PravniSubjekt") %>%
  keep(~ any(xml_text(xml_find_all(.x, ".//SkolaZarizeni/IZO")) %in% izo_list))


# Extract all relevant data at once using purrr and dplyr
school_data <- pravni_subjekty %>%
  map_df(~ {
    # Extract common ICO for all associated schools
    ico <- xml_text(xml_find_first(.x, "./ICO"))
    
    # Extract the schools under each <PravniSubjekt>
    schools <- xml_find_all(.x, ".//SkolaZarizeni")
    
    # Map over each school to extract the relevant fields
    map_df(schools, ~ {
      tibble(
        izo = xml_text(xml_find_first(.x, "./IZO")),
        skola_plny_nazev = xml_text(xml_find_first(.x, "./SkolaPlnyNazev")),
        ico = ico  # Use the ICO from the parent <PravniSubjekt>
      )
    })
  })


matched_data <- filtered_data %>%
  left_join(school_data, by = "izo")


write_xlsx(matched_data, "outcomes/seznam_skol_zadosti.xlsx")
