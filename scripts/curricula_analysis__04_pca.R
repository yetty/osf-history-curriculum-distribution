# Load necessary libraries for data manipulation, visualization, and text analysis
library(ggplot2)
library(cluster)
library(Rtsne)
library(clusterSim)
library(tm)
library(quanteda)
library(quanteda.textstats)
library(dplyr)
library(stopwords)

# Load the datasets containing vectors and school information
load("data/other_content_with_vectors.RData")
load("data/content_with_schools.RData") 

# Calculate the total number of unique schools with non-missing content
total_schools <- content_with_schools %>%
  filter(!is.na(content)) %>%
  summarise(total = n_distinct(schoolId)) %>%
  pull(total)

# Ensure the output directory exists for saving results
output_dir <- "outcomes/analysis"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Set a seed for reproducibility of clustering results
set.seed(42)

# Loop over specified grades and cluster numbers
for (grade in 6:9) {  # Loop over different grades
  for (k in 3:7) {    # Loop over different numbers of clusters

    # Filter the data for the current grade
    content_with_vectors_filtered <- content_with_vectors %>% filter(grade == !!grade)

    # Extract vectors and convert them into a matrix
    vector_list <- content_with_vectors_filtered$vector
    vector_matrix <- do.call(rbind, vector_list)

    # Remove duplicate vectors to ensure unique data points
    vector_matrix_unique <- unique(vector_matrix)

    # Perform k-means clustering on the unique vectors
    kmeans_result <- kmeans(vector_matrix_unique, centers = k, nstart = 25)

    # Perform t-SNE for dimensionality reduction and visualization
    tsne_result <- Rtsne(vector_matrix_unique, dims = 2, perplexity = 30, verbose = TRUE, max_iter = 1000)

    # Prepare the t-SNE data with cluster assignments for visualization
    tsne_data <- data.frame(tsne_result$Y)
    colnames(tsne_data) <- c("Dim1", "Dim2")
    tsne_data$cluster <- as.factor(kmeans_result$cluster)

    # Create a t-SNE plot with clusters colored differently
    tsne_plot <- ggplot(tsne_data, aes(x = Dim1, y = Dim2, color = cluster)) +
      geom_point(size = 2, alpha = 0.7) +
      scale_color_discrete(name = "Cluster") +
      labs(
        title = paste0("Grade ", grade, " t-SNE Visualization"),
        subtitle = paste0("Cluster Analysis of History Content Topics with K-means (k = ", k, ")"),
        x = "t-SNE Dimension 1",
        y = "t-SNE Dimension 2"
      ) +
      theme_minimal(base_size = 14) +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5),
        legend.position = "right"
      )

    # Display the plot
    print(tsne_plot)

    # Save the plot to the output directory in A5 landscape format
    plot_filename <- file.path(output_dir, paste0("tsne_grade_", grade, "_k_", k, ".png"))
    ggsave(plot_filename, tsne_plot, width = 8.27, height = 5.83, units = "in")

    # Map cluster assignments back to the original data
    unique_to_original <- match(data.frame(t(vector_matrix)), data.frame(t(vector_matrix_unique)))
    content_with_vectors_filtered$cluster <- kmeans_result$cluster[unique_to_original]

    # Calculate the number and percentage of unique schools in each cluster
    school_cluster_counts <- content_with_vectors_filtered %>%
      group_by(cluster) %>%
      summarise(unique_schools = n_distinct(schoolId))

    school_cluster_percentages <- school_cluster_counts %>%
      mutate(percentage = (unique_schools / total_schools) * 100)

    # Print the percentage of schools in each cluster to the console
    for (i in 1:k) {
      cluster_percentage <- school_cluster_percentages$percentage[school_cluster_percentages$cluster == i]
      print(paste("Cluster", i, "Percentage of schools:", round(cluster_percentage, 2), "%"))
    }

    # Save the school percentages to a CSV file
    school_percentage_file <- file.path(output_dir, paste0("school_cluster_percentages_grade_", grade, "_k_", k, ".csv"))
    write.csv(school_cluster_percentages, school_percentage_file, row.names = FALSE)

    # Analyze top collocations for each cluster
    for (i in 1:k) {
      cluster_data <- subset(content_with_vectors_filtered, cluster == i)
      content_text <- tolower(paste(cluster_data$content, collapse = " "))
      
      # Tokenize the text and remove stopwords
      tokens <- tokens(content_text, remove_punct = TRUE, remove_numbers = TRUE)
      tokens <- tokens_remove(tokens, stopwords::stopwords("cs", source = "stopwords-iso"))
      tokens_ngrams <- tokens_ngrams(tokens, n = 2:5)
      
      # Create a document-feature matrix (DFM) and extract top n-grams
      dfm <- dfm(tokens_ngrams)
      freq <- textstat_frequency(dfm, n = 10)
      freq$percentage <- (freq$frequency / total_schools) * 100
      
      # Save the top collocations to a CSV file
      collocations_filename <- file.path(output_dir, paste0("collocations_grade_", grade, "_k_", k, "_cluster_", i, ".csv"))
      write.csv(freq, collocations_filename, row.names = FALSE)
      
      # Print a summary of top collocations to the console
      print(paste("Cluster", i, "Top Collocations:"))
      print(freq)
    }
  }
}