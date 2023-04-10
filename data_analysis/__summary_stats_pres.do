* Summary statistics for moves and productivity metrics

clear
cd "$data_folder"
use "author_panel"

keep if inrange(year, 2000,2020)

* find moves
bys author_id: gen move = 1 if aff_inst_id[_n] != aff_inst_id[_n-1] & _n != 1 & _n != _N
bys author_id: egen number_of_moves = sum(move)

egen author_tag = tag(author_id)

order move number_of_moves 

count if number_of_moves > 5 & author_tag == 1 // 1423 people move than 5 times?
* unrealistic