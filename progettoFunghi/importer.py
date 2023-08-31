import sys, database, diagnostic, datetime

if len(sys.argv) != 2:
    print("Usage: python3 importer.py <path_to_csv_file>")
    sys.exit(1)

logger = diagnostic.Diagnostic("./logger_importer.txt", diagnostic.DEBUG)
db = database.DatabaseHandler(logger= logger)
db.open(host= "127.0.0.1", username= "root", password= "MartinaFederico1vs1!", port= 3306, databaseName= "Mushrooms", connectionsPoolName= "MSR", numberOfConnectionsInPool= 20)

with open(sys.argv[1], "r") as f:
   lines = f.readlines()

stations = db.getStationRecords()
stationName = lines[0].strip()
if stationName not in stations:
    raise Exception(f"Station {stationName} not present in database")

periodicData = {}
instantaneousData = {}

dataName = None
for line in lines[2:]:
    if line.strip() == "":
        dataName = None
        continue
    elif dataName == None:
        dataName = line.strip()
        continue
    else:
        splittedLine = line.strip().split(",")
        if len(splittedLine) != 3:
            raise Exception(f"Line {line} has not 3 elements")
        elif splittedLine[0].strip() == "":
            print(f"Line {line} has empty start time")
            continue
        elif splittedLine[1].strip() == "":
            print(f"Line {line} has empty end time")
            continue
        elif splittedLine[2].strip() == "":
            print(f"Line {line} has empty value")
            continue

        startTime = int(datetime.datetime.fromisoformat(splittedLine[0].strip()).timestamp())
        endTime = int(datetime.datetime.fromisoformat(splittedLine[1].strip()).timestamp())
        value = round(float(splittedLine[2].strip()), 2)

        if startTime >= 1693386000:
            continue

        if dataName == "Precipitazioni":
            if startTime not in periodicData:
                periodicData[startTime] = {"startTime": startTime, "endTime": endTime, "Precipitation": value}
            else:
                raise Exception(f"Periodic data with start time {startTime} already present")
        elif dataName == "Temperatura":
            if startTime not in instantaneousData:
                instantaneousData[startTime] = {"startTime": startTime, "endTime": endTime, "Temperatura": value, "Umidita": None, "DirezioneVento": None, "VelocitaVento": None}
            elif startTime in instantaneousData and instantaneousData[startTime]["Temperatura"] == None:
                instantaneousData[startTime]["Temperatura"] = value
            else:
                raise Exception(f"Temperatura data with start time {startTime} already present. Record: {instantaneousData[startTime]}")
        elif dataName == "Umidita":
            if startTime not in instantaneousData:
                instantaneousData[startTime] = {"startTime": startTime, "endTime": endTime, "Temperatura": None, "Umidita": value, "DirezioneVento": None, "VelocitaVento": None}
            elif startTime in instantaneousData and instantaneousData[startTime]["Umidita"] == None:
                instantaneousData[startTime]["Umidita"] = value
            else:
                raise Exception(f"Umidita data with start time {startTime} already present. Record: {instantaneousData[startTime]}")
        elif dataName == "DirezioneVento":
            if startTime not in instantaneousData:
                instantaneousData[startTime] = {"startTime": startTime, "endTime": endTime, "Temperatura": None, "Umidita": None, "DirezioneVento": value, "VelocitaVento": None}
            elif startTime in instantaneousData and instantaneousData[startTime]["DirezioneVento"] == None:
                instantaneousData[startTime]["DirezioneVento"] = value
            else:
                raise Exception(f"DirezioneVento data with start time {startTime} already present. Record: {instantaneousData[startTime]}")
        elif dataName == "VelocitaVento":
            if startTime not in instantaneousData:
                instantaneousData[startTime] = {"startTime": startTime, "endTime": endTime, "Temperatura": None, "Umidita": None, "DirezioneVento": None, "VelocitaVento": value}
            elif startTime in instantaneousData and instantaneousData[startTime]["VelocitaVento"] == None:
                instantaneousData[startTime]["VelocitaVento"] = value
            else:
                raise Exception(f"VelocitaVento data with start time {startTime} already present. Record: {instantaneousData[startTime]}")
        else:
            raise Exception(f"Data name {dataName} not recognized")
        
        if dataName in ["Temperatura", "Umidita", "DirezioneVento", "VelocitaVento"] and startTime != endTime:
            raise Exception(f"Data name {dataName} has different start time {startTime} and end time {endTime}. Record: {splittedLine}")

dbRecords = list()
for record in periodicData.values():
    dbRecords.append({"StationName": stationName, "StartTimestamp": record["startTime"], "EndTimestamp": record["endTime"], "Precipitation": record["Precipitation"]})

db.storePeriodicDataRecords(dbRecords)
print(f"{len(dbRecords)} periodic data records stored")

dbRecords = list()
for record in instantaneousData.values():
    dbRecords.append({"StationName": stationName, "Timestamp": record["startTime"], "Temperature": record["Temperatura"], "Humidity": record["Umidita"], "WindDirection": record["DirezioneVento"], "WindSpeed": record["VelocitaVento"]})

db.storeInstantaneousDataRecords(dbRecords)
print(f"{len(dbRecords)} instantaneous data records stored")

db.close()