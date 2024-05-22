library(cluster)
library(haven)
library(dplyr)
set.seed(1)

####### Calcular distancia within groups y dejar la distancia en el dataframe como la suma de las tres distancias
### Entender bien cómo se calcula la matriz de dist. A qué corresponde cada uno de los elementos de la matriz

covar_data <- read_dta('C:/Users/Pablo Uribe/Dropbox/Arlen/4. Pablo/01 Data/matrix.dta') |> 
  rename(ID = strataID)

# # Define the vector of seven numbers
 IDs <- as.vector(covar_data$ID)
#IDs <- c(1, 2, 3, 4, 5, 6, 7)
# 
# # Simulate covariate data for each ID
# covar_data <- data.frame(ID = IDs,
#                          covar1 = abs(rnorm(length(IDs))),
#                          covar2 = abs(rnorm(length(IDs))),
#                          covar3 = abs(rnorm(length(IDs))),
#                          covar4 = abs(rnorm(length(IDs))),
#                          covar5 = abs(rnorm(length(IDs))),
#                          covar6 = abs(rnorm(length(IDs))),
#                          covar7 = abs(rnorm(length(IDs))))

# Generate all possible combinations of IDs
combinations <- combn(IDs, 2)

# Initialize an empty list to store the results
all_combinations <- list()

# Iterate over combinations of the first two groups
for (i in 1:ncol(combinations)) {
  group1 <- combinations[, i]
  remaining <- setdiff(IDs, group1)
  
  # Generate combinations of the second group
  combinations2 <- combn(remaining, 2)
  
  # Iterate over combinations of the third group
  for (j in 1:ncol(combinations2)) {
    
    group2 <- combinations2[, j]
    group3 <- setdiff(remaining, group2)
    
    # Store the combination of groups
    all_combinations <- c(all_combinations, list(data.frame(Group1 = paste(group1, collapse = ","),
                                                            Group2 = paste(group2, collapse = ","),
                                                            Group3 = paste(group3, collapse = ","))))
  }
}

# Convert the list to a dataframe
combinations_df <- do.call(rbind, all_combinations)


# Function to calculate Euclidean distance considering all covariates
calculate_distance <- function(group1, group2, group3, covar_data) {
  
  # Extract covariate values for each group
  covar_group1 <- covar_data[covar_data$ID %in% group1, ]
  covar_group2 <- covar_data[covar_data$ID %in% group2, ]
  covar_group3 <- covar_data[covar_data$ID %in% group3, ]

  
  # Calculate Euclidean distance for each covariate
  distances <- numeric()
    
  # Combine covariate values into a matrix
  covar_matrix <- rbind(covar_group1, covar_group2, covar_group3)
  
  # Calculate pairwise Euclidean distances between strata A vs B for all covars. The -1 omits the ID column
  distance1 <- dist(covar_group1[-1])
  distance2 <- dist(covar_group2[-1])
  distance3 <- dist(covar_group3[-1])
  
  # Create a vector from all within-group distances
  pairwise_distances <- c(distance1,distance2,distance3)
  
  # Sum all within-group distances
  overall_distance <- sum(pairwise_distances, na.rm = T)
  
  # Return the overall Euclidean distance
  return(overall_distance)
}


# Initialize an empty vector to store distances
final_distances <- numeric(nrow(combinations_df))

# Iterate over combinations and calculate distances
for (i in 1:nrow(combinations_df)) {
  
  final_distances[i] <- calculate_distance(
    as.numeric(unlist(strsplit(combinations_df$Group1[i], ","))),
    as.numeric(unlist(strsplit(combinations_df$Group2[i], ","))),
    as.numeric(unlist(strsplit(combinations_df$Group3[i], ","))),
    covar_data
  )
  
}

# Add distances to the dataframe
combinations_df$Distance <- final_distances

# Find the combination with the lowest distance
best_combination <- combinations_df[which.min(combinations_df$Distance), ]

# Print the best combination
print(best_combination)

