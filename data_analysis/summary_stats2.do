* 5e) Generate summary statistics and descriptive graphs

clear
cd "$data_folder"
use "sample_fe"


set scheme white_tableau

* count the number of authors and departments
distinct author_id
distinct aff_inst_id

* create tag for more period dynamic model
egen author_global_class_tag = tag(author_id GLOBAL_CLASS)

corr alpha_i_female phi_k_female if author_global_class_tag == 1
corr alpha_i_male phi_k_male if author_global_class_tag == 1