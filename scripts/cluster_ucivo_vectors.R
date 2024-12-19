# Load necessary libraries
install.packages("tidyverse")
install.packages("Rtsne")
install.packages("factoextra")  # for visualizing k-means results
install.packages("mclust")
library(factoextra)
library(tidyverse)
library(ggplot2)
library(Rtsne)  # For t-SNE visualization
library(dplyr)
library(cluster)
library(mclust)


load("data/ucivo.embeddings.RData")

data$rocnik <- as.factor(data$rocnik)

data <- data %>%
  filter(rocnik %in% c(6, 7, 8, 9))


data <- data[!duplicated(data[c("rocnik", "ucivo_vector")]), ]

# Assuming 'data' is your dataset and 'ucivo_vector' is the column with embeddings
# Flatten the list of vectors into a matrix
embedding_matrix <- do.call(rbind, data$ucivo_vector)
# Remove duplicate rows from the embedding matrix
# embedding_matrix <- embedding_matrix[!duplicated(embedding_matrix), ]

pca_result <- prcomp(embedding_matrix, center = TRUE, scale. = TRUE)
summary(pca_result)
save(pca_result, file="data/ucivo.pca.RData")

load("data/ucivo.pca.RData")
pca_data <- pca_result$x[, 1:50]

# Perform K-means clustering (set k as desired number of clusters)
set.seed(42)  # For reproducibility
k <- length(unique(data$rocnik)) # Example: 3 clusters
kmeans_result <- kmeans(pca_data, centers = k, nstart = 25)

# Add cluster labels to the original data
data$cluster <- kmeans_result$cluster
data$cluster <- factor(data$cluster, levels = c(4, 2, 1, 3))
# Map numeric clusters to letters
cluster_labels <- setNames(LETTERS[1:length(unique(data$cluster))], sort(unique(data$cluster)))

# Rename clusters in the data
data$cluster <- factor(data$cluster, levels = names(cluster_labels), labels = cluster_labels)



ggplot(data, aes(x = pca_data[,1], y = pca_data[,2], color = as.factor(cluster))) +
  geom_point(alpha = 0.7, size = 2) +
  labs(
    title = "K-Means Clustering on PCA-Reduced History Topic Embeddings",
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


ggsave("kmeans_clustering.png", width = 8, height = 6, device = "png")

ggsave("kmeans_clustering.pdf", width = 8, height = 6, device = "pdf")


# Map numeric clusters to letters
cluster_labels <- setNames(LETTERS[1:length(unique(data$cluster))], sort(unique(data$cluster)))

# Rename clusters in the data
data$cluster <- factor(data$cluster, levels = names(cluster_labels), labels = cluster_labels)


# Create a contingency table comparing clusters with grades (rocnik)
contingency_table <- table(data$cluster, data$rocnik)
# Filter out columns where all values are zero
contingency_table <- contingency_table[, colSums(contingency_table) > 0]

# Print the filtered contingency table
print(contingency_table)

# Print contingency table
contingency_df <- as.data.frame(as.table(contingency_table))
colnames(contingency_df) <- c("Cluster", "Grade", "Count")
contingency_df <- contingency_df %>%
  group_by(Cluster) %>%
  mutate(Percentage = Count / sum(Count) * 100) %>%
  ungroup()
print(contingency_df)
# Plot a heatmap of the contingency matrix
ggplot(contingency_df, aes(x = Grade, y = Cluster, fill = Percentage)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(
    title = "Alignment of Grade Levels with K-Means Clusters in History Content Topics",
    subtitle = "Proportional Representation of Grade Levels (Rocnik) in Each K-Means Cluster",
    x = "Grade Level (Rocnik)",
    y = "K-Means Cluster",
    fill = "Percentage of Topics"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
    plot.subtitle = element_text(hjust = 0.5, face = "italic", size = 12),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(color = "black", size = 10),
    legend.title = element_text(face = "bold", size = 12),
    legend.text = element_text(size = 10)
  )

ggsave("alingment_of_grade_and_kmeans.eps", width = 8, height = 6, device = "eps")
