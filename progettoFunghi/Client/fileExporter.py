import database, diagnostic
import datetime, xlsxwriter

_MODULE = "MAIN"

def main(logger: diagnostic.Diagnostic, db: database.DatabaseHandler):
	if (isinstance(logger, diagnostic.Diagnostic) == False or isinstance(db, database.DatabaseHandler) == False):
		raise TypeError("Main function")
	
	logger.record("File exporter started", diagnostic.INFO, _MODULE)

	try:
		currentDatetime = datetime.datetime.now()
		midnight = int(datetime.datetime(currentDatetime.year, currentDatetime.month, currentDatetime.day).timestamp())

		# Get stations from database
		stations = []
		records = db.getStationRecords()
		for stationName in records:
			stations.append(stationName)

		if len(stations) == 0:
			raise Exception("No stations in database")

		# Get all data from the database
		dataPerStation = {}

		for station in stations:
			if station not in dataPerStation:
				dataPerStation[station] = {}
				dataPerStation[station]["precipitationAvailable"] = False
				dataPerStation[station]["temperatureAvailable"] = False
				dataPerStation[station]["humidityAvailable"] = False
				dataPerStation[station]["windSpeedAvailable"] = False
				dataPerStation[station]["windDirectionAvailable"] = False

			for i in range(midnight - 30 * 86400, midnight, 86400): 

				dataPerStation[station][i] = {}

				instantaneousData = db.getAverageInstantaneousDataOfStationInPeriod(station, i, i + 86400)
				periodicData = db.getSumPeriodicDataOfStationInPeriod(station, i, i + 86400)
				minMaxTemp = db.getMinMaxTemperatureOfStationInPeriod(station, i, i + 86400)

				if instantaneousData == None:
					logger.record(f"No instantaneous data for station {station} in period {i} - {i + 86400}", diagnostic.WARNING, _MODULE)
				else:
					for key in instantaneousData:
						if key == "Temperature" and instantaneousData[key] != None:
							dataPerStation[station]["temperatureAvailable"] = True
						elif key == "Humidity" and instantaneousData[key] != None:
							dataPerStation[station]["humidityAvailable"] = True
						elif key == "WindSpeed" and instantaneousData[key] != None:
							dataPerStation[station]["windSpeedAvailable"] = True
						elif key == "WindDirection" and instantaneousData[key] != None:
							dataPerStation[station]["windDirectionAvailable"] = True
					
						if instantaneousData[key] != None:
							if key != "WindSpeed":
								dataPerStation[station][i][key] = round(instantaneousData[key], 2)
							else:
								dataPerStation[station][i][key] = round(instantaneousData[key] * 3.6, 2)
						else:
							dataPerStation[station][i][key] = None

				if minMaxTemp == None:
					logger.record(f"No min max temperature for station {station} in period {i} - {i + 86400}", diagnostic.WARNING, _MODULE)
				else:
					for key in minMaxTemp:
						if minMaxTemp[key] != None:
							dataPerStation[station][i][key] = round(minMaxTemp[key], 2)
						else:
							dataPerStation[station][i][key] = None   

				if periodicData == None:       
					logger.record(f"No periodic data for station {station} in period {i} - {i + 86400}", diagnostic.WARNING, _MODULE)
				else:
					for key in periodicData:
						if key == "Precipitation" and periodicData[key] != None:
							dataPerStation[station]["precipitationAvailable"] = True
						
						if periodicData[key] != None:
							dataPerStation[station][i][key] = round(periodicData[key], 2)      
						else:
							dataPerStation[station][i][key] = None

		workbook = xlsxwriter.Workbook("/home/kerolla/Mushrooms/client/mushroomsDataExport.xlsx")
		worksheet = workbook.add_worksheet()
		worksheet.set_column(1, 1, 19)
		worksheet.set_column(2, 8, 15)
		station_name_format = workbook.add_format({'bold': True, 'align': 'center'})
		cell_format = workbook.add_format({'align': 'center', })

		row_index = 1     # line 2

		try:
			for station in stations:
				row_index += 1
				column_index = 66   # column B

				worksheet.write_string(f'{chr(column_index)}{row_index}', station, station_name_format)
				row_index += 2
				column_index = 67

				if dataPerStation[station]["precipitationAvailable"] == True:
					worksheet.write_string(f'{chr(column_index)}{row_index}', "Pioggia", cell_format)
					column_index += 1
				if dataPerStation[station]["temperatureAvailable"] == True:
					worksheet.write_string(f'{chr(column_index)}{row_index}', "Temp", cell_format)
					worksheet.write_string(f'{chr(column_index+1)}{row_index}', "Min Temp", cell_format)
					worksheet.write_string(f'{chr(column_index+2)}{row_index}', "Max Temp", cell_format)
					column_index += 3
				if dataPerStation[station]["humidityAvailable"] == True:
					worksheet.write_string(f'{chr(column_index)}{row_index}', "Umidità", cell_format)
					column_index += 1
				if dataPerStation[station]["windSpeedAvailable"] == True:
					worksheet.write_string(f'{chr(column_index)}{row_index}', "Vel. Vento", cell_format)
					column_index += 1
				if dataPerStation[station]["windDirectionAvailable"] == True:
					worksheet.write_string(f'{chr(column_index)}{row_index}', "Direz. Vento", cell_format)
					column_index += 1
				
				row_index += 1

				for i in range(midnight - 30 * 86400, midnight, 86400):
					column_index = 66
					worksheet.write_string(f'{chr(column_index)}{row_index}', datetime.datetime.fromtimestamp(i).strftime("%d/%m/%Y"), cell_format)
					
					column_index = 67
	
					if dataPerStation[station]["precipitationAvailable"] == True:
						value = "-"
						
						if "Precipitation" in dataPerStation[station][i]:
							if dataPerStation[station][i]["Precipitation"] != None:
								value = dataPerStation[station][i]["Precipitation"]
								worksheet.write_number(f'{chr(column_index)}{row_index}', dataPerStation[station][i]["Precipitation"], cell_format)

						if value == "-":
							worksheet.write_string(f'{chr(column_index)}{row_index}', value, cell_format)
						
						column_index += 1

					if dataPerStation[station]["temperatureAvailable"] == True:
						value = "-"

						if "Temperature" in dataPerStation[station][i]:
							if dataPerStation[station][i]["Temperature"] != None:
								value = dataPerStation[station][i]["Temperature"]
								worksheet.write_number(f'{chr(column_index)}{row_index}', dataPerStation[station][i]["Temperature"], cell_format)

						if value == "-":
							worksheet.write_string(f'{chr(column_index)}{row_index}', value, cell_format)
						
						column_index += 1

						value = "-"

						if "MinTemp" in dataPerStation[station][i]:
							if dataPerStation[station][i]["MinTemp"] != None:
								value = dataPerStation[station][i]["MinTemp"]
								worksheet.write_number(f'{chr(column_index)}{row_index}', dataPerStation[station][i]["MinTemp"], cell_format)
						
						if value == "-":
							worksheet.write_string(f'{chr(column_index)}{row_index}', value, cell_format)
						
						column_index += 1

						value = "-"

						if "MaxTemp" in dataPerStation[station][i]:
							if dataPerStation[station][i]["MaxTemp"] != None:
								value = dataPerStation[station][i]["MaxTemp"]
								worksheet.write_number(f'{chr(column_index)}{row_index}', dataPerStation[station][i]["MaxTemp"], cell_format)
						
						if value == "-":
							worksheet.write_string(f'{chr(column_index)}{row_index}', value, cell_format)
						
						column_index += 1

					if dataPerStation[station]["humidityAvailable"] == True:
						value = "-"

						if "Humidity" in dataPerStation[station][i]:
							if dataPerStation[station][i]["Humidity"] != None:
								value = dataPerStation[station][i]["Humidity"]
								worksheet.write_number(f'{chr(column_index)}{row_index}', dataPerStation[station][i]["Humidity"], cell_format)

						if value == "-":
							worksheet.write_string(f'{chr(column_index)}{row_index}', value, cell_format)
						
						column_index += 1
					
					if dataPerStation[station]["windSpeedAvailable"] == True:
						value = "-"

						if "WindSpeed" in dataPerStation[station][i]:
							if dataPerStation[station][i]["WindSpeed"] != None:
								value = dataPerStation[station][i]["WindSpeed"]
								worksheet.write_number(f'{chr(column_index)}{row_index}', dataPerStation[station][i]["WindSpeed"], cell_format)

						if value == "-":
							worksheet.write_string(f'{chr(column_index)}{row_index}', value, cell_format)
						
						column_index += 1
					
					if dataPerStation[station]["windDirectionAvailable"] == True:
						value = "-"

						if "WindDirection" in dataPerStation[station][i]:
							if dataPerStation[station][i]["WindDirection"] != None:
								value = dataPerStation[station][i]["WindDirection"]
								worksheet.write_number(f'{chr(column_index)}{row_index}', dataPerStation[station][i]["WindDirection"], cell_format)

						if value == "-":
							worksheet.write_string(f'{chr(column_index)}{row_index}', value, cell_format)
						
						column_index += 1
					
					row_index += 1

				row_index += 1

		except Exception as e:
			logger.record("Exception occured while working on file excel", diagnostic.ERROR, _MODULE, exc= e)
		finally:
			workbook.close()

	except Exception as e:
		logger.record("Exception occured in main function", diagnostic.ERROR, _MODULE, exc= e)

	logger.record("File exporter ended", diagnostic.INFO, _MODULE)

if __name__ == "__main__":
	import sys
	arguments = len(sys.argv) - 1
	if arguments > 0:
		import ptvsd
		# Allow other computers to attach to ptvsd at this IP address and port.
		ptvsd.enable_attach(address=('192.168.1.177', 3001))
		# Pause the program until a remote debugger is attached	
		ptvsd.wait_for_attach()

	logger = diagnostic.Diagnostic("/home/kerolla/Mushrooms/client/logger_exporter.txt", diagnostic.DEBUG)

	db = database.DatabaseHandler(logger= logger)
	db.open(host= "127.0.0.1", username= "root", password= "Vialedellapace14!", port= 3306, databaseName= "Mushrooms", connectionsPoolName= "MSR", numberOfConnectionsInPool= 20)

	main(logger= logger, db= db)