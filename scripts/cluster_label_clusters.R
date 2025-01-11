install.packages("textTinyR")

# Load necessary libraries
library(tidyverse)  # For data manipulation and visualization
library(cluster)    # For clustering algorithms
library(factoextra) # For visualization of clustering
library(textTinyR)  # For cosine similarity if needed
library(tm)         # For text preprocessing (optional)

# Assuming your data is in a data frame called `data`
# Columns: `ucivo_vector` (list-column of vectors), `ucivo` (content topics)

# Convert vectors to matrix for clustering
vector_matrix <- do.call(rbind, data$ucivo_vector)

# Step 1: Normalize the vectors (important for clustering)
vector_matrix <- scale(vector_matrix)

# Step 2: Determine the optimal number of clusters (using Elbow method)
fviz_nbclust(vector_matrix, kmeans, method = "wss") +
  ggtitle("Elbow Method to Determine Optimal Clusters")

# Step 3: Apply K-Means clustering
set.seed(42) # For reproducibility
optimal_k <- 5 # Replace with the number of clusters determined from the Elbow plot
kmeans_result <- kmeans(vector_matrix, centers = optimal_k, nstart = 25)

# Add cluster labels back to the data
data$cluster <- kmeans_result$cluster

# Step 4: Analyze clusters and assign labels
# Create a data frame for topics and their clusters
clustered_topics <- data %>%
  group_by(cluster) %>%
  summarise(
    topics = paste(ucivo, collapse = " | "), # Concatenate topics in each cluster
    count = n()
  )

# (Optional) Extract keywords from clusters using term frequency
extract_keywords <- function(text) {
  text_corpus <- Corpus(VectorSource(text))
  text_corpus <- tm_map(text_corpus, content_transformer(tolower))
  text_corpus <- tm_map(text_corpus, removePunctuation)
  text_corpus <- tm_map(text_corpus, removeNumbers)
  text_corpus <- tm_map(text_corpus, removeWords, stopwords("en"))
  
  term_doc_matrix <- TermDocumentMatrix(text_corpus)
  term_freq <- rowSums(as.matrix(term_doc_matrix))
  sort(term_freq, decreasing = TRUE)
}

# Get keywords for each cluster
clustered_topics <- clustered_topics %>%
  rowwise() %>%
  mutate(keywords = list(names(extract_keywords(topics))[1:5])) # Top 5 keywords

# Step 5: Visualize clusters
library(ggplot2)
library(Rtsne)

# Use t-SNE for dimensionality reduction
tsne_result <- Rtsne(vector_matrix, dims = 2, perplexity = 30, verbose = TRUE)

# Create a data frame for visualization
tsne_data <- data.frame(
  X = tsne_result$Y[, 1],
  Y = tsne_result$Y[, 2],
  Cluster = as.factor(data$cluster),
  Topic = data$ucivo
)

# Plot the t-SNE results with cluster labels
ggplot(tsne_data, aes(x = X, y = Y, color = Cluster, label = Topic)) +
  geom_point(alpha = 0.7) +
  geom_text(check_overlap = TRUE, size = 3, vjust = 1.5) +
  labs(title = "t-SNE Visualization of Topic Clusters", color = "Cluster") +
  theme_minimal()

# Step 6: Save results
# Save clusters with labels
write.csv(data, "clustered_topics.csv", row.names = FALSE)

# Save cluster summaries
write.csv(clustered_topics, "cluster_summaries.csv", row.names = FALSE)

