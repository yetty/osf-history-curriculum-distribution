# Load necessary libraries
install.packages("tidyverse")
install.packages("Rtsne")
library(tidyverse)
library(ggplot2)
library(Rtsne)  # For t-SNE visualization
library(dplyr)



# Path to your CSV file
csv_file <- "data/ucivo.embeddings.csv"

# Read the CSV file
data_full <- read.csv(csv_file, stringsAsFactors = FALSE)

data <- head(data_full, 1000)
# data <- data_full

data <- data %>%
  filter(rocnik %in% c(6, 7, 8, 9))

# Parse the ucivo_vector column for the first 10 items
data$ucivo_vector <- lapply(data$ucivo_vector, function(x) {
  # Remove square brackets and extra spaces using a correct escape
  cleaned_x <- gsub("\\[|\\]", "", x)  # Remove brackets correctly
  
  # Remove any unwanted spaces
  cleaned_x <- gsub("\\s", "", cleaned_x)  # Remove spaces

  # Split by commas and convert to numeric
  numeric_values <- as.numeric(strsplit(cleaned_x, ",")[[1]])

  # Check for any NA values and print a warning if they appear
  if (any(is.na(numeric_values))) {
    warning("NA values detected in the vector: ", x)
  }

  return(numeric_values)
})

data$rocnik <- as.factor(data$rocnik)

data <- data[!duplicated(data[c("rocnik", "ucivo_vector")]), ]

# Assuming 'data' is your dataset and 'ucivo_vector' is the column with embeddings
# Flatten the list of vectors into a matrix
embedding_matrix <- do.call(rbind, data$ucivo_vector)
# Remove duplicate rows from the embedding matrix
# embedding_matrix <- embedding_matrix[!duplicated(embedding_matrix), ]

pca_result <- prcomp(embedding_matrix, center = TRUE, scale. = TRUE)
summary(pca_result)
pca_data <- pca_result$x[, 1:50]


# Perform K-means clustering (set k as desired number of clusters)
set.seed(42)  # For reproducibility
k <- 5  # Example: 3 clusters
kmeans_result <- kmeans(pca_data, centers = k, nstart = 25)

# Add cluster labels to the original data
data$cluster <- kmeans_result$cluster

# Dimensionality reduction using t-SNE
set.seed(42)
tsne_result <- Rtsne(embedding_matrix, dims = 2, perplexity = 30, verbose = TRUE)

# Create a data frame for plotting
plot_data <- data.frame(
  x = tsne_result$Y[, 1],
  y = tsne_result$Y[, 2],
  cluster = as.factor(data$cluster)
)

ggplot(data, aes(x = pca_data[,1], y = pca_data[,2], color = as.factor(cluster))) +
  geom_point() +
  labs(title = "K-means Clustering on PCA-reduced Data", x = "PC1", y = "PC2") +
  theme_minimal()

# Plot the clusters
ggplot(plot_data, aes(x = x, y = y, color = cluster)) +
  geom_point(size = 2, alpha = 0.7) +
  labs(title = "t-SNE Visualization of K-means Clusters",
       x = "t-SNE Dimension 1",
       y = "t-SNE Dimension 2") +
  theme_minimal() +
  scale_color_brewer(palette = "Set3")
