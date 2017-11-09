#!/usr/bin/python

import gzip, csv, sys, socket, datetime

def get_time(intime):
	# IN : '2017-04-14 23:45:00 MSK'
	date, time = intime.split(' ')[0], intime.split(' ')[1]
	epoch_time = int(datetime.datetime.strptime(date + ' ' + time, "%Y-%m-%d %H:%M:%S").strftime('%s'))
	return epoch_time

def check_if_number(number):
	try:
		float(number)
		return True
	except ValueError:
		return False

def parse_csv(filename, carbon_server, carbon_port):
	with gzip.open(filename, 'rb') as infile:
		reader = csv.reader(infile)
		for line in reader:
			batch = []

			if len(line) == 0:
				# Empty line
				continue

			if line[0] == 'Group':
				# IN: ['Group', 'Diameter Performance']
				group_name = line[1].replace(' ', '_')

			if len(line) < 3:
				# Header lines
				continue

			elif line[0] == 'Timestamp':
				# Measurement header line
				# ['Timestamp', 'Scope Type', 'Scope', 'Server', 'Name/Index', 'TmResponseTimeDownstream', 'TmResponseTimeUpstream', 'RxRequestNoErrors', 'RxAnswerExpectedAll', 'EvPerConnPtrQueuePeak', 'EvPerConnPtrQueueAvg']
				original_header = line

			elif line[3] == 'ALL':
				# KPI value line
				epoch_time = g#!/usr/bin/python

import gzip, csv, sys, socket, datetime

def get_time(intime):
	# IN : '2017-04-14 23:45:00 MSK'
	date, time = intime.split(' ')[0], intime.split(' ')[1]
	epoch_time = int(datetime.datetime.strptime(date + ' ' + time, "%Y-%m-%d %H:%M:%S").strftime('%s'))
	return epoch_time

def check_if_number(number):
	try:
		float(number)
		return True
	except ValueError:
		return False

def parse_csv(filename, carbon_server, carbon_port):
	with gzip.open(filename, 'rb') as infile:
		reader = csv.reader(infile)
		for line in reader:
			batch = []

			if len(line) == 0:
				# Empty line
				continue

			if line[0] == 'Group':
				# IN: ['Group', 'Diameter Performance']
				group_name = line[1].replace(' ', '_')

			if len(line) < 3:
				# Header lines
				continue

			elif line[0] == 'Timestamp':
				# Measurement header line
				# ['Timestamp', 'Scope Type', 'Scope', 'Server', 'Name/Index', 'TmResponseTimeDownstream', 'TmResponseTimeUpstream', 'RxRequestNoErrors', 'RxAnswerExpectedAll', 'EvPerConnPtrQueuePeak', 'EvPerConnPtrQueueAvg']
				original_header = line

			elif line[3] == 'ALL':
				# KPI value line
				epoch_time = get_time(line[0])
				messages = parse_kpi(original_header, line, group_name)

				for key, value in messages.iteritems():
					message = "%s %s %d\n" % (key, value, epoch_time)
					batch.append(message)
				mess = '\n'.join(batch) + '\n'
				print mess
				write_graphite(mess, carbon_server, carbon_port)

def parse_kpi(original_header, line, group_name):
	# ['2017-04-14 23:45:00 MSK', 'NE', 'HA', 'ALL', 'SY_SERVER_1', '4.105637', '5.229986', '38528', '38485', '18', '3.238418']
	# ['2017-04-15 09:15:00 MSK', 'NE', 'HA', 'ALL', '465837', '232918', '232918', '232918', '7.321113', '232919']
	messages = {}
	header = original_header[:]
	if check_if_number(line[4]):
		prefix = '%s.Measurement.%s.Simple' % (line[2], group_name)
		for i in range(4):
			header.pop(0)
			line.pop(0)
	else:
		prefix = '%s.Measurement.%s.%s' % (line[2], group_name, line[4])
		prefix = line[2] + '.Measurement.' + line[4]
		for i in range(5):
			header.pop(0)
			line.pop(0)
	for i in range(len(line)):
		if line[i] != '' or line[i] != 'n/a':
			# Replace symbols breaking insertion logic (' ') and graphite ('.','/','(',')')
			# key = prefix + '.' + header[i].replace(' ', '_').replace('.', '').replace('/', '_').replace('(', '_').replace(')', '_')
			key = prefix + '.' + header[i]
			messages[key] = line[i]
	return messages

def write_graphite(message, carbon_server, carbon_port):
	sock = socket.socket()
	sock.connect((carbon_server, carbon_port))
	sock.sendall(message)
	sock.close()

def main():
	carbon_server = '127.0.0.1'
	carbon_port = 2003
	filename = sys.argv[1]
	parse_csv(filename, carbon_server, carbon_port)

if __name__ == "__main__":
	main()
et_time(line[0])
				messages = parse_kpi(original_header, line, group_name)

				for key, value in messages.iteritems():
					message = "%s %s %d\n" % (key, value, epoch_time)
					batch.append(message)
				mess = '\n'.join(batch) + '\n'
				print mess
				write_graphite(mess, carbon_server, carbon_port)

def parse_kpi(original_header, line, group_name):
	# ['2017-04-14 23:45:00 MSK', 'NE', 'HA', 'ALL', 'SY_SERVER_1', '4.105637', '5.229986', '38528', '38485', '18', '3.238418']
	# ['2017-04-15 09:15:00 MSK', 'NE', 'HA', 'ALL', '465837', '232918', '232918', '232918', '7.321113', '232919']
	messages = {}
	header = original_header[:]
	if check_if_number(line[4]):
		prefix = '%s.Measurement.%s.Simple' % (line[2], group_name)
		for i in range(4):
			header.pop(0)
			line.pop(0)
	else:
		prefix = '%s.Measurement.%s.%s' % (line[2], group_name, line[4])
		prefix = line[2] + '.Measurement.' + line[4]
		for i in range(5):
			header.pop(0)
			line.pop(0)
	for i in range(len(line)):
		if line[i] != '' or line[i] != 'n/a':
			# Replace symbols breaking insertion logic (' ') and graphite ('.','/','(',')')
			# key = prefix + '.' + header[i].replace(' ', '_').replace('.', '').replace('/', '_').replace('(', '_').replace(')', '_')
			key = prefix + '.' + header[i]
			messages[key] = line[i]
	return messages

def write_graphite(message, carbon_server, carbon_port):
	sock = socket.socket()
	sock.connect((carbon_server, carbon_port))
	sock.sendall(message)
	sock.close()

def main():
	carbon_server = '127.0.0.1'
	carbon_port = 2003
	filename = sys.argv[1]
	parse_csv(filename, carbon_server, carbon_port)

if __name__ == "__main__":
	main()
