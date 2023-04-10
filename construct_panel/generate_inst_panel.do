* Generate institution panel


bys year aff_inst_id: egen nauthors = nvals(author_id)

collapse (first) authors=nauthors (sum) aif=aif waif=waif jif=jif wjif=wjif jci=jci wjci=wjci jifwsc=jifwithoutselfcites wjifwsc=wjifwsc citations=citations wcitations=wcitations top5s=top5 wtop5s=wtop5 wpubs=wpubs (count) pubs = author_id, by(aff_inst_id year)

xtset aff_inst_id year
tsfill

gsort aff_inst_id +year

cd "$data_folder"
save "inst_panel", replace
