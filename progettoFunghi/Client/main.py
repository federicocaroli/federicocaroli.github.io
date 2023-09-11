#!/usr/bin/python3.9

import requests, json, time, datetime, os.path, subprocess, logging, re

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
from constants import DATA_CODES, STATION_CODES, TOSCANA_DATA_HTTP_KEYS

MODULE = "MAIN"

'''Emilia Romagna'''

ER_URL = "https://dati-simc.arpae.it/opendata/osservati/meteo/realtime/realtime.jsonl"

ER_STATIONS = ["Civago","Ospitaletto","Lago Paduli","Sassostorno","Doccia di Fiumalbo","Ligonchio","Frassinoro","Febbio","Collagna","Lago Scaffaiolo Nivo","Lago Scaffaiolo",
			"Villa Minozzo","Passo delle Radici","Sestola","Pievepelago","Succiso","Isola Palanzano","Ramiseto","Monteacuto delle Alpi","Piandelagotti",
			"Lago Pratignano"]

ER_DATE_KEY = "date"
ER_DATA_KEY = "data"
ER_GENERIC_VALUE_KEY = "v"
ER_TIMERANGE_INFO_KEY = "timerange"

'''Toscana'''

TOSCANA_STATIONS = {
	"Alpe del Pellegrino": "TOS11000106",
	"Passo Radici": "TOS30355400",
	"Passo del Cerreto": "TOS09001160",
	"Passo Pradarena": "TOS02000155",
	"Capanne di Sillano": "TOS02000161",
	"Casone di Profecchia": "TOS02000221",
	"Monte Romecchio": "TOS02000275",
	"Foce a Giovo": "TOS03000335",
	"Renaio": "TOS03000278"
}
TOSCANA_DATA_PER_STATION = {
	"Alpe del Pellegrino": [TOSCANA_DATA_HTTP_KEYS.PRECIPIATION, TOSCANA_DATA_HTTP_KEYS.TEMPERATURE, TOSCANA_DATA_HTTP_KEYS.WIND, TOSCANA_DATA_HTTP_KEYS.UMIDITY],
	"Passo Radici": [TOSCANA_DATA_HTTP_KEYS.PRECIPIATION],
	"Passo del Cerreto": [TOSCANA_DATA_HTTP_KEYS.PRECIPIATION, TOSCANA_DATA_HTTP_KEYS.TEMPERATURE],
	"Passo Pradarena": [TOSCANA_DATA_HTTP_KEYS.PRECIPIATION],
	"Capanne di Sillano": [TOSCANA_DATA_HTTP_KEYS.PRECIPIATION],
	"Casone di Profecchia": [TOSCANA_DATA_HTTP_KEYS.PRECIPIATION, TOSCANA_DATA_HTTP_KEYS.TEMPERATURE, TOSCANA_DATA_HTTP_KEYS.UMIDITY],
	"Monte Romecchio": [TOSCANA_DATA_HTTP_KEYS.PRECIPIATION, TOSCANA_DATA_HTTP_KEYS.WIND],
	"Foce a Giovo": [TOSCANA_DATA_HTTP_KEYS.PRECIPIATION, TOSCANA_DATA_HTTP_KEYS.TEMPERATURE, TOSCANA_DATA_HTTP_KEYS.WIND, TOSCANA_DATA_HTTP_KEYS.UMIDITY],
	"Renaio": [TOSCANA_DATA_HTTP_KEYS.PRECIPIATION, TOSCANA_DATA_HTTP_KEYS.TEMPERATURE, TOSCANA_DATA_HTTP_KEYS.WIND, TOSCANA_DATA_HTTP_KEYS.UMIDITY]
}
TOSCANA_GENERIC_URl = "http://www.sir.toscana.it/monitoraggio/dettaglio.php?"
TOSCANA_RECORD_PATTERN = re.compile(r".*VALUES\[\d+\] = new Array\(\"\d+\",\"(.*)\",\"(.*)\",\"(.*)\"\);.*")


