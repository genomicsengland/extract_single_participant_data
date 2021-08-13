# README

This script pulls clinical data from the research release for a single participant for cases where a participant has made a subject access request.

The script is run by passing the participant ID, the name of the LabKey project where the release of interest is located, and the output directory as arguments e.g.:

`Rscript extract_single_participant_data.r 100121453 main-programme_v10_2020-09-03 ~/scratch`

The `tables.csv` file is a list of all the tables in the release and indicates whether or not the table should be included in the extract and whether the table is at the participant or case (i.e. `gel_case_reference`) level.
