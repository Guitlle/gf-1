setwd('C:/local/gf/')
# ----------------------------------------------

# --------------------
# Set up R / install packages
## -------------------
rm(list=ls())
library(data.table)
library(lubridate)
library(stringr)
library(ggplot2)
# -------------------------
# Files and directories
# directories
data_path <- "J:/Project/Evaluation/GF/outcome_measurement/cod/dhis_data/prepped/"
catalogue_path <-"J:/Project/Evaluation/GF/outcome_measurement/cod/dhis/catalogues/"

# input files
data <-"sigl_drc_01_2015_07_2018_prepped.rds"
cat <- "data_elements_cod.csv"

# output files 
prepped_data <- "drugs_consumed_lost_available.rds"
drugs_dist <- "tb_mal_drugs_distributed.rds"

# functions
source('./core/standardizeHZNames.R')
# -------------------------

# # ---------------------------------------------------
# # DATA PREP
# # ---------------------------------------------------
#   # Load data
#   dt <- readRDS(paste0(data_path, data))
#   catalogue <- read.csv(paste0(catalogue_path, cat))
#
#   # subset DHIS data to just the data on drugs that we want to assess for malaria and tb
#   # by first isolating those variables from the catalogue and then subsetting to just those
#   drugs_consumed <- catalogue[grepl("consumed", catalogue$element) & catalogue$type %in% c("tb", "malaria"),]
#   drugs_avail <- catalogue[grepl("available", catalogue$element) & catalogue$type %in% c("tb", "malaria"),]
#   drugs_lost <- catalogue[grepl("lost", catalogue$element) & catalogue$type %in% c("tb", "malaria"),]
#   
#   vars_to_keep <- rbind(drugs_consumed, drugs_avail, drugs_lost)
#   vars_to_keep$element_id <- as.character(vars_to_keep$element_id)
#   vars_to_keep <- vars_to_keep$element_id
#   
#   dt <- dt[element_id %in% vars_to_keep, ]
#   dt$element <- as.character(dt$element)
#   dt <- dt[drug== 1]
#   
#   dt[grep("perdue", dt$element), variable:= "lost"]
#   dt[grep("consomm�e", dt$element), variable:= "consumed"]
#   dt[grep("utilisable", dt$element), variable:= "available"]
#   
#   dt$drug <- NULL
#   dt[grep("RHE", element, fixed=TRUE), drug:= "RHE"]
#   dt[grep("RHZ", element, fixed=TRUE), drug:= "RHZ"]
#   dt[grep("RHZE", element, fixed=TRUE), drug:= "RHZE"]
#   dt[grep("(RH) 150mg+75mg", element, fixed=TRUE), drug:= "RH 150mg+75mg"]
#   dt[grep("(RH) 60mg+30mg", element, fixed=TRUE), drug:= "RH 60mg+30mg"]
#   dt[grep("Amodiaquine (6-13 ans", element, fixed=TRUE), drug:= "ASAQ_6to13yrs"]
#   dt[grep("Amodiaquine (+14 ans", element, fixed=TRUE), drug:= "ASAQ_14yrsAndOlder"]
#   dt[grep("Amodiaquine (2-11 mois)", element, fixed=TRUE), drug:= "ASAQ_2to11mos"]
#   dt[grep("Amodiaquine (12-59 mois)", element, fixed=TRUE), drug:= "ASAQ_12to59mos"]
#   dt[grep("Sulfadoxine", element, fixed=TRUE), drug:= "SP"]
#   dt[grep("Artemether 80mg+480mg", element, fixed=TRUE), drug:= "AL_80+480"]
#   dt[grep("Artemether 40mg+240mg", element, fixed=TRUE), drug:= "AL_40mg+240mg"]
#   
#   dt <- dt[!is.na(drug)]
#   
#   saveRDS(dt, paste0(data_path, prepped_data))
# # ---------------------------------------------------

# ---------------------------------------------------
# Load prepped data
dt <- readRDS(paste0(data_path, prepped_data))
# ---------------------------------------------------

# ---------------------------------------------------
# snis data is more accurate from 2017 on for drc
dt <- dt[ date >= "2017-01-01"]
dt[, element:= NULL]
dt[, element_eng:= NULL]
dt[, element_id:= NULL]
dt[, tableau:= NULL]
dt[, category:= NULL]
dt[, mtk:= NULL]
dt[, opening_date:= NULL]
dt[, last_update:= NULL]
dt[, data_set:= NULL]
dt[, coordinates:= NULL]

all_vars <- colnames(dt)
vars_for_cast <- all_vars[!all_vars %in% c("variable", "value")]

# create formula for cast
f <- as.formula(paste(paste(vars_for_cast, collapse = " + "), "~ variable"))

# cast variable wide so we can add/subtract vars
dt_wide <- dcast.data.table(dt, f, value.var = "value")

# OPTIONAL - sum by DPS here before calculation, then do calculation. Testing what happens when I try this
sdcols <- c('available', 'consumed', 'lost')
dt_wide <- dt_wide[, lapply(.SD, sum, na.rm=TRUE), .SDcols= sdcols, by= c('dps','date', 'type', 'drug')]

# identify where previous date (by month) is missing in the data,
# by unique identifiers
test <- setorderv(dt_wide, c("dps", "drug", "date")) #c("org_unit_id","drug", "category", "date"))
test <- test[, previous_date := (date - months(1))]
test <- test[, actual_previous_date := data.table::shift(date, 1L, type="lag"), by=c('dps', 'drug')] #by=c('org_unit_id', 'drug', 'category')]
test <- test[, include_in_calculation := ifelse(previous_date == actual_previous_date, TRUE, FALSE), ]

# calculate received, only for dates where the previous month exists
# use shift to get the value for the previous date of the available variable
test[is.na(lost), lost:= 0]
test[include_in_calculation==TRUE, received := (available + consumed + lost - ( data.table::shift(available, 1L, type="lag") ))]

# aggregate to health zone values
sd_cols = c("available", "consumed", "lost", "received")
hz_level <- test[, lapply(.SD, sum, na.rm=TRUE), by=c("date", "dps", "health_zone", "drug", "category"), .SDcols = sd_cols]

# save a copy of the data with drugs distributed for analysis/comparison to PNLP
saveRDS(test, paste0(data_path, drugs_dist))

test <- readRDS(paste0(data_path, drugs_dist))
# where level/org unit type is health zone, the actual field for health zone is blank
# fill this in so that we can aggregate to health zone level
test[is.na(health_zone), edit_hz_string:= TRUE]
test[org_unit_type =="health zone", health_zone:= org_unit]
test[, health_zone:= tolower(health_zone)]

test[edit_hz_string== TRUE, health_zone:= sapply(str_split(health_zone, " ", 2),'[', 2)]
test[edit_hz_string== TRUE, health_zone := str_squish(health_zone)]
test[edit_hz_string== TRUE, health_zone := trimws(health_zone)]
test[edit_hz_string== TRUE, health_zone := gsub(" zone de sant�", "", health_zone)]

test[, health_zone:= gsub(" ", "-", health_zone)]

test[, health_zone := standardizeHZNames(health_zone)]
saveRDS(test, paste0(data_path, drugs_dist))


  