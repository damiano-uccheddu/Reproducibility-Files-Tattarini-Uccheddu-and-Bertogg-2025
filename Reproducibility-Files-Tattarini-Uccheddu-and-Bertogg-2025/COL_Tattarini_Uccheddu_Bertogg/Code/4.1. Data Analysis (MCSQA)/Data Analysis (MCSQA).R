# Sequence and cluster analysis were performed in R (Version R-4.5.1) for Windows using RStudio Desktop (Version: 2025.05.1+513)


# *-----------------------------------------------------------------------------------------------* 
# Load data and libraries 
# *-----------------------------------------------------------------------------------------------* 

# Install RTools if necessary (https://cran.rstudio.com/bin/windows/Rtools/)

# Set the working directory 
setwd("A:/Encrypted datasets/Derived/COL_Tattarini_Uccheddu_Bertogg/W_All")

# Time 
Sys.time() # Check the time 

# Libraries 
install.packages("ggplot2")				# version "3.5.2"
install.packages("logr")				# version "1.3.9" 
install.packages("readstata13")			# version "0.11.0"
install.packages("TraMineR")			# version "2.2.12"
install.packages("WeightedCluster")		# version "1.8.1"

library("ggplot2")						# version "3.5.2" 
library("logr")							# version "1.3.9" 
library("readstata13")					# version "0.11.0"
library("TraMineR")						# version "2.2.12"
library("WeightedCluster")				# version "1.8.1"

# Check the versions of the packages
pkgs <- c("logr", "readstata13", "TraMineR", "WeightedCluster", "ggplot2")
installed <- installed.packages()
versions <- installed[pkgs, "Version", drop = FALSE]
print(versions)

# Expected versions for replicability: 
	expected_versions <- c(ggplot2 = "3.5.2", logr = "1.3.9", readstata13 = "0.11.0", TraMineR = "2.2.12", WeightedCluster = "1.8.1")

	for (pkg in names(expected_versions)) { # Check the packages 
	  installed_ver <- as.character(packageVersion(pkg))
	  if (installed_ver != expected_versions[pkg]) {
	    stop(sprintf("Package %s version mismatch: expected %s but got %s", pkg, expected_versions[pkg], installed_ver))
	  }
	}



# * ======================================================================= * 
# Log file
# * ======================================================================= * 

log_file <- "C:/Users/damiano/Dropbox/_Projects/COL_Tattarini_Uccheddu_Bertogg/Data analysis/Output folder - Common/Log files/sequence_analysis.log"
lf <- log_open(log_file)


# *-----------------------------------------------------------------------------------------------* 
# Create a function to perform the sequence analysis
# *-----------------------------------------------------------------------------------------------* 

