#' Match a vector of genes to a SIF network
#'
#' @param genes1 a vector of genes
#' @param genes2 an optional vector if the source
#' @param annot_edgelist a data.frame; the first two columns are interaction
#'   participants and the third column is an optional annotation
#' @param antibody_vec a vector with the names of the antibodies (e.g. colnames(proteomicResponses));
#'   indicies returned from this function will be mapped to this vector
#' @param use_annot a boolean as to whether the optional annotation column values
#'   in the annot_edgelist should outputted in the results
#' @param verbose a boolean to show debugging information
#'
#' @return a data.frame, columns 1-2 are indicies of the edgelist participants,
#'   column 3 is the annotation values for the edgelist, 4-5 the names of the
#'   edgelist participants
#'
#' @examples
#' antibody_map_file <- system.file("target_score_data", "antibody_map_08272020.csv", 
#'   package = "targetscore")
#' mab_to_genes <- read.csv(antibody_map_file, header = TRUE, stringsAsFactors = FALSE)
#' proteomic_responses_file <- system.file("test_data", "BT474.csv", package = "targetscore")
#' proteomic_responses <- read.csv(proteomic_responses_file, row.names = 1)
#' dist_file <- system.file("target_score_data", "distances.txt", package = "targetscore")
#' tmp_dist <- read.table(dist_file, sep = "\t", header = TRUE, stringsAsFactors = FALSE)
#' 
#' dist <- tmp_dist[which(tmp_dist[, 3] <= 1), ]
#' idx_ab_map <- which(mab_to_genes[, 1] %in% colnames(proteomic_responses))
#' 
#' mab_genes <- mab_to_genes[idx_ab_map, 4]
#' names(mab_genes) <- mab_to_genes[idx_ab_map, 1] 
#' 
#' dist_list <- match_genes_to_edgelist(
#' genes1 = mab_genes,
#' genes2 = NULL,
#' annot_edgelist = dist,
#' antibody_vec = colnames(proteomic_responses),
#' use_annot = TRUE,
#' verbose = TRUE
#' )
#' 
#' @importFrom stats complete.cases
#' 
#' @concept targetscore
#' @export
match_genes_to_edgelist <- function(genes1, genes2 = NULL, annot_edgelist, antibody_vec,
                                    use_annot = FALSE, verbose = FALSE) {
  results <- data.frame(
    gene1 = numeric(0), gene2 = numeric(0), annot = numeric(0),
    gene1_name = character(0), gene2_name = character(0),
    stringsAsFactors = FALSE
  )

  if(is.null(genes2)) {
    genes2 <- genes1
  }

  if(is.null(names(genes1)) || is.null(names(genes2))) {
    stop("ERROR: genes1 and genes2 must be named vectors with antibody names")
  }

  t1 <- unique(as.vector(genes1))
  t2 <- setdiff(t1, c("a", "i", "c"))
  if(length(t2) == 0) {
    msg <- paste0("ERROR: genes1 do not appear to be gene names: ", paste(t1, sep=", "))
    stop(msg)
  }

  # Use whole edgelist and filter by genes1
  tmp_idx <- which(annot_edgelist[, 1] %in% genes1)
  annot_edgelist0 <- annot_edgelist[tmp_idx, ]
  # Use edgelist from the previous step  and filter by genes2
  tmp_idx <- which(annot_edgelist0[, 2] %in% genes2)
  annot_edgelist0 <- annot_edgelist0[tmp_idx, ]

  # genes1x <- genes1[annot_edgelist0[, 1] %in% genes1]
  # genes1x <- genes1x[!is.na(genes1x)]

  tmp <- paste0(annot_edgelist0[, 1], ":", annot_edgelist0[, 2])
  if (any(duplicated(tmp))) {
    stop("ERROR: Multiple shortest paths found. Check network.")
  }

  genes1_df <- data.frame(
    PARTICIPANT_A = as.vector(genes1),
    PARTICIPANT_A_NAME = names(genes1),
    stringsAsFactors = FALSE
  )
  genes2_df <- data.frame(
    PARTICIPANT_B = as.vector(genes2),
    PARTICIPANT_B_NAME = names(genes2),
    stringsAsFactors = FALSE
  )

  cur_annot_edgelist <- annot_edgelist0
  cur_annot_edgelist <- merge(cur_annot_edgelist, genes1_df, by = "PARTICIPANT_A", all.y = TRUE)
  cur_annot_edgelist <- merge(cur_annot_edgelist, genes2_df, by = "PARTICIPANT_B", all.y = TRUE)
  idx <- complete.cases(cur_annot_edgelist)
  cur_annot_edgelist <- cur_annot_edgelist[idx, ]

  if (verbose) {
    message("START MATCH GENES: ", as.character(Sys.time()), "\n")
    message("NROW: ", nrow(cur_annot_edgelist), "\n")
  }

  # NOTE: Lack of interactions between nodes may trigger match_genes_to_edgelist 
  #   errors generating data.frame when cur_annot_edgelist has a nrow = 0
  for (i in 1:nrow(cur_annot_edgelist)) {
    # i <- 1
    annot <- NA
    if (use_annot) {
      annot <- cur_annot_edgelist[i, "DISTANCE"]
    }

    # Get indicies based off antibody names rather than the gene names
    gene1_ab_idx <- which(antibody_vec == cur_annot_edgelist[i, "PARTICIPANT_A_NAME"])
    gene2_ab_idx <- which(antibody_vec == cur_annot_edgelist[i, "PARTICIPANT_B_NAME"])

    gene1_name <- cur_annot_edgelist[i, "PARTICIPANT_A"]
    gene2_name <- cur_annot_edgelist[i, "PARTICIPANT_B"]
    gene1_ab <- cur_annot_edgelist[i, "PARTICIPANT_A_NAME"]
    gene2_ab <- cur_annot_edgelist[i, "PARTICIPANT_B_NAME"]

    tmp_results <- data.frame(
      gene1 = gene1_ab_idx,
      gene2 = gene2_ab_idx,
      annot = annot,
      gene1Name = gene1_name,
      gene2Name = gene2_name,
      gene1Ab = gene1_ab,
      gene2Ab = gene2_ab,
      stringsAsFactors = FALSE
    )

    results <- rbind(results, tmp_results)
  }

  return(results)
}
