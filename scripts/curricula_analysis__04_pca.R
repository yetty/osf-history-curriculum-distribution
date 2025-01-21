library(ggplot2)
library(cluster)
library(Rtsne)
library(clusterSim)
library(tm)
library(RWeka)

# Load the data
load("data/other_content_with_vectors.RData")

grade <- 8
k <- 4

content_with_vectors <- content_with_vectors %>% filter(grade==grade)

# Extract the list of vectors from the 'vector' column
vector_list <- content_with_vectors$vector

# Convert the list of vectors into a matrix
# Assuming each element in the list is a numeric vector of the same length
vector_matrix <- do.call(rbind, vector_list)

# Remove duplicate rows
vector_matrix_unique <- unique(vector_matrix)

# Set a seed for reproducibility
set.seed(42)

# Perform k-means clustering
# Determine the number of clusters (k)
kmeans_result <- kmeans(vector_matrix_unique, centers = k, nstart = 25)

# Perform t-SNE
tsne_result <- Rtsne(vector_matrix_unique, dims = 2, perplexity = 30, verbose = TRUE, max_iter = 1000)

# Prepare the t-SNE data with cluster assignments
tsne_data <- data.frame(tsne_result$Y)
colnames(tsne_data) <- c("Dim1", "Dim2")
tsne_data$cluster <- as.factor(kmeans_result$cluster)

# Visualize the t-SNE results with cluster colors
ggplot(tsne_data, aes(x = Dim1, y = Dim2, color = cluster)) +
  geom_point() +
  labs(title = "t-SNE Visualization with K-means Clustering", x = "Dimension 1", y = "Dimension 2") +
  theme_minimal()


unique_to_original <- match(data.frame(t(vector_matrix)), data.frame(t(vector_matrix_unique)))
content_with_vectors$cluster <- kmeans_result$cluster[unique_to_original]

# Define a tokenizer function for n-grams (e.g., bigrams for collocations)
BigramTokenizer <- function(x) {
  NGramTokenizer(x, Weka_control(min = 2, max = 2)) # min=2 and max=2 for bigrams
}

for (i in 1:k) {
  cluster_data <- subset(content_with_vectors, cluster == i)
  corpus <- Corpus(VectorSource(cluster_data$content))
  
  # Create Document-Term Matrix using the BigramTokenizer
  dtm <- DocumentTermMatrix(corpus, control = list(tokenize = BigramTokenizer))
  
  # Calculate frequencies of n-grams
  freq <- colSums(as.matrix(dtm))
  
  print(paste("Cluster", i, "Top Collocations:"))
  print(sort(freq, decreasing = TRUE)[1:10])
}