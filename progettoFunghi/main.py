#!/usr/bin/python3.9

import requests, json, time, datetime, os.path, subprocess, logging

python_packages_installed = False
python_packages_exception = None
if os.path.isfile("./requirements.txt"):
		for i in range(0, 3):
			try:
				subprocess.check_call(["/usr/bin/pip", "install", "-r", "requirements.txt"])
			except subprocess.CalledProcessError as e:
				python_packages_exception = e
			else:
				python_packages_installed = True
				break

import diagnostic, database
from constants import DATA_CODES, STATION_CODES

MODULE = "MAIN"

URL = "https://dati-simc.arpae.it/opendata/osservati/meteo/realtime/realtime.jsonl"

STATIONS = ["Civago","Ospitaletto","Lago Paduli","Sassostorno","Doccia di Fiumalbo","Ligonchio","Frassinoro","Febbio","Collagna","Lago Scaffaiolo Nivo","Lago Scaffaiolo",
			"Villa Minozzo","Passo delle Radici","Sestola","Pievepelago","Succiso","Isola Palanzano","Ramiseto","Monteacuto delle Alpi","Piandelagotti",
			"Lago Pratignano"]

# General info
DATE_KEY = "date"
DATA_KEY = "data"
GENERIC_VALUE_KEY = "v"
TIMERANGE_INFO_KEY = "timerange"

#DATA_CODES = {"B12101": DATA_KEYS.TEMPERATURE, "B01019": STATION_NAME_KEY, "B05001": STATION_LATITUDE_KEY, "B06001": STATION_LONGITUDE_KEY, "B13011": PRECIPITATION_KEY, "B07030": STATION_ALTITUDE_KEY, "B13003": RELATIVE_HUMIDITY_KEY, "B11001": WIND_DIRECTION_KEY, "B11002": WIND_SPEED_KEY}