def main(logger: diagnostic.Diagnostic, db: database.DatabaseHandler):
	
	firstRound = True

	if any(TOSCANA_DATA_HTTP_KEYS.PRECIPIATION not in TOSCANA_DATA_PER_STATION[station] for station in TOSCANA_DATA_PER_STATION):
		raise Exception(f"Every station must have precipitation data")

	station_to_add = list()

	for station in station_to_add:
		if station["Name"] not in db.getStationRecords():
			db.addNewStationRecords([station])

	while True:
		try:
			if firstRound == False:
				time.sleep(15 * 60)
			else:
				firstRound = False

			logger.record(msg= f"INIZIO PROCESSO {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", logLevel= diagnostic.INFO, module= MODULE)
			emiliaRomagna(logger= logger, db= db)
			toscana(logger= logger, db= db)
			logger.record(msg= f"FINE PROCESSO {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", logLevel= diagnostic.INFO, module= MODULE)

		except Exception as e:
			print(f"Exception: {e}")
		
def emiliaRomagna(logger: diagnostic.Diagnostic, db: database.DatabaseHandler):
	if isinstance(logger, diagnostic.Diagnostic) == False or isinstance(db, database.DatabaseHandler) == False:
		raise TypeError(f"Invalid arguments. logger: {logger}, db: {db}")
	
	periodicRowAdded = 0
	instantaneousRowAdded = 0

	try:
		stationsInfo = db.getStationRecords()

		req = requests.get(url=ER_URL)
		if req.status_code == 200:
			data = req.text

			for record in data.split('\n'):
				try:
					if record == "":
						continue

					jsonRecord = json.loads(record)
					if ER_DATE_KEY not in jsonRecord:
						raise Exception(f"Date key not present in {jsonRecord}")
					elif ER_DATA_KEY not in jsonRecord:
						raise Exception(f"Data key not present in {jsonRecord}")
					elif "Z" not in jsonRecord[ER_DATE_KEY]:
						raise Exception(f"Z not present in {jsonRecord[ER_DATE_KEY]}")
					
					datetimeString = jsonRecord[ER_DATE_KEY].replace("Z", "+00:00")
					datetimeObject = datetime.datetime.fromisoformat(datetimeString)
					endTimestamp = int(datetimeObject.timestamp())

					stationName = None
					stationLatitude = None
					stationLongitude = None
					stationAltitude = None

					instantaneousData = {"Temperature": None, "Humidity": None, "WindDirection": None, "WindSpeed": None}
					accumulationData = {"Timerange": None, "StartTimestamp": None, "Precipitation": None}

					for dataElem in jsonRecord[ER_DATA_KEY]:
						
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
							
							stationName = dataElem["vars"][STATION_CODES.NAME][ER_GENERIC_VALUE_KEY]
							stationLatitude = dataElem["vars"][STATION_CODES.LATITUDE][ER_GENERIC_VALUE_KEY]
							stationLongitude = dataElem["vars"][STATION_CODES.LONGITUDE][ER_GENERIC_VALUE_KEY]
							stationAltitude = dataElem["vars"][STATION_CODES.ALTITUDE][ER_GENERIC_VALUE_KEY]

						# data values
						elif "vars" in dataElem and "timerange" in dataElem and "level" in dataElem:
							if dataElem["timerange"][0] == 1 and DATA_CODES.PRECIPITATION in dataElem["vars"]:
								if accumulationData["Timerange"] == None or accumulationData["Timerange"] > dataElem["timerange"][2]:
									accumulationData["Precipitation"] = dataElem["vars"][DATA_CODES.PRECIPITATION][ER_GENERIC_VALUE_KEY]
									accumulationData["StartTimestamp"] = endTimestamp - dataElem["timerange"][2]
									accumulationData["Timerange"] = dataElem["timerange"][2]

							elif dataElem["timerange"][0] == 254:
								if DATA_CODES.TEMPERATURE in dataElem["vars"] and instantaneousData["Temperature"] == None and dataElem["vars"][DATA_CODES.TEMPERATURE][ER_GENERIC_VALUE_KEY] != None:
									instantaneousData["Temperature"] = dataElem["vars"][DATA_CODES.TEMPERATURE][ER_GENERIC_VALUE_KEY] - 273.15
									if instantaneousData["Temperature"] < 0:
										raise Exception(f"Temperature value is negative. Record: {jsonRecord}")
								elif DATA_CODES.TEMPERATURE in dataElem["vars"] and instantaneousData["Temperature"] != None:
									logger.record(msg= f"Duplicated Temperature in the same record. Record: {jsonRecord}", logLevel= diagnostic.WARNING, module= MODULE)
								
								if DATA_CODES.RELATIVE_HUMIDITY in dataElem["vars"] and instantaneousData["Humidity"] == None and dataElem["vars"][DATA_CODES.RELATIVE_HUMIDITY][ER_GENERIC_VALUE_KEY] != None:
									instantaneousData["Humidity"] = dataElem["vars"][DATA_CODES.RELATIVE_HUMIDITY][ER_GENERIC_VALUE_KEY]
								elif DATA_CODES.RELATIVE_HUMIDITY in dataElem["vars"] and instantaneousData["Humidity"] != None:
									logger.record(msg= f"Duplicated Humidity in the same record. Record: {jsonRecord}", logLevel= diagnostic.WARNING, module= MODULE)
								
								if DATA_CODES.WIND_DIRECTION in dataElem["vars"] and instantaneousData["WindDirection"] == None and dataElem["vars"][DATA_CODES.WIND_DIRECTION][ER_GENERIC_VALUE_KEY] != None:
									instantaneousData["WindDirection"] = dataElem["vars"][DATA_CODES.WIND_DIRECTION][ER_GENERIC_VALUE_KEY]
								elif DATA_CODES.WIND_DIRECTION in dataElem["vars"] and instantaneousData["WindDirection"] != None:
									logger.record(msg= f"Duplicated WindDirection in the same record. Record: {jsonRecord}", logLevel= diagnostic.WARNING, module= MODULE)
								
								if DATA_CODES.WIND_SPEED in dataElem["vars"] and instantaneousData["WindSpeed"] == None and dataElem["vars"][DATA_CODES.WIND_SPEED][ER_GENERIC_VALUE_KEY] != None:
									instantaneousData["WindSpeed"] = dataElem["vars"][DATA_CODES.WIND_SPEED][ER_GENERIC_VALUE_KEY]
								elif DATA_CODES.WIND_SPEED in dataElem["vars"] and instantaneousData["WindSpeed"] != None:
									logger.record(msg= f"Duplicated WindSpeed in the same record. Record: {jsonRecord}", logLevel= diagnostic.WARNING, module= MODULE)
						else:
							logger.record(msg= f"Emilia Romagna: Unknown record format. Record: {jsonRecord}", logLevel= diagnostic.WARNING, module= MODULE)
					
					if stationName is None:
						raise Exception(f"Station name not present in {jsonRecord}")
					elif stationName not in ER_STATIONS:
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
					elif endTimestamp <= stationsInfo[stationName]["LastUpdate"]:
						continue

					saveAccumulationData = True
					saveInstantaneousData = True
					updateLastUpdate = True

					try:
						if accumulationData["Precipitation"] == None:
							saveAccumulationData = False
							if stationName in ["Lago Scaffaiolo Nivo"]:
								pass
							else:
								raise Exception(f"Accumulation data are none. Station name: {stationName}")
						else:
							if accumulationData["Timerange"] != 900:
								raise Exception(f"{stationName.upper()} vuole inviare dati periodici con periodicità diversa da 15 min")

							# per cambiamenti dell'API future
							if stationName in ["Lago Scaffaiolo Nivo"]:
								logger.record(msg= f"LAGO SCAFFOIOLO NIVO HA INVIATO DATI PERIODICI PER LA PRIMA VOLTA!!!!!!!!!!!. Record: {jsonRecord}", logLevel= diagnostic.INFO, module= MODULE)

					except Exception as e:
						if datetimeObject.hour not in [8, 0] or datetimeObject.minute != 0:
							logger.record(msg= f"Emilia Romagna: Error while checking accumulation data. Record: {jsonRecord}", logLevel= diagnostic.ERROR, module= MODULE, exc= e)
						updateLastUpdate = False
						saveAccumulationData = False

					try:
						if all(value == None for value in instantaneousData.values()):
							saveInstantaneousData = False
							if stationName in ["Lago Scaffaiolo", "Passo delle Radici", "Sestola", "Pievepelago", "Isola Palanzano", "Lago Paduli", "Frassinoro", "Sassostorno", "Doccia di Fiumalbo", "Ligonchio", "Febbio", "Collagna", "Villa Minozzo", "Ramiseto", "Piandelagotti", "Lago Pratignano", "Civago", "Ospitaletto", "Monteacuto delle Alpi"] and datetimeObject.minute in [15, 45]:
								pass
							elif stationName in ["Succiso"]:
								pass
							else:
								raise Exception(f"Instantaneous data are none. Station name: {stationName}")
						else:
							# per cambiamenti dell'API future
							if stationName in ["Lago Scaffaiolo", "Passo delle Radici", "Sestola", "Pievepelago", "Isola Palanzano", "Lago Paduli", "Frassinoro", "Sassostorno", "Doccia di Fiumalbo", "Ligonchio", "Febbio", "Collagna", "Villa Minozzo", "Ramiseto", "Piandelagotti", "Lago Pratignano", "Civago", "Ospitaletto", "Monteacuto delle Alpi"] and datetimeObject.minute in [15, 45]:
								logger.record(msg= f"{stationName.upper()} HA INVIATO DATI INSTANTANETI PER LA PRIMA VOLTA AI 15 O 45!!!!!!!!!!!. Record: {jsonRecord}", logLevel= diagnostic.INFO, module= MODULE)
							elif stationName in ["Succiso"]:
								logger.record(msg= f"{stationName.upper()} HA INVIATO DATI INSTANTANETI PER LA PRIMA VOLTA!!!!!!!!!!!. Record: {jsonRecord}", logLevel= diagnostic.INFO, module= MODULE)
					except Exception as e:
						if datetimeObject.hour not in [8, 0] or datetimeObject.minute != 0:
							logger.record(msg= f"Emilia Romagna: Error while checking instantaneous data. Record: {jsonRecord}", logLevel= diagnostic.ERROR, module= MODULE, exc= e)
						saveInstantaneousData = False
						updateLastUpdate = False

					if saveAccumulationData == True:
						db.storePeriodicDataRecords([{"StationName": stationName, "StartTimestamp": accumulationData["StartTimestamp"], "EndTimestamp": endTimestamp, "Precipitation": accumulationData["Precipitation"]}])
						periodicRowAdded += 1

					if saveInstantaneousData == True:
						db.storeInstantaneousDataRecords([{"StationName": stationName, "Timestamp": endTimestamp, "Temperature": instantaneousData["Temperature"], "Humidity": instantaneousData["Humidity"], "WindDirection": instantaneousData["WindDirection"], "WindSpeed": instantaneousData["WindSpeed"]}])
						instantaneousRowAdded += 1
					
					if updateLastUpdate == True:
						db.updateLastUpdateOfStationRecords([{"Name": stationName, "LastUpdate": endTimestamp}])

				except Exception as e:
					logger.record(msg= f"Emilia Romagna: Error while parsing data record. Record: {jsonRecord}", logLevel= diagnostic.ERROR, module= MODULE, exc= e)
		else:
			raise Exception(f"Impossible to request data. Status code: {req.status_code}. Text: {req.text}")
	except Exception as e:
		logger.record(msg= f"Emilia Romagna: Error while fetching data", logLevel= diagnostic.CRITICAL, module= MODULE, exc= e)
	else:
		logger.record(msg= f"Emilia Romagna: Periodic data added: {periodicRowAdded}. Instantaneous data added: {instantaneousRowAdded}", logLevel= diagnostic.INFO, module= MODULE)

