# ----------------------------------------------
# AUTHOR: Emily Linebarger 
# PURPOSE: Master file for updating resource tracking database. 
# DATE: Last updated November 2018. 
# ----------------------------------------------

# ---------------------------------------
# Install packages and set up R  
# ---------------------------------------

# ----------------------------------------------------------------------
# To do list for this code: 
# - add in an option to only rework one file (make database append-only)
# - add in variable creation during the append step to flag current grants. 
# ---------------------------------------------------------------------

rm(list=ls())
library(lubridate)
library(data.table)
library(readxl)
library(stats)
library(stringr)
library(tidyr)
library(tools)
library(rlang)
library(zoo)
library(dplyr)

options(scipen=100)

# ---------------------------------------
#Boolean logic switches 
# ---------------------------------------
include_stops = FALSE #Set to true if you would like scripts to stop when errors are found (specifically, module mapping)
verbose = FALSE #Set to true if you would like warning messages printed (helpful for debugging functions). Urgent messages will always be flagged regardless of this switch. 
limit_filelist <- TRUE #Set to TRUE if you want to only run files that will be saved in final budgets and expenditures. 

# ---------------------------------------
# Set global variables and filepaths.  
# ---------------------------------------

#Replace global variables to match what code you want to run. 
user = "elineb" #Change to your username 
country <- c("cod") #Change to the country you want to update. 

#Mark which grants are currently active to save in file - this should be updated every grant period! 
current_gtm_grants <- c('GTM-H-HIVOS', 'GTM-H-INCAP', 'GTM-M-MSPAS', 'GTM-T-MSPAS')
current_gtm_grant_period <- c('2018', '2019-2020', '2018-2020', '2016-2019')

current_cod_grants <- c('COD-C-CORDAID', 'COD-H-MOH', 'COD-T-MOH', 'COD-M-MOH', 'COD-M-SANRU')
current_cod_grant_period <- rep("2018-2020", 5)

current_uga_grants <- c('UGA-C-TASO', 'UGA-H-MoFPED', 'UGA-M-MoFPED', 'UGA-M-TASO', 'UGA-T-MoFPED')
current_uga_grant_period <- rep("2018-2020", 5)

#Filepaths
j = ifelse(Sys.info()[1]=='Windows','J:','/home/j')
dir = paste0(j, '/Project/Evaluation/GF/')
code_loc = ifelse(Sys.info()[1]=='Windows', paste0('C:/Users/', user, '/Documents/gf/'), paste0('/homes', user, '/gf/'))
code_dir = paste0(code_loc, "resource_tracking/prep/")
combined_output_dir = paste0(j, "resource_tracking/multi_country/mapping")
source(paste0(code_dir, "shared_mapping_functions.R")) 

# ----------------------------------------------
# STEP 1: Read in and verify module mapping framework
# ----------------------------------------------
  
  map = read_xlsx(paste0(j, "Project/Evaluation/GF/mapping/multi_country/intervention_categories/intervention_and_indicator_list.xlsx"), sheet='module_mapping')
  map = data.table(map)
  source(paste0(code_dir, "2_verify_module_mapping.r"))
  module_map <- prep_map(map)
  
# ----------------------------------------------
# STEP 2: Load country directories and file list
# ----------------------------------------------
  
  
  master_file_dir = paste0("J:/Project/Evaluation/GF/resource_tracking/", country, "/grants/")
  export_dir = paste0("J:/Project/Evaluation/GF/resource_tracking/", country, "/prepped/")
  country_code_dir <- paste0(code_dir, "global_fund_prep/", country, "_prep/")
  file_list = fread(paste0(master_file_dir, country, "_budget_filelist.csv"), stringsAsFactors = FALSE)
  file_list$start_date <- as.Date(file_list$start_date, format = "%m/%d/%Y")
  file_list = file_list[, -c('notes')]
  
  #Validate file list 
  desired_cols <- c('file_name', 'sheet', 'function_type', 'start_date', 'disease', 'data_source', 'period', 'qtr_number', 'grant', 'primary_recipient',
                    'secondary_recipient', 'language', 'geography', 'grant_period', 'grant_status', 'file_iteration')
  #stopifnot(colnames(file_list) %in% desired_cols)
  
  stopifnot(sort(unique(file_list$data_source)) == c("fpm", "pudr"))
  stopifnot(sort(unique(file_list$file_iteration)) == c("final", "initial"))
  
  #Turn this variable on to run only a limited section of each country's file list; i.e. only the part that will be kept after GOS data is prioritized in step 4 (aggregate data). 
  if(limit_filelist==TRUE){
    file_list = prioritize_gos(file_list)
  }
  
  
# ----------------------------------------------
# STEP 3: Prep a single source of data
# ----------------------------------------------
  
  source(paste0(code_dir, "3_prep_country_data.r"))

# ----------------------------------------------
# STEP 4: Aggregate all data sources
# ----------------------------------------------

  source(paste0(code_dir, "4_aggregate_all_data_sources.r"))

# ----------------------------------------------
# STEP 5: Verify budget numbers
# ----------------------------------------------

  source(paste0(code_dir, "5_verify_budget_numbers.r")) 
 
# ----------------------------------------------
# STEP 6: Upload to Basecamp
# ----------------------------------------------

#Open in Spyder, and run: "C:/Users/user/Documents/gf/resource_tracking/prep/6_basecamp_upload.py"

