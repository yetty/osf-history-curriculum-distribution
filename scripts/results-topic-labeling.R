# Install necessary packages for statistical analysis
install.packages("psych")  # For psychological statistics
install.packages("irr")    # For inter-rater reliability measures

# Load required libraries
library(readxl)  # For reading Excel files
library(dplyr)   # For data manipulation
library(psych)   # For psychological statistics
library(boot)    # For bootstrapping
library(irr)     # For inter-rater reliability measures

# Load GPT-4o labelled data
load("data/ucivo.sample-topics-gpt-4o.RData")
labelled_data_gpt4o <- sampled_data_llm %>%
  rename(theme = `blok RVP`, topic = `ucivo RVP`) %>%
  select(izo, rocnik, ucivo, theme, topic) %>%
  mutate(theme = str_replace_all(theme, "\t", "")) %>%
  mutate(theme = ifelse(theme == "OBJE VY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY", "OBJEVY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY", theme))

# Load GPT-4o-mini labelled data
load("data/ucivo.sample-topics-gpt-4o-mini.RData")
labelled_data_gpt4o_mini <- sampled_data_gpt4o_mini %>%
  rename(theme = `blok RVP`, topic = `ucivo RVP`) %>%
  select(izo, rocnik, ucivo, theme, topic) %>%
  mutate(theme = str_replace_all(theme, "\t", "")) %>%
  mutate(theme = ifelse(theme == "OBJE VY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY", "OBJEVY A DOBÝVÁNÍ. POČÁTKY NOVÉ DOBY", theme))

# Load human-labelled data
labelled_data_human <- read_excel("data/ucivo.sample-topics.xlsx") %>%
  mutate(theme = str_replace_all(theme, "\t", "")) %>%
  mutate(theme = ifelse(theme == "NEJSTARŠÍ CIVILIZACE", "NEJSTARŠÍ CIVILIZACE. KOŘENY EVROPSKÉ KULTURY", theme))

# Function to compute unweighted Cohen's kappa
compute_unweighted_kappa <- function(dataset1, dataset2, column) {
  kappa_whole <- cohen.kappa(x = cbind(dataset1[[column]], dataset2[[column]]))
  print(kappa_whole)
  
  merged_data <- data.frame(
    rocnik = dataset1$rocnik,
    value1 = dataset1[[column]],
    value2 = dataset2[[column]]
  )
  
  kappa_by_rocnik <- merged_data %>%
    group_by(rocnik) %>%
    summarise(
      kappa = cohen.kappa(x = cbind(value1, value2))$kappa,
      lower_confid = pmax(cohen.kappa(x = cbind(value1, value2))$confid[1], -1),
      upper_confid = pmin(cohen.kappa(x = cbind(value1, value2))$confid[2], 1)
    ) %>%
    ungroup()
  
  kappa_whole_row <- data.frame(
    rocnik = NA,
    kappa = kappa_whole$kappa,
    lower_confid = pmax(kappa_whole$confid[1], -1),
    upper_confid = pmin(kappa_whole$confid[2], 1)
  )
  
  final_result <- bind_rows(kappa_by_rocnik, kappa_whole_row)
  return(final_result)
}

# Function to compute Fleiss' kappa
compute_fleiss_kappa <- function(dataset1, dataset2, column) {
  kappa_whole <- kappam.fleiss(cbind(dataset1[[column]], dataset2[[column]]))
  print(kappa_whole)
  
  merged_data <- data.frame(
    rocnik = dataset1$rocnik,
    value1 = dataset1[[column]],
    value2 = dataset2[[column]]
  )
  
  kappa_by_rocnik <- merged_data %>%
    group_by(rocnik) %>%
    summarise(
      kappa = round(kappam.fleiss(cbind(value1, value2))$value, 2),
      p = round(kappam.fleiss(cbind(value1, value2))$p.value, 4)
    ) %>%
    ungroup()
  
  kappa_whole_row <- data.frame(
    rocnik = NA,
    kappa = round(kappa_whole$value, 2),
    p = round(kappa_whole$p.value, 4)
  )
  
  final_result <- bind_rows(kappa_by_rocnik, kappa_whole_row)
  return(final_result)
}

# Compare GPT-4o vs Human
theme_fleiss_kappa <- compute_fleiss_kappa(labelled_data_gpt4o, labelled_data_human, "theme")
print(theme_fleiss_kappa)

topics_fleiss_kappa <- compute_fleiss_kappa(labelled_data_gpt4o, labelled_data_human, "topic")
print(topics_fleiss_kappa)

# Compare GPT-4o-mini vs Human
theme_fleiss_kappa_mini <- compute_fleiss_kappa(labelled_data_gpt4o_mini, labelled_data_human, "theme")
print(theme_fleiss_kappa_mini)

topics_fleiss_kappa_mini <- compute_fleiss_kappa(labelled_data_gpt4o_mini, labelled_data_human, "topic")
print(topics_fleiss_kappa_mini)

# Compare GPT-4o vs GPT-4o-mini
theme_fleiss_kappa_llms <- compute_fleiss_kappa(labelled_data_gpt4o, labelled_data_gpt4o_mini, "theme")
print(theme_fleiss_kappa_llms)

topics_fleiss_kappa_llms <- compute_fleiss_kappa(labelled_data_gpt4o, labelled_data_gpt4o_mini, "topic")
print(topics_fleiss_kappa_llms)