perform_sequence_analysis <- function(dataset_suffix) {


	# Common parameters for plot readability
	plot_cex <- 1.5    # For axis, labels, main title, and sub-title
	legend_cex <- 50   # For the legend text


		# *-----------------------------------------------------------------------------------------------* 
		# Sequence analysis for women
		# *-----------------------------------------------------------------------------------------------* 

		# Data 
		Family_women     		<- read.dta13(paste0("A:/Encrypted datasets/Derived/COL_Tattarini_Uccheddu_Bertogg/W_All/SHARE_for_SA_Women_Family", dataset_suffix, ".dta"))
		Employment_women  		<- read.dta13(paste0("A:/Encrypted datasets/Derived/COL_Tattarini_Uccheddu_Bertogg/W_All/SHARE_for_SA_Women_Employment", dataset_suffix, ".dta"))

		# Define the sequences (Build sequence objects)
		Family_seq_women		<- seqdef(Family_women,   		2:36, informat = "STS") # "STS" is the wide format
		Employment_seq_women	<- seqdef(Employment_women,  	2:36, informat = "STS")

		# Use transition rates to compute substitution costs on each channel. Dynamic Hamming distance (DHD) 
		mcdist_women <- seqdistmc(channels=list(Family_seq_women, Employment_seq_women), method="DHD")


		# *-----------------------------------------------------------------------------------------------* 
		# First step: Choose the best clustering method 
		# *-----------------------------------------------------------------------------------------------* 

		# Automatic comparison of clustering methods 
		allClust_women <- wcCmpCluster(mcdist_women, maxcluster=20, method=c("average", "pam", "beta.flexible", "ward.D2", "diana", "agnes"), pam.combine=FALSE)

		summary(allClust_women, max.rank = 20)

		# Plot PBC, RHC and ASW
		pdf(paste0('allClust_women_A', dataset_suffix, '.pdf'), width = 20, height = 20)
		par(cex.axis = plot_cex, cex.lab = plot_cex, cex.main = plot_cex, cex.sub = plot_cex)  # Adjust font sizes		
		plot(allClust_women, stat=c("ASW", "CH", "HC", "HGSD", "PBC"), norm="zscore", lwd=7) # Increased line width
		dev.off()

		# Plot PBC, RHC and ASW grouped by cluster method
		pdf(paste0('allClust_women_B', dataset_suffix, '.pdf'), width = 20, height = 20)
		par(cex.axis = plot_cex, cex.lab = plot_cex, cex.main = plot_cex, cex.sub = plot_cex)  # Adjust font sizes
		plot(allClust_women, group="method", stat=c("ASW", "CH", "HC", "HGSD", "PBC"), norm="zscore", lwd=7) # Increased line width
		dev.off()


		# *-----------------------------------------------------------------------------------------------* 
		# Second step: Cluster analysis, choose the best number of clusters 
		# *-----------------------------------------------------------------------------------------------* 

		# Ward cluster
		wardCluster_women <- hclust(as.dist(mcdist_women), method = "ward.D")

		# Estimate the clustering quality for groupings in 2, 3, ..., ncluster = 20
		wardRange_women <- as.clustrange(wardCluster_women, diss = mcdist_women, ncluster = 20)
		summary(wardRange_women, max.rank = 20)
		Sys.time()

		# Plot ASWw HG PBC HC 
		pdf(paste0('wardRange_women', dataset_suffix, '.pdf'), width = 20, height = 20)
		par(cex.axis = plot_cex, cex.lab = plot_cex, cex.main = plot_cex, cex.sub = plot_cex)  # Adjust font sizes
		plot(wardRange_women, stat=c("ASW", "CH", "HC", "HGSD", "PBC"), norm="zscore", lwd=7) # Increased line width
		dev.off()

		# Perform the cluster analysis using the Ward
		clusterward_women <- agnes(mcdist_women, diss = T, method = "ward")


		# *-----------------------------------------------------------------------------------------------* 
		# *>> Variables for regression analysis 
		# *-----------------------------------------------------------------------------------------------* 

		mergeid <- Family_women[1]

		for (k in 2:20) {
			family_work_women <- cutree(clusterward_women, k = k)
			cluster_women <- data.frame(pid = mergeid, family_work_women)
			cluster_women <- setNames(cluster_women, c("mergeid", paste0("cluster_", k)))
			save.dta13(cluster_women, paste0("A:/Encrypted datasets/Derived/COL_Tattarini_Uccheddu_Bertogg/W_All/cluster_women_", dataset_suffix, k, ".dta"))

			# Create labs factor
			labs <- factor(family_work_women, labels = paste("Cluster", 1:k))

			# Save Family plot
			pdf(paste0('Family_seq_women_', k, dataset_suffix, '.pdf'), width = 20, height = 20)
			par(cex=plot_cex)  # Adjust global text size
			seqdplot(Family_seq_women, group = labs, border = NA, with.legend = TRUE, cex.legend = legend_cex)
			dev.off()

			# Save Employment plot
			pdf(paste0('Employment_seq_women_', k, dataset_suffix, '.pdf'), width = 20, height = 20)
			par(cex=plot_cex)  # Adjust global text size
			seqdplot(Employment_seq_women, group = labs, border = NA, with.legend = TRUE, cex.legend = legend_cex)
			dev.off()
		}




		# *-----------------------------------------------------------------------------------------------* 
		# Sequence analysis for men
		# *-----------------------------------------------------------------------------------------------* 

		# Data 
		Family_men 		<- read.dta13(paste0("A:/Encrypted datasets/Derived/COL_Tattarini_Uccheddu_Bertogg/W_All/SHARE_for_SA_Men_Family", dataset_suffix, ".dta"))
		Employment_men 	<- read.dta13(paste0("A:/Encrypted datasets/Derived/COL_Tattarini_Uccheddu_Bertogg/W_All/SHARE_for_SA_Men_Employment", dataset_suffix, ".dta"))

		# Define the sequences (Build sequence objects)
		Family_seq_men 		<- seqdef(Family_men, 		2:36, informat = "STS") # "STS" is the wide format
		Employment_seq_men 	<- seqdef(Employment_men, 	2:36, informat = "STS")

		# Use transition rates to compute substitution costs on each channel. Dynamic Hamming distance (DHD) 
		mcdist_men <- seqdistmc(channels=list(Family_seq_men, Employment_seq_men), method="DHD")


		# *-----------------------------------------------------------------------------------------------* 
		# First step: Choose the best clustering method 
		# *-----------------------------------------------------------------------------------------------* 

		# Automatic comparison of clustering methods 
		allClust_men <- wcCmpCluster(mcdist_men, maxcluster=20, method=c("average", "pam", "beta.flexible", "ward.D2", "diana", "agnes"), pam.combine=FALSE)

		summary(allClust_men, max.rank = 20)

		# Plot PBC, RHC and ASW
		pdf(paste0('allClust_men_A', dataset_suffix, '.pdf'), width = 20, height = 20)
		par(cex.axis = plot_cex, cex.lab = plot_cex, cex.main = plot_cex, cex.sub = plot_cex)  # Adjust font sizes
		plot(allClust_men, stat=c("ASW", "CH", "HC", "HGSD", "PBC"), norm="zscore", lwd=7) # Increased line width
		dev.off()

		# Plot PBC, RHC and ASW grouped by cluster method
		pdf(paste0('allClust_men_B', dataset_suffix, '.pdf'), width = 20, height = 20)
		par(cex.axis = plot_cex, cex.lab = plot_cex, cex.main = plot_cex, cex.sub = plot_cex)  # Adjust font sizes
		plot(allClust_men, group="method", stat=c("ASW", "CH", "HC", "HGSD", "PBC"), norm="zscore", lwd=7) # Increased line width
		dev.off()


		# *-----------------------------------------------------------------------------------------------* 
		# Second step: Cluster analysis, choose the best number of clusters 
		# *-----------------------------------------------------------------------------------------------* 

		# Ward cluster
		wardCluster_men <- hclust(as.dist(mcdist_men), method = "ward.D")

		# Estimate the clustering quality for groupings in 2, 3, ..., ncluster = 20
		wardRange_men <- as.clustrange(wardCluster_men, diss = mcdist_men, ncluster = 20)
		summary(wardRange_men, max.rank = 20)
		Sys.time()

		# Plot ASWw HG PBC HC 
		pdf(paste0('wardRange_men', dataset_suffix, '.pdf'), width = 20, height = 20)
		par(cex.axis = plot_cex, cex.lab = plot_cex, cex.main = plot_cex, cex.sub = plot_cex)  # Adjust font sizes
		plot(wardRange_men, stat=c("ASW", "CH", "HC", "HGSD", "PBC"), norm="zscore", lwd=7) # Increased line width
		dev.off()

		# Perform the cluster analysis using the Ward
		clusterward_men <- agnes(mcdist_men, diss = T, method = "ward")


		# *-----------------------------------------------------------------------------------------------* 
		# *>> Variables for regression analysis 
		# *-----------------------------------------------------------------------------------------------* 

		mergeid <- Family_men[1]

		for (k in 2:20) {
			family_work_men <- cutree(clusterward_men, k = k)
			cluster_men <- data.frame(pid = mergeid, family_work_men)
			cluster_men <- setNames(cluster_men, c("mergeid", paste0("cluster_", k)))
			save.dta13(cluster_men, paste0("A:/Encrypted datasets/Derived/COL_Tattarini_Uccheddu_Bertogg/W_All/cluster_men_", dataset_suffix, k, ".dta"))

			# Create labs factor
			labs <- factor(family_work_men, labels = paste("Cluster", 1:k))

			# Save Family plot
			pdf(paste0('Family_seq_men_', k, dataset_suffix, '.pdf'), width = 20, height = 20)
			par(cex=plot_cex)  # Adjust global text size
			seqdplot(Family_seq_men, group = labs, border = NA, with.legend = TRUE, cex.legend = legend_cex)
			dev.off()

			# Save Employment plot
			pdf(paste0('Employment_seq_men_', k, dataset_suffix, '.pdf'), width = 20, height = 20)
			par(cex=plot_cex)  # Adjust global text size
			seqdplot(Employment_seq_men, group = labs, border = NA, with.legend = TRUE, cex.legend = legend_cex)
			dev.off()
		}
}



# *-----------------------------------------------------------------------------------------------* 
# *>> Call the function for each dataset 
# *-----------------------------------------------------------------------------------------------* 

perform_sequence_analysis("") 		# Dataset with all the countries 
perform_sequence_analysis("_FR") 	# France
perform_sequence_analysis("_IT") 	# Italy
perform_sequence_analysis("_NL") 	# Netherlands
perform_sequence_analysis("_SE") 	# Sweden



# *-----------------------------------------------------------------------------------------------* 
# *>> Close 
# *-----------------------------------------------------------------------------------------------* 

# Log file (close)
log_close()

# Time 
Sys.time() # Check the time 

