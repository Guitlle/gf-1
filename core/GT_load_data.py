import pandas as pd
import numpy as np

munisGT = pd.read_csv("../../Covariates and Other Data/Demographics/Guatemala_Municipios_IGN2017_worldpop2010-2012-2015.csv")
# There are two municipalities that are actually one. To handle this unique case I am making the
# following groupby.
munisGT = munisGT.groupby("COD_MUNI__").agg({
    "NOMBRE__": "first",
    "COD_DEPT__": "first",
    "DEPTO__": "first",
    "AREA_KM__": "sum",
    "Poblacion2010": "sum",
    "Poblacion2012": "sum",
    "Poblacion2015": "sum"
}).reset_index()

splitted_municipalities = pd.DataFrame(data = {
    "parent_code": [1322,507,1002,1705,1708,1901,1218],
    "new_code": [1333,514,1021,1713,1714,1911,1230],
    "year_of_split": [2015,2015,2014,2011,2014,2014,2014]
})

munisGT.columns = ["municode", "name", "deptocode", "depto", "area", 
                   "Poblacion2010", "Poblacion2012", "Poblacion2015"]
munisGT = munisGT.merge(splitted_municipalities, 
                        left_on = "municode", right_on = "new_code", how="outer")
munisGT["parent_code"] = munisGT.apply(lambda x: x.municode if np.isnan(x.parent_code) else x.parent_code, axis="columns")

munisGT_2009 = munisGT.groupby("parent_code").agg({
    "name": "first",
    "deptocode": "first",
    "depto": "first",
    "area": "sum",
    "Poblacion2010": "sum",
    "Poblacion2012": "sum",
    "Poblacion2015": "sum"
}).reset_index()
munisGT_2009.columns = ["municode", "name", "deptocode", "depto", "area", 
                   "Poblacion2010", "Poblacion2012", "Poblacion2015"]