# Load necessary libraries
library(readr)   # For reading CSV files
library(dplyr)   # For data manipulation
library(stats)
library(stringr)
library(writexl)
library(readxl)
library(ggplot2)
library(multcomp)









contingency_table_themes <- table(content_with_schools$grade, content_with_schools$theme)
chi_square_result_themes <- chisq.test(contingency_table_themes)
print(chi_square_result_themes)

unique(content_with_schools$theme)

df_contingency <- as.data.frame(contingency_table_themes)
# Manually specify the order of themes

# Set the factor levels for the `theme` column to your custom order
df_contingency$Var2 <- factor(df_contingency$Var2, levels = custom_theme_order)


ggplot(df_contingency, aes(x = Var1, y = Var2, fill = Freq)) + 
  geom_tile() + 
  labs(x = "Grade", y = "Theme", fill = "Count", title = "Contingency Table Heatmap") + 
  theme_minimal() + 
  scale_fill_gradient(low = "white", high = "steelblue") +
  scale_y_discrete(labels = function(x) stringr::str_trunc(x, 20, side = "right"))


# Step 2: Aggregate relative frequencies across all schools
average_relative_frequencies <- relative_frequencies %>%
  group_by(theme) %>%
  summarise(avg_relative_frequency = mean(relative_frequency, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(avg_relative_frequency))  # Sort by average relative frequency

# View the result
print(average_relative_frequencies)


contingency_table_topics <- table(ucivo_with_schools$rocnik, ucivo_with_schools$topic)
chi_square_result_topics <- chisq.test(contingency_table_topics)
print(chi_square_result_topics)
print(chi_square_result_topics$expected)


theme_counts <- ucivo_with_schools %>%
  group_by(strata, theme) %>%
  summarise(count = n())


# Step 1: Perform One-Way ANOVA for `theme`
anova_theme <- aov(count ~ factor(strata), data = theme_counts)

# Step 2: Display summary for `theme` ANOVA
summary(anova_theme)

# Step 3: If significant, perform Tukey's HSD for `theme`
if (summary(anova_theme)[[1]]$`Pr(>F)`[1] < 0.05) {
  tukey_theme <- TukeyHSD(anova_theme)
  print(tukey_theme)
} else {
  print("No significant differences found for `theme`, no Tukey's test performed.")
}

# Step 4: Perform One-Way ANOVA for `topic`
topic_counts <- ucivo_with_schools %>%
  group_by(strata, topic) %>%
  summarise(count = n())

anova_topic <- aov(count ~ factor(strata), data = topic_counts)

# Step 5: Display summary for `topic` ANOVA
summary(anova_topic)

# Step 6: If significant, perform Tukey's HSD for `topic`
if (summary(anova_topic)[[1]]$`Pr(>F)`[1] < 0.05) {
  tukey_topic <- TukeyHSD(anova_topic)
  print(tukey_topic)
} else {
  print("No significant differences found for `topic`, no Tukey's test performed.")
}

# Optional: Visualize the results for `theme` and `topic` using boxplots
ggplot(theme_counts, aes(x = strata, y = count, fill = strata)) +
  geom_boxplot() +
  labs(title = "Distribution of Theme Counts Across School Sizes",
       x = "School Size (Strata)",
       y = "Theme Count") +
  scale_x_discrete(labels = c("Small", "Medium", "Large")) +
  theme_minimal()

# Calculate the mean and standard error for theme counts by school size
theme_summary <- theme_counts %>%
  group_by(theme) %>%
  summarise(mean_count = mean(count), 
            se = sd(count) / sqrt(n()))  # Standard error

# Plot bar plot with error bars
ggplot(theme_summary, aes(x = theme, y = mean_count, fill = theme)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  geom_errorbar(aes(ymin = mean_count - se, ymax = mean_count + se), width = 0.2) +
  labs(title = "Mean Theme Counts Across School Sizes",
       x = "School Size (Strata)",
       y = "Mean Theme Count") +
  theme_minimal()

ggplot(ucivo_with_schools, aes(x = factor(strata), y = topic)) +
  geom_boxplot() +
  labs(x = "School Size", y = "Topic", title = "Content Distribution by School Size for Topic")


# Define a threshold to split the beginning and end of the grade
# Assuming you have a reasonable number of rows per grade, e.g., 10 entries per grade.
# Define the function
# Define the function
analyze_curriculum_content <- function(rocnik, column) {
  
  # Filter data for the given grade (rocnik)
  ucivo_grade_filtered <- ucivo_with_schools %>%
    filter(rocnik == !!rocnik)
  
  # Set number of rows to consider as "beginning" and "end"
  num_beginning <- 5  # First 5 rows per grade per school
  num_end <- 5  # Last 5 rows per grade per school
  
  # Get the first `num_beginning` rows for each school (beginning)
  beginning_data <- ucivo_grade_filtered %>%
    group_by(izo, rocnik) %>%
    slice_head(n = num_beginning)
  
  # Get the last `num_end` rows for each school (end)
  end_data <- ucivo_grade_filtered %>%
    group_by(izo, rocnik) %>%
    slice_tail(n = num_end)
  
  # Count frequency of the selected column (theme or topic) at the beginning
  beginning_counts <- beginning_data %>%
    group_by(izo, !!sym(column)) %>%
    summarise(count = n()) %>%
    arrange(desc(count))
  
  # Count frequency of the selected column (theme or topic) at the end
  end_counts <- end_data %>%
    group_by(izo, !!sym(column)) %>%
    summarise(count = n()) %>%
    arrange(desc(count))
  
  # Rank schools based on column counts at the beginning
  beginning_ranked <- beginning_counts %>%
    group_by(izo) %>%
    arrange(desc(count)) %>%
    top_n(1)  # Get the top theme/topic for each school at the beginning
  
  # Rank schools based on column counts at the end
  end_ranked <- end_counts %>%
    group_by(izo) %>%
    arrange(desc(count)) %>%
    top_n(1)  # Get the top theme/topic for each school at the end
  
# Ensure we filter and sort before plotting
# Filter the top 5 most emphasized content at the beginning, sorted by count
beginning_ranked_top5 <- beginning_counts %>%
  group_by(izo) %>%
  arrange(desc(count)) %>%
  slice_head(n = 5)  # Get the top 5 items after sorting by count

# Filter the top 5 most emphasized content at the end, sorted by count
end_ranked_top5 <- end_counts %>%
  group_by(izo) %>%
  arrange(desc(count)) %>%
  slice_head(n = 5)  # Get the top 5 items after sorting by count

# Plot the top 5 most emphasized content at the beginning, with no legend
p1 <- ggplot(beginning_ranked_top5, aes(x = reorder(!!sym(column), count), y = count, fill = !!sym(column))) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = paste("Most Emphasized", column, "at the Beginning of Grade", rocnik),
       x = column,
       y = "Frequency") +
  theme_minimal() +
  theme(legend.position = "none")  # Remove legend

# Plot the top 5 most emphasized content at the end, with no legend
p2 <- ggplot(end_ranked_top5, aes(x = reorder(!!sym(column), count), y = count, fill = !!sym(column))) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = paste("Most Emphasized", column, "at the End of Grade", rocnik),
       x = column,
       y = "Frequency") +
  theme_minimal() +
  theme(legend.position = "none")  # Remove legend

  # Save the plots as PNG files
  ggsave(paste0(column, "_", rocnik, "_beginning.png"), plot = p1, width = 20, height = 6)
  ggsave(paste0(column, "_", rocnik, "_end.png"), plot = p2, width = 20, height = 6)
}



analyze_curriculum_content(6, "topic")

analyze_curriculum_content(7, "topic")

analyze_curriculum_content(8, "topic")

analyze_curriculum_content(9, "topic")
