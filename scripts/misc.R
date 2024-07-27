# Load required library
library(dplyr)

# Load the CSV file
file_path <- 'outcomes/sampled_schools.csv'
sampled_schools <- read.csv(file_path)

# Check if website column is not empty and create website_bing_found column
sampled_schools <- sampled_schools %>%
  mutate(website_bing_found = !is.na(website) & website != "") %>%
  arrange(!website_bing_found)

# Save the updated data back to the CSV file
write.csv(sampled_schools, file = file_path, row.names = FALSE)

# Optionally, print a message indicating success
cat("Updated sampled_schools.csv with website_bing_found column.\n")







# Load necessary libraries
library(ggplot2)
library(dplyr)
library(hrbrthemes)

# Read the CSV file
data <- read.csv("outcomes/sampled_schools.csv")

# Convert the 'True' and 'False' strings to logical (boolean) values
data$website_bing_found <- data$website_bing_found == "True"
data$svp_bing_found <- data$svp_bing_found == "True"

strata_labels <- c("1" = "malá", "2" = "střední", "3" = "velká")

# 1. Calculate total and percentages for websites found
total_websites_found <- sum(data$website_bing_found, na.rm = TRUE)
websites_found_per_stratum <- data %>%
  group_by(strata) %>%
  summarize(count = sum(website_bing_found, na.rm = TRUE),
            total = n()) %>%
  mutate(percentage = (count / total) * 100)

# 2. Calculate total and percentages for ŠVPs found
total_svps_found <- sum(data$svp_bing_found, na.rm = TRUE)
svps_found_per_stratum <- data %>%
  group_by(strata) %>%
  summarize(count = sum(svp_bing_found, na.rm = TRUE),
            total = n()) %>%
  mutate(percentage = (count / total) * 100)

# Print the results
cat("Total websites found automatically:", total_websites_found, "\n")
cat("Websites found per stratum (count and percentage):\n")
print(websites_found_per_stratum)

cat("Total ŠVPs found automatically:", total_svps_found, "\n")
cat("ŠVPs found per stratum (count and percentage):\n")
print(svps_found_per_stratum)


# Websites found per stratum
p1 <- ggplot(websites_found_per_stratum, aes(x = factor(strata, levels = c("1", "2", "3"), labels = strata_labels), y = percentage, fill = factor(strata, levels = c("1", "2", "3"), labels = strata_labels))) +
  geom_bar(stat = "identity") +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "Nalezené webové stránky ZŠ",
       x = "Skupina škol podle počtu žáků", y = "Procento nalezených webů", fill = "Velikost ZŠ") +
  theme_ipsum() +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
  )
ggsave("weby.png", plot=p1, width=10, height=6)

 # ŠVPs found per stratum
p2 <- ggplot(svps_found_per_stratum, aes(x = factor(strata, levels = c("1", "2", "3"), labels = strata_labels), y = percentage, fill = factor(strata, levels = c("1", "2", "3"), labels = strata_labels))) +
  geom_bar(stat = "identity") +
  scale_y_continuous(limits = c(0, 100)) +
  labs(title = "Nalezené ŠVP jednotlivých ZŠ",
       x = "Skupina škol podle počtu žáků", y = "Procento nalezených ŠVP", fill = "Velikost ZŠ") +
  theme_ipsum() +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
  )
ggsave("svp.png", plot=p2, width=10, height=6)



library(openxlsx)
file_path <- 'outcomes/sampled_schools.csv'
sampled_schools <- read.csv(file_path)
write.xlsx(sampled_schools, file = 'outcomes/sampled_schools.xlsx')
