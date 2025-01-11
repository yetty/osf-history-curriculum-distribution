library(ggplot2)
library(dplyr)

create_cluster_plot <- function(data, pca_data, num_clusters, selected_rocnik) {
  # Perform K-means clustering
  set.seed(42)  # For reproducibility
  kmeans_result <- kmeans(pca_data, centers = num_clusters, nstart = 25)
  
  # Add cluster labels to the original data
  data$cluster <- kmeans_result$cluster
  
  # Map numeric clusters to letters
  cluster_labels <- setNames(LETTERS[1:length(unique(data$cluster))], sort(unique(data$cluster)))
  data$cluster <- factor(data$cluster, levels = names(cluster_labels), labels = cluster_labels)
  
  # Calculate the top 10 most frequent `ucivo` values for each cluster
  top_ucivo <- data %>%
    group_by(cluster) %>%
    count(ucivo) %>%
    arrange(desc(n)) %>%
    slice_head(n = 10) %>%
    ungroup()

  print(top_ucivo)
  
  # Merge `top_ucivo` with cluster centers for annotation
  top_ucivo_annot <- top_ucivo %>%
    left_join(
      as.data.frame(kmeans_result$centers) %>% mutate(cluster = LETTERS[1:num_clusters]),
      by = "cluster"
    )
  
  # Create the plot
  plot <- ggplot(data, aes(x = pca_data[,1], y = pca_data[,2], color = as.factor(cluster))) +
    geom_point(alpha = 0.7, size = 2) +
    geom_text(
      data = top_ucivo_annot,
      aes(x = PC1, y = PC2, label = ucivo, color = cluster),
      inherit.aes = FALSE,
      size = 3, hjust = 0, nudge_x = 0.5
    ) +
    labs(
      title = paste("K-Means Clustering on PCA-Reduced Embeddings for rocnik", selected_rocnik),
      subtitle = "Principal Components (PC1 and PC2) from OpenAI Embeddings",
      x = "Principal Component 1 (PC1)",
      y = "Principal Component 2 (PC2)",
      color = "Cluster"
    ) +
    theme_bw(base_size = 12) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
      plot.subtitle = element_text(hjust = 0.5, face = "italic", size = 12),
      axis.title = element_text(face = "bold", size = 12),
      axis.text = element_text(color = "black", size = 10),
      legend.title = element_text(face = "bold", size = 12),
      legend.text = element_text(size = 10),
      panel.grid.major = element_line(color = "gray", size = 0.2),
      panel.grid.minor = element_blank()
    )
  
  # Save the plot
  ggsave(paste0("kmeans_clustering_rocnik_", selected_rocnik, ".png"), plot, width = 8, height = 6, device = "png")
  ggsave(paste0("kmeans_clustering_rocnik_", selected_rocnik, ".pdf"), plot, width = 8, height = 6, device = "pdf")
  
  return(plot)
}

# Example usage:
# Assuming `data` contains the dataset and `ucivo` is a column
# create_cluster_plot(data, num_clusters = 4, selected_rocnik = 6)


get_representative_examples <- function(data, pca_data, kmeans_result) {
  # Initialize a list to store representative examples
  representative_examples <- list()
  
  # Iterate over each cluster
  for (cluster in unique(kmeans_result$cluster)) {
    # Get the centroid of the current cluster
    centroid <- kmeans_result$centers[cluster, ]
    
    # Subset data for the current cluster
    cluster_indices <- which(kmeans_result$cluster == cluster)
    cluster_pca_data <- pca_data[cluster_indices, ]
    
    # Calculate Euclidean distances to the centroid
    distances <- apply(cluster_pca_data, 1, function(x) sqrt(sum((x - centroid)^2)))
    
    # Find the index of the closest point
    closest_index <- cluster_indices[which.min(distances)]
    
    # Retrieve the corresponding 'ucivo' example
    representative_examples[[as.character(cluster)]] <- data$ucivo[closest_index]
  }
  
  return(representative_examples)
}

# Example usage:
# Assuming 'data' is your dataset and 'rocnik' contains the desired values
# create_cluster_plot(data, num_clusters = 4, selected_rocnik = 6)



 # Ensure 'rocnik' is a factor
 data$rocnik <- as.factor(data$rocnik)
  
 # Filter for the selected 'rocnik'
 rocnik6 <- data %>% filter(rocnik == 6)
 
 # Remove duplicate rows based on 'rocnik' and 'ucivo_vector'
 rocnik6 <- rocnik6[!duplicated(data[c("rocnik", "ucivo_vector")]), ]
 
 # Flatten the list of vectors into a matrix
 embedding_matrix <- do.call(rbind, rocnik6$ucivo_vector)
 
 # Perform PCA
 pca_result <- prcomp(embedding_matrix, center = TRUE, scale. = TRUE)
 pca_data <- pca_result$x[, 1:50]

 set.seed(42)  # For reproducibility
 kmeans_result <- kmeans(pca_data, centers = 3, nstart = 25)

 rocnik6$cluster <- kmeans_result$cluster

top_ucivo <- data %>%
  group_by(rocnik) %>%
  count(ucivo) %>%
  arrange(desc(n))

hist(top_ucivo$n)

print(top_ucivo)

 print(get_representative_examples(rocnik6, pca_data, kmeans_result))


 create_cluster_plot(rocnik6, pca_data, num_clusters = 3, selected_rocnik = 6)

