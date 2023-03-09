*gen fe1fe2_fem = fe1_female + fe2_female

sum fe2_female
local varfe2 = r(Var)

sum wprod
local var_y = r(Var)

corr wprod fe2_female
local corry = r(rho)

di `corry' / `var_y'

sum fe1_female
local varfe1 = r(Var)

sum wprod
local var_y = r(Var)

corr wprod fe1_female
local corry = r(rho)

di `corry' / `var_y'


sum fe2_female
local varfe2 = r(Var)

sum wprod
local var_y = r(Var)

corr wprod fe2_female
local corry = r(rho)

di `corry' / `var_y'