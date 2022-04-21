# Script to help refreshing the table manifest when using a newer project
# Requires copying the list of tables that is given under the Listss sub-heading
# on the project homepage
# Command:
# Rscript refresh_table_manifest.r <current_menifest> <output_filename>
rm(list = objects())
Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE,
    scipen = 200)

# get passed arguments
input_manifest <- commandArgs(trailingOnly = TRUE)[1]
output_destination <- commandArgs(trailingOnly = TRUE)[2]

# Function to send a message to console
send_notification <- function(text){
    cat(paste(text, "\n"))
}

# ask and return an input
ask_for_input <- function(question) {
    send_notification(question)
    return(readLines("stdin", n = 1))
}

# get an input and check it is an acceptable response
get_and_check_response <- function(question, acceptable_responses){
    a <- ask_for_input(question)
    while(!a %in% acceptable_responses) {
        a <- ask_for_input("unacceptable")
    }
    return(a)
}

# print out a vector nicely
print_list <- function(list) {
    for (i in list) {
        cat(paste(i, "\n"))
    }
}

# get information on any new tables
get_new_table_info <- function(tab) {
    export <- get_and_check_response(paste("Should", tab,
        "be included in export? y/n"), c("y", "n"))
    if (export == "y") {
        return(data.frame(
            table = tab,
            level = get_and_check_response("What level is it? participant/gcr",
                c("participant", "gcr")),
            export = TRUE,
            note = NA
            )
        )
    } else {
        return(data.frame(
            table = tab,
            level = NA,
            export = TRUE,
            note = ask_for_input("Why not?")
            )
        )
    }
}

# read current tables from clipboard
get_and_check_response("Copy the list of tables to clipboard then press Enter", c(""))
prj_tabs <- read.delim(pipe("pbpaste"), header = FALSE)$V2
send_notification("Here's what I got:")
print_list(c(head(prj_tabs), "..."))

# read the current table_manifest
curr_manifest <- read.csv(input_manifest)

# Identify and remove tables that were in previous manifest not in new
missing_tables <- curr_manifest$table[!curr_manifest$table %in% prj_tabs]
send_notification("These tables are missing from the pasted in list and will be deleted from the manifest")
print_list(missing_tables)
curr_manifest <- curr_manifest[!curr_manifest$table %in% missing_tables, ]

# Identify tables in the new list that aren't in the manifest
new_tables <- prj_tabs[!prj_tabs %in% curr_manifest$table]
send_notification("These tables are in the pasted in list but not in the manifest, we need some information")
print_list(new_tables)

# get required info
for (i in new_tables) {
    d <- get_new_table_info(i)
    curr_manifest <- rbind(curr_manifest, d)
}

# Write out the new table manifest
write.csv(curr_manifest, output_destination, row.names = F)
