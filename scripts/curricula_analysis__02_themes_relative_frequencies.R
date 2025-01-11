# Load required libraries
library(dplyr)       # For data manipulation
library(tidyr)       # For reshaping data (pivot_wider)
library(ggplot2)     # For visualization
library(stringr)     # For string truncation
library(scales)      # For percentage formatting in plots

# Load the dataset
load("data/content_with_schools.RData")  # Load pre-processed dataset containing content with school information

# Define a custom theme order for plotting by RVP
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

total_schools <- content_with_schools %>%
  filter(!is.na(content)) %>%
  summarise(total = n_distinct(schoolId)) %>%
  pull(total)

# Step 1: Check if a theme is present in a school (TRUE/FALSE per school-grade-theme combination)
school_theme_presence <- content_with_schools %>%
  group_by(schoolId, grade, theme_en) %>%         # Group by school ID, grade, and theme
  summarise(count = n(), .groups = "drop") %>%  # Count occurrences of themes per school
  mutate(theme_present = ifelse(count > 0, 1, 0)) %>%  # 1 if theme is present in the school, else 0
  ungroup()

# Step 1: Compute relative frequency of themes within each school
school_relative_frequencies <- content_with_schools %>%
  group_by(schoolId, grade, theme) %>%         # Group by school ID, grade, and theme
  summarise(count = n(), .groups = "drop") %>%  # Count occurrences of themes per school
  group_by(schoolId, grade) %>%               # Group by school ID and grade
  mutate(relative_frequency = count / sum(count)) %>%  # Compute relative frequency within the school
  ungroup()                                   # Remove grouping to allow further manipulation

# Step 2: Calculate the relative frequency of schools with a given theme present for each grade
relative_school_presence <- school_theme_presence %>%
  group_by(grade, theme_en) %>%                      # Group by grade and theme
  summarise(
    schools_with_theme = sum(theme_present),         # Sum of 1's gives the number of schools with the theme
    .groups = "drop"                                  # Drop grouping for clarity
  ) %>%
  mutate(
    relative_school_frequency = schools_with_theme / total_schools   # Calculate relative frequency of schools with the theme
  )
# Step 3: Reshape data for contingency table format (if needed for further analysis)
contingency_table_themes <- relative_school_presence %>%
  tidyr::pivot_wider(names_from = theme, values_from = mean_relative_frequency, values_fill = 0)

# Step 4: Order themes for plotting
relative_school_presence$theme <- factor(relative_school_presence$theme_en, levels = english_themes)

# Step 5: Create a heatmap of relative frequencies
# Improved plot for academic paper

# Step 5: Create a heatmap of relative frequencies for schools having themes present
relative_school_presence_plot <- ggplot(relative_school_presence, aes(x = factor(grade), y = theme_en, fill = relative_school_frequency)) +
  geom_tile(color = "white") +                                      # Add tiles for the heatmap
  geom_text(aes(label = scales::percent(relative_school_frequency, accuracy = 0.1)), # Add percentage text
            color = "black", size = 3.5, fontface = "italic") +     # Use larger text for better legibility
  scale_fill_gradient(low = "white", high = "steelblue", na.value = "grey", 
                      labels = scales::label_percent(accuracy = 0.1)) +  # Format legend as percentages
  labs(
    title = "Relative Frequency of Schools\nwith themes Present Across Educational Grades",  # More formal title
    x = "Grade",  # More formal axis label for x-axis
    y = "Historical theme (English)",  # More formal axis label for y-axis
    fill = "Relative Frequency of Schools (%)"  # Label for the fill legend
  ) +
  theme_bw() +                                                        # A cleaner background for professional look
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 12),      # Adjust x-axis text for readability
    axis.text.y = element_text(size = 12),                              # Increase y-axis text size for clarity
    axis.title.x = element_text(size = 14, face = "bold"),             # Bold title for x-axis
    axis.title.y = element_text(size = 14, face = "bold"),             # Bold title for y-axis
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),  # Bold and centered plot title
    legend.title = element_text(size = 12, face = "bold"),             # Bold legend title
    legend.text = element_text(size = 11),                             # Adjust legend text size
    panel.grid.major = element_line(color = "grey", size = 0.25),      # Lighter gridlines for readability
    panel.grid.minor = element_blank(),                                # Remove minor gridlines for a cleaner look
    legend.position = "right",                                         # Place legend to the right for more space
    legend.key.size = unit(1, "cm")                                    # Adjust legend key size
  ) +
  scale_y_discrete(labels = function(x) stringr::str_trunc(x, 30, side = "right")) + # Truncate theme labels
  theme(legend.position = "bottom")                                      # Keep the legend visible for clarity


# Show plot
relative_school_presence_plot

ggsave(
  filename = "themes_school_presence_heatmap_sorted.pdf",  # Output file name
  plot = relative_school_presence_plot,                          # Use the last generated plot
  device = "pdf",                              # Save as PDF
  width = 11.69,                                # A4 width in inches
  height = 8.27,                              # A4 height in inches
  units = "in"                                 # Specify units as inches
)
