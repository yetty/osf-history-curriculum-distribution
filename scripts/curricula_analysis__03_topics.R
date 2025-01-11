library(dplyr)       # For data manipulation
library(tidyr)       # For reshaping data (pivot_wider)
library(ggplot2)     # For visualization
library(stringr)     # For string truncation
library(scales)      # For percentage formatting in plots
library(writexl)

# Load the dataset
load("data/content_with_schools.RData")  # Load pre-processed dataset containing content with school information

total_schools <- content_with_schools %>%
  filter(!is.na(content)) %>%
  summarise(total = n_distinct(schoolId)) %>%
  pull(total)

other_content <- content_with_schools %>% filter(topic_en == "other" | topic_en == "other historical topic") %>% group_by(content)
write_xlsx(as.data.frame(other_content), "data/other_content.xlsx")

# Step 1: Check if a topic is present in a school (TRUE/FALSE per school-grade-topic combination)
school_topic_presence <- content_with_schools %>%
  group_by(schoolId, grade, topic_en) %>%         # Group by school ID, grade, and topic
  summarise(count = n(), .groups = "drop") %>%  # Count occurrences of topics per school
  mutate(topic_present = ifelse(count > 0, 1, 0)) %>%  # 1 if topic is present in the school, else 0
  ungroup()

# Step 2: Calculate the relative frequency of schools with a given topic present for each grade
relative_school_presence <- school_topic_presence %>%
  group_by(grade, topic_en) %>%                      # Group by grade and topic
  summarise(
    schools_with_topic = sum(topic_present),         # Sum of 1's gives the number of schools with the topic
    .groups = "drop"                                  # Drop grouping for clarity
  ) %>%
  mutate(
    relative_school_frequency = schools_with_topic / total_schools   # Calculate relative frequency of schools with the topic
  )

# Step 3: Reshape data for contingency table format (if needed for further analysis)
contingency_table_topics <- relative_school_presence %>%
  tidyr::pivot_wider(names_from = topic_en, values_from = relative_school_frequency, values_fill = 0)

# Step 4: Merge the topics with their order values
topics_with_order <- content_with_schools %>%
  distinct(topic_en, order) %>%  # Get distinct topic_en and order pairs
  arrange(order)  # Arrange them by order

# Ensure topic_en in the plot is ordered according to `order`
relative_school_presence$topic_en <- factor(
  relative_school_presence$topic_en,
  levels = topics_with_order$topic_en  # Use the correct order for topics
)

# Step 5: Create a heatmap of relative frequencies for schools having topics present
relative_school_presence_plot <- ggplot(relative_school_presence, aes(x = factor(grade), y = topic_en, fill = relative_school_frequency)) +
  geom_tile(color = "white") +                                      # Add tiles for the heatmap
  geom_text(aes(label = scales::percent(relative_school_frequency, accuracy = 0.1)), # Add percentage text
            color = "black", size = 3.5, fontface = "italic") +     # Use larger text for better legibility
  scale_fill_gradient(low = "white", high = "steelblue", na.value = "grey", 
                      labels = scales::label_percent(accuracy = 0.1)) +  # Format legend as percentages
  labs(
    title = "Relative Frequency of Schools\nwith Topics Present Across Educational Grades",  # More formal title
    x = "Grade",  # More formal axis label for x-axis
    y = "Historical Topic (English)",  # More formal axis label for y-axis
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
  scale_y_discrete(labels = function(x) stringr::str_trunc(x, 40, side = "right")) + # Truncate topic labels
  theme(legend.position = "bottom")                                      # Keep the legend visible for clarity

# Show plot
relative_school_presence_plot

# Save the plot as PDF
ggsave(
  filename = "topics_school_presence_heatmap_sorted.pdf",  # Output file name
  plot = relative_school_presence_plot,                          # Use the last generated plot
  device = "pdf",                              # Save as PDF
  width = 11.69,                                # A4 width in inches
  height = 8.27,                              # A4 height in inches
  units = "in"                                 # Specify units as inches
)
