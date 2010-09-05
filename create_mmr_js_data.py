import MySQLdb
import json

def load_mmr(iso3) :
	# connect to database
	db = MySQLdb.connect(host='140.142.16.74', port=2302, read_default_file="~/.my.cnf", db='codmod', use_unicode=True)
	
	# get study data
	sql = 'SELECT * FROM mmr_studies WHERE iso3="' + iso3 + '";'
	c = db.cursor(cursorclass=MySQLdb.cursors.DictCursor)
	c.execute(sql)
	data = c.fetchall()
	f = open('./data/mmr_studies.js', 'w')
	f.write('var mmr_studies = ' + json.JSONEncoder().encode(data))
	f.close()
	
	# get estimates
	sql = 'SELECT * FROM mmr_estimates WHERE iso3="' + iso3 + '";'
	c = db.cursor(cursorclass=MySQLdb.cursors.DictCursor)
	c.execute(sql)
	data = c.fetchall()
	f = open('./data/mmr_estimates.js', 'w')
	f.write('var mmr_estimates = ' + json.JSONEncoder().encode(data))
	f.close()
	