def main(logger: diagnostic.Diagnostic, db: database.DatabaseHandler):
	
	firstRound = True

	while True:
		try:
			if firstRound == False:
				time.sleep(60 * 60)
			else:
				firstRound = False

			logger.record(msg= f"INIZIO PROCESSO {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", logLevel= diagnostic.INFO, module= MODULE)

			stationsInfo = db.getStationRecords()

			req = requests.get(url=URL)
			if req.status_code == 200:
				data = req.text

				for record in data.split('\n'):
					try:
						if record == "":
							continue

						jsonRecord = json.loads(record)
						if DATE_KEY not in jsonRecord:
							raise Exception(f"Date key not present in {jsonRecord}")
						elif DATA_KEY not in jsonRecord:
							raise Exception(f"Data key not present in {jsonRecord}")
						elif "Z" not in jsonRecord[DATE_KEY]:
							raise Exception(f"Z not present in {jsonRecord[DATE_KEY]}")
						
						datetimeString = jsonRecord[DATE_KEY].replace("Z", "+00:00")
						datetimeObject = datetime.datetime.fromisoformat(datetimeString)
						startTimestamp = int(datetimeObject.timestamp())

						stationName = None
						stationLatitude = None
						stationLongitude = None
						stationAltitude = None

						dataInRecord = jsonRecord[DATA_KEY]

						instantaneousData = {"Temperature": None, "Humidity": None, "WindDirection": None, "WindSpeed": None}
						accumulationData = {"Timerange": None, "EndTimestamp": None, "Precipitation": None}

						for dataElem in dataInRecord:
							
							# Station info
							if "vars" in dataElem and "timerange" not in dataElem and "level" not in dataElem:
								if STATION_CODES.NAME not in dataElem["vars"]:
									raise Exception(f"Station name not present in {dataElem}")
								elif STATION_CODES.LATITUDE not in dataElem["vars"]:
									raise Exception(f"Station latitude not present in {dataElem}")
								elif STATION_CODES.LONGITUDE not in dataElem["vars"]:
									raise Exception(f"Station longitude not present in {dataElem}")
								elif STATION_CODES.ALTITUDE not in dataElem["vars"]:
									raise Exception(f"Station altitude not present in {dataElem}")
								
								stationName = dataElem["vars"][STATION_CODES.NAME][GENERIC_VALUE_KEY]
								stationLatitude = dataElem["vars"][STATION_CODES.LATITUDE][GENERIC_VALUE_KEY]
								stationLongitude = dataElem["vars"][STATION_CODES.LONGITUDE][GENERIC_VALUE_KEY]
								stationAltitude = dataElem["vars"][STATION_CODES.ALTITUDE][GENERIC_VALUE_KEY]

							elif "vars" in dataElem and "timerange" in dataElem and "level" in dataElem:
								if dataElem["timerange"][0] == 1 and DATA_CODES.PRECIPITATION in dataElem["vars"]:
									if accumulationData["Timerange"] == None or accumulationData["Timerange"] > dataElem["timerange"][2]:
										accumulationData["Precipitation"] = dataElem["vars"][DATA_CODES.PRECIPITATION][GENERIC_VALUE_KEY]
										accumulationData["EndTimestamp"] = startTimestamp + dataElem["timerange"][2]
										accumulationData["Timerange"] = dataElem["timerange"][2]

								elif dataElem["timerange"][0] == 254:
									if DATA_CODES.TEMPERATURE in dataElem["vars"] and instantaneousData["Temperature"] == None:
										instantaneousData["Temperature"] = dataElem["vars"][DATA_CODES.TEMPERATURE][GENERIC_VALUE_KEY]
									if DATA_CODES.RELATIVE_HUMIDITY in dataElem["vars"] and instantaneousData["Humidity"] == None:
										instantaneousData["Humidity"] = dataElem["vars"][DATA_CODES.RELATIVE_HUMIDITY][GENERIC_VALUE_KEY]
									if DATA_CODES.WIND_DIRECTION in dataElem["vars"] and instantaneousData["WindDirection"] == None:
										instantaneousData["WindDirection"] = dataElem["vars"][DATA_CODES.WIND_DIRECTION][GENERIC_VALUE_KEY]
									if DATA_CODES.WIND_SPEED in dataElem["vars"] and instantaneousData["WindSpeed"] == None:
										instantaneousData["WindSpeed"] = dataElem["vars"][DATA_CODES.WIND_SPEED][GENERIC_VALUE_KEY]
							else:
								raise Exception(f"Invalid {dataElem}")
						
						if stationName is None:
							raise Exception(f"Station name not present in {jsonRecord}")
						elif stationName != None and stationName not in STATIONS:
							continue
						elif stationName not in stationsInfo:
							if stationLatitude is None:
								raise Exception(f"Station latitude not present in {jsonRecord}")
							elif stationLongitude is None:
								raise Exception(f"Station longitude not present in {jsonRecord}")
							elif stationAltitude is None:
								raise Exception(f"Station altitude not present in {jsonRecord}")
							else:
								db.addNewStationRecords([{"Name": stationName, "Latitude": stationLatitude, "Longitude": stationLongitude, "Altitude": stationAltitude}])
								stationsInfo = db.getStationRecords()
						elif startTimestamp <= stationsInfo[stationName]["LastUpdate"]:
							continue

						if accumulationData["Precipitation"] != None:
							db.storePeriodicDataRecords([{"StationName": stationName, "StartTimestamp": startTimestamp, "EndTimestamp": accumulationData["EndTimestamp"], "Precipitation": accumulationData["Precipitation"]}])
							# per il futuro
							if stationName in ["Lago Scaffaiolo Nivo"]:
								logger.record(msg= f"LAGO SCAFFOIOLO NIVO HA INVIATO DATI DI PIOGGIA PER LA PRIMA VOLTA!!!!!!!!!!!. Record: {record}", logLevel= diagnostic.INFO, module= MODULE)
						elif stationName in ["Lago Scaffaiolo Nivo"]:
							pass
						else:
							raise Exception(f"Accumulation data are none. Station name: {stationName}. Line: {record}")

						if any(value != None for value in instantaneousData.values()):
							db.storeInstantaneousDataRecords([{"StationName": stationName, "Timestamp": startTimestamp, "Temperature": instantaneousData["Temperature"], "Humidity": instantaneousData["Humidity"], "WindDirection": instantaneousData["WindDirection"], "WindSpeed": instantaneousData["WindSpeed"]}])
							# per il futuro
							if stationName in ["Lago Scaffaiolo", "Passo delle Radici", "Sestola", "Pievepelago", "Succiso", "Isola Palanzano", "Lago Paduli", "Frassinoro", "Sassostorno", "Doccia di Fiumalbo", "Ligonchio", "Febbio", "Collagna", "Villa Minozzo", "Ramiseto", "Piandelagotti", "Lago Pratignano", "Civago", "Ospitaletto", "Monteacuto delle Alpi"] and datetimeObject.minute in [15, 45]:
								logger.record(msg= f"{stationName.upper()} HA INVIATO DATI AI MINUTI 15 O 45 LA PRIMA VOLTA!!!!!!!!!!!. Record: {record}", logLevel= diagnostic.INFO, module= MODULE)
						elif stationName in ["Lago Scaffaiolo", "Passo delle Radici", "Sestola", "Pievepelago", "Succiso", "Isola Palanzano", "Lago Paduli", "Frassinoro", "Sassostorno", "Doccia di Fiumalbo", "Ligonchio", "Febbio", "Collagna", "Villa Minozzo", "Ramiseto", "Piandelagotti", "Lago Pratignano", "Civago", "Ospitaletto", "Monteacuto delle Alpi"] and datetimeObject.minute in [15, 45]:
							pass
						else:
							raise Exception(f"Instantaneous data are none. Station name: {stationName}. Line: {record}")

						db.updateLastUpdateOfStationRecords([{"Name": stationName, "LastUpdate": startTimestamp}])

					except Exception as e:
						logger.record(msg= f"Error while parsing data record. Record: {record}", logLevel= diagnostic.ERROR, module= MODULE, exc= e)
						continue
			else:
				logger.record(msg= f"Impossible to request data. Status code: {req.status_code}. Text: {req.text}", logLevel= diagnostic.ERROR, module= MODULE)
		except Exception as e:
			logger.record(msg= f"Error while fetching data", logLevel= diagnostic.CRITICAL, module= MODULE, exc= e)

		logger.record(msg= f"FINE PROCESSO {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", logLevel= diagnostic.INFO, module= MODULE)

