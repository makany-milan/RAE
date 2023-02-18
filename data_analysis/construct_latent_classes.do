* 4g) Collapse rankings

clear
cd "$data_folder"
use "sample"

collapse (first) inst_name qs_econ_2021_rank qs_overall_2022_rank qs_econ_citations qs_faculty_student_ratio_score qs_size cwur_worldrank the_ec_rank the_ec_industry_income the_research_rank the_citations inst_country country_name (count) authors=author_id (sum) aif top5s (mean) max_age avg_coauthors female, by(aff_inst_id)

