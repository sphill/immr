def load_mmr(iso3) :
	db = MySQLdb.connect(host='140.142.16.74', port=2302, read_default_file="~/.my.cnf", db='codmod', use_unicode=True)
	sql = 'SELECT age, year, observation_id, study_id, source_type, country_name, source_label, sample_size, cf, rate, outlier FROM mmr_graphs WHERE iso3="' + iso3 + '" AND cause="A10" AND age>14 AND age<50 AND sex=2'