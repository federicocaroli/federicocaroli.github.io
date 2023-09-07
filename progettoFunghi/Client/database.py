import mariadb, copy, datetime, os, sys, re
import diagnostic
from constants import DATA_KEYS, STATION_KEYS

_MODULE = "DBMS"

class DatabaseHandler:
	'''
	Provide an interface to communicate with a mariaDB database.
	'''
	def __init__(self, logger: diagnostic.Diagnostic):
		'''
		Initializates the module
		'''
		if isinstance(logger, diagnostic.Diagnostic) != True:
			raise TypeError("DatabaseHandler __init__ method")

		# common variables
		self._logger = logger
		self._status = False

		# variables to manage database connections
		self._databaseConfig = dict()		
		self._connectionsPool = None

	def open(self, host: str, username: str, password: str, port: int, databaseName: str, numberOfConnectionsInPool: int, connectionsPoolName: str) -> bool:
		'''
		Create a connection to a MariaDB database.
		'''

		if type(host) != str or type(username) != str or type(password) != str or type(port) != int or type(databaseName) != str or type(numberOfConnectionsInPool) != int or type(connectionsPoolName) != str:
			raise TypeError("Database open method")
		elif self._status == True:
			raise Exception("Database module has already been started")

		self._status = True		
		self._databaseConfig = {"host": host, "user": username, "port": port, "password": password, "database": databaseName, "autocommit": True}

		try:
			# check if database exists
			databaseCreationQuery = f"CREATE DATABASE IF NOT EXISTS {databaseName}"

			conn = mariadb.connect(
						host = host,
						user= username,
						password= password,
						port= port,
						autocommit = True
					)
			cur = conn.cursor()
			cur.execute(databaseCreationQuery)
			cur.close()
			conn.close()

			# Create the connections pool
			self._connectionsPool = mariadb.ConnectionPool(
									pool_name= connectionsPoolName,
									pool_size= numberOfConnectionsInPool,
									**self._databaseConfig
								)

			# create the tables
			stationTableCreationQuery = f"CREATE TABLE IF NOT EXISTS STATION(\
					Name VARCHAR(255) NOT NULL PRIMARY KEY,\
					Latitude DOUBLE NOT NULL,\
					Longitude DOUBLE NOT NULL,\
					Altitude DOUBLE,\
					LastUpdate BIGINT DEFAULT 0 NOT NULL,\
					CONSTRAINT stationLatitudeLongitudeUnique UNIQUE(Latitude, Longitude))"
			
			periodicDataTableCreationQuery = f"CREATE TABLE IF NOT EXISTS PERIODIC_DATA(\
					StationName VARCHAR(255) NOT NULL,\
					StartTimestamp BIGINT NOT NULL,\
					EndTimestamp BIGINT NOT NULL,\
					Precipitation DOUBLE,\
					CONSTRAINT periodicDataStationNameForeign FOREIGN KEY(StationName) REFERENCES STATION(Name) ON DELETE CASCADE,\
					CONSTRAINT periodicDataRecordPK PRIMARY KEY(StationName, StartTimestamp, EndTimestamp))"
			
			instantaneousDataTableCreationQuery = f"CREATE TABLE IF NOT EXISTS INSTANTANEOUS_DATA(\
					StationName VARCHAR(255) NOT NULL,\
					Timestamp BIGINT NOT NULL,\
					Temperature DOUBLE,\
					Humidity DOUBLE,\
					WindDirection DOUBLE,\
					WindSpeed DOUBLE,\
					CONSTRAINT instantaneousDataStationNameForeign FOREIGN KEY(StationName) REFERENCES STATION(Name) ON DELETE CASCADE,\
					CONSTRAINT instantaneousDataRecordPK PRIMARY KEY(StationName, Timestamp))"
			
			userTableCreationQuery = f"CREATE TABLE IF NOT EXISTS USER(\
					Username VARCHAR(255) NOT NULL PRIMARY KEY,\
					Password VARCHAR(64) NOT NULL,\
					AuthLevel SMALLINT NOT NULL,\
					CONSTRAINT user_check_auth_level CHECK(AuthLevel >= 0))"

			conn, cur = self._getConnectionWithDatabase()
			for query in [stationTableCreationQuery, periodicDataTableCreationQuery, instantaneousDataTableCreationQuery, userTableCreationQuery]:
				cur.execute(query)

			cur.close()
			conn.close()

			self._logger.record(msg= "Database module correctly started", logLevel= diagnostic.DEBUG, module= _MODULE)

		except Exception as e:
			self._logger.record(msg= f"Impossible to correctly open a connection to MariaDB DBMS. Database config: {self._databaseConfig}. Pool name: {connectionsPoolName}. Pool size: {numberOfConnectionsInPool}", logLevel= diagnostic.CRITICAL, module= _MODULE, exc= e)
			raise e  

	def _getConnectionWithDatabase(self):

		if self._status == True and self._connectionsPool != None:
			try:
				try:
					conn = self._connectionsPool.get_connection()
					cur = conn.cursor()
				except mariadb.PoolError as e:
					self._logger.record(msg= "Impossible to correctly get the cursor of a connection belonging to the pool", logLevel=diagnostic.ERROR, module=_MODULE, exc=e)
					conn = mariadb.Connection(
									**self._databaseConfig
								)
					cur = conn.cursor()
				
				return conn, cur
			
			except Exception as e:
				self._logger.record(msg="Exception occured while trying to get the cursor", logLevel=diagnostic.ERROR, module=_MODULE, exc=e)
				raise e		
		
		else:
			raise Exception(f"Impossible to correctly get the cursor because status is False or pool is None. Status: {self._status}")
		
	def close(self) -> bool:
		
		if self._status == True:
			try:
				self._status = False
				if self._connectionsPool != None:
					self._connectionsPool.close()
					self._connectionsPool = None

			except Exception as e:
				self._logger.record(msg="Exception while closing database module", logLevel= diagnostic.ERROR, module=_MODULE, exc=e)
				return False
			else:
				self._logger.record(msg="Database module correctly closed", logLevel=diagnostic.DEBUG, module=_MODULE)
			
		return True

	def addNewStationRecords(self, records: list):
		if type(records) != list:
			raise TypeError("Database storeStationRecords method")
		elif self._status != True or self._connectionsPool == None:
			raise Exception(f"Impossible to store new station stop records into DB because status is False or connection pool is None. Records: {records}. Status: {self._status}")

		dbRecords = list()

		for record in copy.deepcopy(records):
			if type(record) != dict:
				self._logger.record(msg= f"Station record to store in the DB is not a dict. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			elif any(key not in record for key in ["Name", "Latitude", "Longitude", "Altitude"]):
				self._logger.record(msg= f"Station record to store in the DB has not all the necessary keys. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			else:
				dbRecords.append((record["Name"], record["Latitude"], record["Longitude"], record["Altitude"]))
		
		if len(dbRecords) > 0:
			conn, cur = self._getConnectionWithDatabase()
			
			try:
				cur.executemany(f"INSERT INTO STATION(Name, Latitude, Longitude, Altitude, LastUpdate) VALUES(?, ?, ?, ?, DEFAULT)", dbRecords)
			except Exception as e:
				self._logger.record(msg= f"Exception occured while storing new station records into DB. Records: {dbRecords}", logLevel= diagnostic.ERROR, module=_MODULE, exc= e)
				raise e
			finally:
				cur.close()
				conn.close()

	def updateLastUpdateOfStationRecords(self, records: list):
		if type(records) != list:
			raise TypeError("Database updateLastUpdateOfStationRecords method")
		elif self._status != True or self._connectionsPool == None:
			raise Exception(f"Impossible to update last update of station records into DB because status is False or connection pool is None. Records: {records}. Status: {self._status}")
		
		dbRecords = list()

		for record in copy.deepcopy(records):
			if type(record) != dict:
				self._logger.record(msg= f"Station record to update in the DB is not a dict. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			elif any(key not in record for key in ["Name", "LastUpdate"]):
				self._logger.record(msg= f"Station record to update in the DB has not all the necessary keys. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			else:
				dbRecords.append((record["LastUpdate"], record["Name"]))
		
		if len(dbRecords) > 0:
			conn, cur = self._getConnectionWithDatabase()
			
			try:
				cur.executemany(f"UPDATE STATION SET LastUpdate = ? WHERE Name = ?", dbRecords)
			except Exception as e:
				self._logger.record(msg= f"Exception occured while updating last update of station records into DB. Records: {dbRecords}", logLevel= diagnostic.ERROR, module=_MODULE, exc= e)
				raise e
			finally:
				cur.close()
				conn.close()

	def getStationRecords(self) -> dict:
		
		conn, cur = self._getConnectionWithDatabase()

		try:
			result = dict()	
			cur.execute(f"SELECT Name, Latitude, Longitude, Altitude, LastUpdate FROM STATION")

			records = cur.fetchall()
			
			for record in records:
				result[record[0]] = {"Latitude": record[1], "Longitude": record[2], "Altitude": record[3], "LastUpdate": record[4]}

			return result

		except Exception as e:
			self._logger.record(msg= f"Exception occured while getting station records from DB", logLevel= diagnostic.ERROR, module=_MODULE, exc= e)
			raise e
		finally:
			cur.close()
			conn.close()

	def storePeriodicDataRecords(self, records: list):
		if type(records) != list:
			raise TypeError("Database storePeriodicDataRecords method")
		elif self._status != True or self._connectionsPool == None:
			raise Exception(f"Impossible to store periodic data records into DB because status is False or connection pool is None. Records: {records}. Status: {self._status}")
		
		dbRecords = list()
		
		for record in copy.deepcopy(records):
			if type(record) != dict:
				self._logger.record(msg= f"Periodic data record to store in the DB is not a dict. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			elif any(key not in record for key in ["StationName", "StartTimestamp", "EndTimestamp", "Precipitation"]):
				self._logger.record(msg= f"Periodic data record to store in the DB has not all the necessary keys. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			elif record["StartTimestamp"] == None or record["EndTimestamp"] == None or record["StationName"] == None:
				self._logger.record(msg= f"Periodic data record to store in the DB has some None values in StartTimestamp, EndTimestamp, StationName fields. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			elif all(record[key] == None for key in ["Precipitation"]):
				self._logger.record(msg= f"Periodic data record to store in the DB has all None values in data fields. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			else:
				dbRecords.append((record["StationName"], record["StartTimestamp"], record["EndTimestamp"], record["Precipitation"]))
		
		if len(dbRecords) > 0:
			conn, cur = self._getConnectionWithDatabase()
			
			try:
				cur.executemany(f"INSERT INTO PERIODIC_DATA(StationName, StartTimestamp, EndTimestamp, Precipitation) VALUES(?, ?, ?, ?)", dbRecords)
			except Exception as e:
				self._logger.record(msg= f"Exception occured while storing periodic data records into DB. Records: {dbRecords}", logLevel= diagnostic.ERROR, module=_MODULE, exc= e)
				raise e
			finally:
				cur.close()
				conn.close()
	
	def storeInstantaneousDataRecords(self, records: list):
		if type(records) != list:
			raise TypeError("Database storeInstantaneousDataRecords method")
		elif self._status != True or self._connectionsPool == None:
			raise Exception(f"Impossible to store instantaneous data records into DB because status is False or connection pool is None. Records: {records}. Status: {self._status}")
		
		dbRecords = list()
		
		for record in copy.deepcopy(records):
			if type(record) != dict:
				self._logger.record(msg= f"Instantaneous data record to store in the DB is not a dict. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			elif any(key not in record for key in ["StationName", "Timestamp", "Temperature", "Humidity", "WindDirection", "WindSpeed"]):
				self._logger.record(msg= f"Instantaneous data record to store in the DB has not all the necessary keys. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			elif record["Timestamp"] == None or record["StationName"] == None:
				self._logger.record(msg= f"Instantaneous data record to store in the DB has some None values in Timestamp, StationName fields. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			elif all(record[key] == None for key in ["Temperature", "Humidity", "WindDirection", "WindSpeed"]):
				self._logger.record(msg= f"Instantaneous data record to store in the DB has all None values in data fields. Record: {record}", logLevel= diagnostic.ERROR, module=_MODULE)
			else:
				dbRecords.append((record["StationName"], record["Timestamp"], record["Temperature"], record["Humidity"], record["WindDirection"], record["WindSpeed"]))
		
		if len(dbRecords) > 0:
			conn, cur = self._getConnectionWithDatabase()
			
			try:
				cur.executemany(f"INSERT INTO INSTANTANEOUS_DATA(StationName, Timestamp, Temperature, Humidity, WindDirection, WindSpeed) VALUES(?, ?, ?, ?, ?, ?)", dbRecords)
			except Exception as e:
				self._logger.record(msg= f"Exception occured while storing instantaneous data records into DB. Records: {dbRecords}", logLevel= diagnostic.ERROR, module=_MODULE, exc= e)
				raise e
			finally:
				cur.close()
				conn.close()

if __name__ == "__main__":
	import json
	arguments = len(sys.argv) - 1
	if arguments > 0:
		import ptvsd
		# Allow other computers to attach to ptvsd at this IP address and port.
		ptvsd.enable_attach(address=('10.0.0.5', 3001))
		# Pause the program until a remote debugger is attached	
		ptvsd.wait_for_attach()
	
	l = diagnostic.Diagnostic(path="./logger_database.txt", logLevel=10)
	dbms = DatabaseHandler(logger=l)
	dbms.open()