if __name__ == "__main__":
	# Install python packages
	
	logger = diagnostic.Diagnostic("./logger.txt", diagnostic.DEBUG)

	if python_packages_installed == False and python_packages_exception == None:
		if os.path.isfile("requirements.txt") == False:
			logger.record(msg=f"Impossible to install python packages because requirements.txt file is missing", logLevel= diagnostic.CRITICAL, module=MODULE)
		if os.path.isfile("/usr/bin/pip") == False:
			logger.record(msg=f"Impossible to install python packages because pip is missing", logLevel= diagnostic.CRITICAL, module=MODULE)
	elif python_packages_installed == False and python_packages_exception != None:
		logger.record(msg=f"Impossible to install python packages. Exception while installing: {python_packages_exception}", logLevel= diagnostic.CRITICAL, module=MODULE)
	else:
		logger.record(msg="Python packages installed", logLevel= diagnostic.DEBUG, module=MODULE)

	logging.getLogger("urllib3").setLevel(logging.WARNING)
	logging.getLogger("requests").setLevel(logging.WARNING)

	db = database.DatabaseHandler(logger= logger)
	db.open(host= "127.0.0.1", username= "root", password= "MartinaFederico1vs1!", port= 3306, databaseName= "Mushrooms", connectionsPoolName= "MSR", numberOfConnectionsInPool= 20)

	main(logger= logger, db= db)