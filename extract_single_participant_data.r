# script to extract a single participant's data from the research release
# requires access to embassy vpn to access RE labkey from outside
# command:
# Rscript extract_single_participant_data.r <participant_id> <project_name> <output_directory>
# e.g. Rscript extract_single_participant_data.r 100121453 main-programme_v10_2020-09-03 ~/scratch
rm(list = objects())
Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE,
    scipen = 200)
library(Rlabkey)

# get passed arguments
participant_id <- commandArgs(trailingOnly = TRUE)[1]
release_version <- commandArgs(trailingOnly = TRUE)[2]
output_directory <- commandArgs(trailingOnly = TRUE)[3]

# connections for getting to the RE labkey, requires connection to embassy VPN
url <- "https://labkey-embassy.gel.zone/labkey"
# path to the project containing the data
fp <- paste0("/main-programme/", release_version)
# should always be this but check a table R snippet if you think it might
# have changed
sn <- "lists"

# some columns that LK makes that aren't in actual data, so can be ignored
lk_cols_to_drop <- c("ModifiedBy",
                     "lastIndexed",
                     "Created",
                     "CreatedBy",
                     "Modified",
                     "container",
                     "EntityId")

# some functions for running SQL on RE labkey
run_sql <- function(sql) {
    labkey.executeSql(url, fp, sn, sql, colNameOpt = "fieldname")
}

read_participant_data_from_table <- function(tab, id, level) {
    cat(paste("Reading", tab, "\n"))
    if (level == 'participant') {
        sql  <- paste0("select * from ", tab,
                    " where participant_id = '", id, "';")
    } else {
        sql  <- paste0("select * from ", tab,
                    " where rare_diseases_family_id = '", id, "';")
    }
    d <- run_sql(sql)
    return(d[, !colnames(d) %in% lk_cols_to_drop])
}

# check participant ID exists in participant table and get the GCR
gcr <- run_sql(paste0(
    "select gel_case_reference from participant where participant_id = '",
    participant_id, "';"))$gel_case_reference
stopifnot(length(gcr) == 1)

# read in the table manifest which says which tables to extract and whether
# they are participant-level or gcr-level
table_manifest <- read.csv("tables.csv")

# checks on table_manifest
stopifnot(all(table_manifest$level %in% c("participant", "gcr")))
stopifnot(all(table_manifest$export %in% c(TRUE, FALSE)))

table_manifest <- table_manifest[table_manifest$export == TRUE, ]
stopifnot(nrow(table_manifest) > 0)

# fetch all the tables
d <- list()
for (i in seq_len(nrow(table_manifest))) {
    tab <- table_manifest$table[i]
    level <- table_manifest$level[i]
    id <- ifelse(level == "participant", participant_id, gcr)
    d[[tab]] <- read_participant_data_from_table(tab, id, level)
}

# function to write out tsv file with date and participant_id appended to
# filename
write_csv <- function(df, fn) {
    ffn <- paste0(output_directory, "/", fn, "-", participant_id, "-",
                  Sys.Date(), ".xls")
    write.table(df, ffn, sep = "\t", row.names = F)
}

dir.create(output_directory, showWarnings = FALSE)
for (tab in names(d)) {
    write.csv(d[[tab]], tab, row.names = F, quotes = F)
}
