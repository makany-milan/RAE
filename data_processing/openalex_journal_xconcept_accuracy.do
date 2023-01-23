* Check the accuracy of OpenAlex's XCONCEPT classifications.
cd "$data_folder\concepts"
* create directory to save datasets
capture mkdir "formatted"


* Import OpenAlex concepts
clear
import delimited using concepts_data.csv, varnames(1) encoding(utf-8)