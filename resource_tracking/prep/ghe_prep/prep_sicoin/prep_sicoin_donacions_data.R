# ----------------------------------------------
# Irena Chen
#
# 2/9/2018
# Template for prepping SICOIN donations data 
# Inputs:
# inFile - name of the file to be prepped
# year - which year the dataset corresponds to
#
# Outputs:
# budget_dataset - prepped data.table object

# --------------------------------------------------------------
# start function
# --------------------------------------------------------------
prep_donacions_sicoin = function(inFile, start_date, disease, period, source, loc_name, loc_id) {
  
  # Test the inputs
  if (class(inFile)!='character') stop('Error: inFile argument must be a string!')
  if (class(year)=='character') stop('Error: year argument must be a number!')
  # --------------------------------------------------------------
  # Files and directories
  #inFile = "J:/Project/Evaluation/GF/resource_tracking/gtm/SICOIN GT/TUBERCULOSIS/MONTHLY/TB DONATIONS/2017/TB DEC 2017 DONATIONS.xls"
  #inFile = "J:/Project/Evaluation/GF/resource_tracking/gtm/SICOIN GT/TUBERCULOSIS/MONTHLY/TB DONATIONS/2016/TB AUGUST 2016 DONATIONS.xls"
  #disease = "tb"
  #start_date = "2016-08-01"
  #period = 30
  #source = "donacions"
  
  # Load/prep data
  gf_data <- data.table(read_excel(inFile))
  ## remove empty columns 
  gf_data<- Filter(function(x)!all(is.na(x)), gf_data)
  
  if (disease%in%c("hiv", "tb")){ 
      if("X_12" %in% colnames(gf_data) && (gf_data$X__12 && length(unique(na.omit(gf_data$X__12))) >1 || nrow(gf_data[grep("FONDO", gf_data$X__12)]) == 0)){ 
      ## grab loc_id: 
      gf_data$X__14 <- na.locf(gf_data$X__14, na.rm=FALSE)
      gf_data$X__4 <- na.locf(gf_data$X__4, na.rm=FALSE)
      gf_data$X__3 <- na.locf(gf_data$X__3, na.rm=FALSE)
      # remove rows where cost_categories are missing values
      if(disease=="hiv"&year(start_date)== 2011 & period==30){ 
        gf_data <- gf_data[c(grep("Banco", gf_data$X__12):grep("FONDO", gf_data$X__12)),]
      } else if(disease=="tb"){
        gf_data <- gf_data[c(grep("Donant", gf_data$X__12):.N),]
      } else {
        gf_data <- gf_data[c(grep("Gobierno de", gf_data$X__12):.N),]
      }
      gf_data <- na.omit(gf_data, cols="X__15")
      budget_dataset <- gf_data[, c("X__3","X__4","X__14","X__15", "X__27", "X__29"), with=FALSE]
      names(budget_dataset) <- c("adm1", "adm2", "loc_name","sda_orig", "budget", "disbursement")
     }else if (!("X_12" %in% colnames(gf_data)) && disease == "tb" && (start_date == "2018-04-01" || start_date == "2018-03-01")){
        setnames(gf_data, old = "DEL MES DE ABRIL AL MES DE ABRIL", new = "location")
        
        ## grab loc_id: 
        gf_data$X__11 <- na.locf(gf_data$X__11, na.rm=FALSE)
        gf_data$X__3 <- na.locf(gf_data$X__3, na.rm=FALSE)
        gf_data$location <- na.locf(gf_data$location, na.rm=FALSE)
        
        gf_data <- gf_data[c(grep("Donant", gf_data$X__10):.N),]
        #gf_data <- na.omit(gf_data, cols="X__15")
        #budget_dataset <- gf_data[, c("X__3","location","X_11","X__15", "X__27", "X__29"), with=FALSE]
        names(budget_dataset) <- c("adm1", "adm2", "loc_name","sda_orig", "budget", "disbursement")
        
    }else {  ## if there are no other external sources other than GF 
        budget_dataset <- setnames(data.table(matrix(nrow = 1, ncol = 11)), 
                                   c("sda_orig","adm2","adm1","loc_name","budget", "disbursement", 
                                     "source", "period",	"start_date", "disease", "expenditure"))
        budget_dataset$loc_name<- as.character(budget_dataset$loc_name)
        budget_dataset$loc_name <- loc_name
        budget_dataset$loc_id <- loc_id
    }
  }
  toMatch <- c("government", "recursos", "resources", "multire")
  budget_dataset <- budget_dataset[ !grepl(paste(toMatch, collapse="|"), tolower(budget_dataset$loc_name)),]
  

  
  ##enforce variable classes 
  if (!is.numeric(budget_dataset$budget)) budget_dataset[,budget:=as.numeric(budget)]
  if (!is.numeric(budget_dataset$disbursement)) budget_dataset[,disbursement:=as.numeric(disbursement)]
  
  ## in the off chance that there are duplicates by loc_id & sda_orig (NAs in the budget for instance)
  ## this gets rid of them:
  budget_dataset <- budget_dataset[, list(budget=sum(na.omit(budget)), disbursement=sum(na.omit(disbursement))),
                                   by=c("adm1","adm2","loc_name", "sda_orig")]

  # --------------------------------------------------------------
  
  ## Create other variables 
  budget_dataset$financing_source <- source
  budget_dataset$start_date <- start_date
  budget_dataset$period <- period
  budget_dataset$expenditure <- 0 ## change this once we figure out where exp data is
  budget_dataset$disease <- disease
  

  # ----------------------------------------------
  
  # Enforce variable classes again 
  if (!is.numeric(budget_dataset$expenditure)) budget_dataset[,expenditure:=as.numeric(expenditure)]
  
  # ----------------------------------------------
  # return prepped data
  return(budget_dataset)
}

