* 4g) Construct regions for institution classes

clear
cd "$data_folder"
import delimited using "regions/regions.csv", varnames(1)
keep continent iso2

* add some missing countries
expand 2 in l
replace iso2 = "XK" in l
replace continent = "EU" if iso2 == "XK"

gen region = ""
replace region = "EU" if continent == "EU"
replace region = "NA" if continent == "NA"
replace region = "UK" if iso2 == "GB"
replace region = "US" if iso2 == "US"
replace region = "REST" if missing(region)

encode region, gen(region_id)
rename iso2 inst_country



save "regions/regions", replace