// setup the database necessities
	set odbcmgr unixodbc
	global db_name CODMOD
	odbc load, exec("SELECT iso3 FROM countries") dsn("$db_name") clear
	levelsof iso3, l(ihme_isos) c

// get deaths by age estimates
	use "/home/j/project/causes of death/codmod/archive/codmod/maternal reviewer responses/final run 3/results/rreg/results/compiled_deaths_by_age.dta", clear
	keep country_name iso3 year age mean_deaths lower_deaths upper_deaths
	rename mean_deaths mean
	rename lower_deaths lower
	rename upper_deaths upper
	generate type = "deaths_" + string(age)
	drop age
	tempfile deathsbyage
	save `deathsbyage', replace

// get mmr estimates
	use "/home/j/project/causes of death/codmod/archive/codmod/maternal reviewer responses/final run 3/results/rreg/results/compiled_mmrs_by_country.dta", clear
	keep iso3 country_name year MMR_mean MMR_lower MMR_upper
	rename MMR_mean mean
	rename MMR_lower lower
	rename MMR_upper upper
	generate type = "mmr"

// keep just relevant data
	append using `deathsbyage'
	generate keepme = 0
	foreach i of local ihme_isos {
			replace keepme = 1 if iso3 == "`i'"
	}
	keep if keepme == 1

// upload estimates
	odbc exec("DROP TABLE IF EXISTS mmr_estimates;"), dsn("$db_name")
	odbc exec("CREATE TABLE IF NOT EXISTS mmr_estimates(iso3 char(3), country_name char(48), year smallint, mean float, upper float, lower float, type char(9), PRIMARY KEY (iso3, year, type), FOREIGN KEY (iso3) REFERENCES countries(iso3), FOREIGN KEY (year) REFERENCES years(year)) ENGINE=InnoDB;"), dsn("$db_name")
	odbc insert iso3 year mean lower upper country_name type, table("mmr_estimates") dsn("$db_name") overwrite
	odbc exec("ALTER TABLE mmr_estimates ADD INDEX (iso3), ADD INDEX (year);"), dsn("$db_name")

// get maternal mortality studies
	odbc load, exec("SELECT *, cf*envelope as deaths FROM cod_studies LEFT JOIN cod_observations USING (study_id) LEFT JOIN cause_fractions USING (observation_id) LEFT JOIN population USING (iso3,year,sex,age) LEFT JOIN mortality_envelope USING (iso3,year,sex,age) LEFT JOIN fertility USING (iso3,year) LEFT JOIN sexes USING (sex) LEFT JOIN ages USING (age) LEFT JOIN countries USING (iso3) WHERE age>14 AND age<50 AND sex=2 AND cause='A10' AND year >= 1980 AND year <= 2010;") dsn("$db_name") clear
        
// make deaths by age
	preserve
	generate type = "deaths_" + string(age)
	keep iso3 type year study_id source_type source_label sample_size cf outlier deaths
	rename deaths observed
	tempfile deathsbyage
	save `deathsbyage', replace
	restore

// make mmr
	collapse (sum) deaths sample_size (mean) births, by(iso3 year study_id source_type source_label outlier)
	generate type = "mmr"
	generate observed = deaths/births*100000

// upload observations
	append using `deathsbyage'
	odbc exec("DROP TABLE IF EXISTS mmr_studies;"), dsn("$db_name")
	odbc exec("CREATE TABLE IF NOT EXISTS mmr_studies(iso3 char(3), year smallint, study_id int, source_type char(14), source_label char(28), outlier bit, sample_size float, observed float, type char(9), PRIMARY KEY (study_id, year, type), FOREIGN KEY (iso3) REFERENCES countries(iso3), FOREIGN KEY (year) REFERENCES years(year)) ENGINE=InnoDB;"), dsn("$db_name")
	odbc insert iso3 year study_id source_type source_label outlier sample_size observed type, table("mmr_studies") dsn("$db_name") overwrite
	odbc exec("ALTER TABLE mmr_studies ADD INDEX (iso3), ADD INDEX (year);"), dsn("$db_name")
        