def toscana(logger: diagnostic.Diagnostic, db: database.DatabaseHandler):
	if isinstance(logger, diagnostic.Diagnostic) == False or isinstance(db, database.DatabaseHandler) == False:
		raise TypeError(f"Invalid arguments. logger: {logger}, db: {db}")
	
	precipitationRowsPerStation = dict()
	temperatureRowsPerStation = dict()
	windDirectionRowsPerStation = dict()
	windSpeedRowsPerStation = dict()
	umidityRowsPerStation = dict()

	periodicRowAdded = 0
	instantaneousRowAdded = 0

	try:
		stationsInfo = db.getStationRecords()

		for station in TOSCANA_STATIONS:
			try:
				if station in precipitationRowsPerStation:
					raise Exception(f"Station {station} already present in precipitationRowsPerStation")
				elif station in temperatureRowsPerStation:
					raise Exception(f"Station {station} already present in temperatureRowsPerStation")
				elif station in windDirectionRowsPerStation:
					raise Exception(f"Station {station} already present in windDirectionRowsPerStation")
				elif station in windSpeedRowsPerStation:
					raise Exception(f"Station {station} already present in windSpeedRowsPerStation")
				elif station in umidityRowsPerStation:
					raise Exception(f"Station {station} already present in umidityRowsPerStation")
				
				precipitationRowsPerStation[station] = dict()
				temperatureRowsPerStation[station] = dict()
				windDirectionRowsPerStation[station] = dict()
				windSpeedRowsPerStation[station] = dict()
				umidityRowsPerStation[station] = dict()
					
				if station not in stationsInfo:
					raise Exception(f"Station {station} not present in db")

				for dataHttpKey in TOSCANA_DATA_PER_STATION[station]:
					try:
						time.sleep(10)
						
						req = requests.get(url=f"{TOSCANA_GENERIC_URl}id={TOSCANA_STATIONS[station]}&title=&type={dataHttpKey}", headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.5790.102 Safari/537.36"})
						if req.status_code == 200:
							reply = req.text
							if "var VALUES = new Array();" not in reply:
								raise Exception(f"Unexpected reply")

							for line in reply.split('\n'):
								line = line.strip()

								matchResult = TOSCANA_RECORD_PATTERN.search(line)
								if matchResult:
									if matchResult.group(1) == "" or matchResult.group(2) == "":
										raise Exception(f"Unexpected empty line: {line}")

									datetimeObject = datetime.datetime.strptime(matchResult.group(1), "%d/%m/%Y %H.%M")
									timestamp = int(datetimeObject.timestamp())

									if timestamp <= stationsInfo[station]["LastUpdate"]:
										continue

									if dataHttpKey == TOSCANA_DATA_HTTP_KEYS.PRECIPIATION:
										if matchResult.group(3) != "":
											value = float(matchResult.group(3))
										else:
											value = 0.0
										
										if timestamp in precipitationRowsPerStation[station]:
											raise Exception(f"Duplicate precipitation record. timestamp: {timestamp}, value: {value}, dict: {precipitationRowsPerStation[station]}")

										precipitationRowsPerStation[station][timestamp] = value

									elif dataHttpKey == TOSCANA_DATA_HTTP_KEYS.TEMPERATURE:									
										value = float(matchResult.group(2))

										if timestamp in temperatureRowsPerStation[station]:
											raise Exception(f"Duplicate temperature record. timestamp: {timestamp}, value: {value}, dict: {temperatureRowsPerStation[station]}")
										
										temperatureRowsPerStation[station][timestamp] = value

									elif dataHttpKey == TOSCANA_DATA_HTTP_KEYS.WIND:
										if matchResult.group(3) == "":
											raise Exception(f"Unexpected empty wind direction. line: {line}")

										if "/" in matchResult.group(2):
											valueSpeed = float(matchResult.group(2).split("/")[0])
										else:
											valueSpeed = float(matchResult.group(2))
										
										valueDirection = float(matchResult.group(3))

										if timestamp in windDirectionRowsPerStation[station]:
											raise Exception(f"Duplicate wind direction record. timestamp: {timestamp}, value: {valueDirection}, dict: {windDirectionRowsPerStation[station]}")
										
										if timestamp in windSpeedRowsPerStation[station]:
											raise Exception(f"Duplicate wind speed record. timestamp: {timestamp}, value: {valueSpeed}, dict: {windSpeedRowsPerStation[station]}")
										
										windDirectionRowsPerStation[station][timestamp] = valueDirection
										windSpeedRowsPerStation[station][timestamp] = valueSpeed

									elif dataHttpKey == TOSCANA_DATA_HTTP_KEYS.UMIDITY:
										value = float(matchResult.group(2))

										if timestamp in umidityRowsPerStation[station]:
											raise Exception(f"Duplicate umidity record. timestamp: {timestamp}, value: {value}, dict: {umidityRowsPerStation[station]}")
										
										umidityRowsPerStation[station][timestamp] = value
									else:
										raise Exception(f"Unexpected dataHttpKey: {dataHttpKey}")

								elif "new Array(" in line and "VALUES[" in line:
									raise Exception(f"Expected line ignored: {line}")
						else:
							raise Exception(f"Impossible to request data. Status code: {req.status_code}. Text: {req.text}")
					except Exception as e:
						logger.record(msg=f"Toscana: Exception while fetching data of Station: {station} and Data: {dataHttpKey}", logLevel= diagnostic.CRITICAL, module=MODULE, exc= e)
						raise e
			except Exception as e:
				logger.record(msg= f"Toscana: Error while fetching data of Station: {station}", logLevel= diagnostic.CRITICAL, module= MODULE, exc= e)
			
		for station in TOSCANA_STATIONS:
			try:
				if len(precipitationRowsPerStation[station]) == 0:
					logger.record(msg= f"Toscana: Station: {station} doesn't have any precipitation record", logLevel= diagnostic.WARNING, module= MODULE)
					continue
				
				for timestampRecord in precipitationRowsPerStation[station]:
					try:
						temperature = None
						umidity = None
						windDirection = None
						windSpeed = None

						if TOSCANA_DATA_HTTP_KEYS.TEMPERATURE in TOSCANA_DATA_PER_STATION[station]:
							if timestampRecord not in temperatureRowsPerStation[station]:
								raise Exception(f"Temperature record not present for station: {station} and timestamp: {timestampRecord}")
							temperature = temperatureRowsPerStation[station][timestampRecord]
						
						if TOSCANA_DATA_HTTP_KEYS.UMIDITY in TOSCANA_DATA_PER_STATION[station]:
							if timestampRecord not in umidityRowsPerStation[station]:
								raise Exception(f"Umidity record not present for station: {station} and timestamp: {timestampRecord}")
							umidity = umidityRowsPerStation[station][timestampRecord]
						
						if TOSCANA_DATA_HTTP_KEYS.WIND in TOSCANA_DATA_PER_STATION[station]:
							if timestampRecord not in windDirectionRowsPerStation[station] or timestampRecord not in windSpeedRowsPerStation[station]:
								raise Exception(f"Wind direction/speed record not present for station: {station} and timestamp: {timestampRecord}")
							
							windDirection = windDirectionRowsPerStation[station][timestampRecord]
							windSpeed = windSpeedRowsPerStation[station][timestampRecord]

						if any(value != None for value in [temperature, umidity, windDirection, windSpeed]):
							db.storeInstantaneousDataRecords([{"StationName": station, "Timestamp": timestampRecord, "Temperature": temperature, "Humidity": umidity, "WindDirection": windDirection, "WindSpeed": windSpeed}])
							instantaneousRowAdded += 1

						db.storePeriodicDataRecords([{"StationName": station, "StartTimestamp": timestampRecord-900, "EndTimestamp": timestampRecord, "Precipitation": precipitationRowsPerStation[station][timestampRecord]}])
						db.updateLastUpdateOfStationRecords([{"Name": station, "LastUpdate": timestampRecord}])
						periodicRowAdded += 1

					except Exception as e:
						logger.record(msg= f"Toscana: Error while handling record of Station: {station} and Timestamp: {timestampRecord}", logLevel= diagnostic.ERROR, module= MODULE, exc= e)
			except Exception as e:
				logger.record(msg= f"Toscana: Error while handling data of Station: {station}", logLevel= diagnostic.CRITICAL, module= MODULE, exc= e)
	except Exception as e:
		logger.record(msg= f"Toscana: General exception", logLevel= diagnostic.CRITICAL, module= MODULE, exc= e)
	else:
		logger.record(msg= f"Toscana: Periodic data added: {periodicRowAdded}. Instantaneous data added: {instantaneousRowAdded}", logLevel= diagnostic.INFO, module= MODULE)

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
	db.open(host= "127.0.0.1", username= "root", password= "Vialedellapace14!", port= 3306, databaseName= "Mushrooms", connectionsPoolName= "MSR", numberOfConnectionsInPool= 20)

	main(logger= logger, db= db)