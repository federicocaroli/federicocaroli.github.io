"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const cors_1 = __importDefault(require("cors"));
const database_1 = require("./database");
// Create the PostgreSQL handler
var dbHandler = new database_1.MariaDBHandler("localhost", "root", "MartinaFederico1vs1!", "Mushrooms");
// Setup express for API
const mushroomServer = (0, express_1.default)();
mushroomServer.use(express_1.default.json({ limit: '20mb' }));
mushroomServer.use((0, cors_1.default)({}));
const parser = express_1.default.urlencoded({ extended: false });
const serverPort = 8000;
// Define authentication levels for APIs
const NO_PRIVILEDGE_REQUIRED = 0;
const USER_LEVEL = 1;
const ADMIN_LEVEL = 2;
// Check if variable is an object
function isObject(variable) {
    return variable !== null && typeof variable == 'object' && !Array.isArray(variable);
}
// Issue a new JWT token
function issueJwt(username, authLevel) {
    let jwtSecretKey = "=H}3NKzBbrJG}EX3";
    let payload = {
        authLevel: authLevel,
    };
    let signOption = {
        issuer: "Mushrooms",
        subject: username,
        expiresIn: "1h"
    };
    return jsonwebtoken_1.default.sign(payload, jwtSecretKey, signOption);
}
// Verify auth token
function verifyJwt(token, username) {
    let jwtSecretKey = "=H}3NKzBbrJG}EX3";
    try {
        let verifyOption = {
            issuer: "Mushrooms",
            subject: username,
            expiresIn: "1h",
        };
        return jsonwebtoken_1.default.verify(token, jwtSecretKey, verifyOption);
    }
    catch (err) {
        return null;
    }
}
// Validate JWT
function validateJwt(req, minLevel) {
    // Get header fields
    let token = req.header("token");
    let username = req.header("username");
    // Missing auth token
    if (token === undefined || username === undefined) {
        return false;
    }
    let jwtPayload = verifyJwt(token, username);
    // Check if the token is valid
    if (jwtPayload === null) {
        return false;
    }
    else if (isObject(jwtPayload) === false) {
        return false;
    }
    else if (jwtPayload.hasOwnProperty("authLevel") === false) {
        return false;
    }
    // Check if this user has enough privileges to access this API
    if (jwtPayload["authLevel"] < minLevel) {
        return false;
    }
    // Valid JWT
    return true;
}
function errorOccurred(message, res, resMessage = "") {
    console.log(message);
    res.status(500).end(resMessage);
}
// Let the user authenticate
mushroomServer.post("/login", parser, (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    // Check the required request fields
    try {
        const requiredFields = ["username", "password"];
        requiredFields.forEach((field) => {
            if (!(field in req.body)) {
                res.status(400).end(`Missing required fields! Field: ${field}`);
                return;
            }
        });
        var username = String(req.body.username).trim();
        var password = String(req.body.password).trim();
    }
    catch (err) {
        errorOccurred(`Error in login API when parsing the request\nError: ${err}`, res, "Error in login API when parsing the request");
        return;
    }
    // User's privilege level. If the auth is wrong or the user do not exists it is -1
    let authLevel = -1;
    // Check the auth
    try {
        authLevel = yield dbHandler.authenticate_user(username, password);
    }
    catch (e) {
        errorOccurred(`Error in login API when checking the user in DB\nError: ${e}`, res, "Error in login API when checking the user in DB");
        return;
    }
    try {
        // Check if invalid auth level
        if (authLevel < 0) {
            res.status(403).json({ reason: "authentication" });
            return;
        }
        // Generate the JWT token
        const token = issueJwt(username, authLevel);
        res.setHeader("Content-Type", "application/json");
        res.status(200).json({ "token": token });
        res.end();
    }
    catch (err) {
        errorOccurred(`Error in login API when creating the token\nError: ${err}`, res, "Error in login API when creating the token");
    }
}));
mushroomServer.post('/get_stations', parser, (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    // Check if an auth token is present
    try {
        if (validateJwt(req, USER_LEVEL) == false) {
            res.status(403).json({ reason: "authentication" });
            return;
        }
    }
    catch (err) {
        errorOccurred(`Error while checking JWT get_stations API\nError: ${err}`, res, "Error while checking JWT get_stations API");
        return;
    }
    try {
        let result = yield dbHandler.get_stations();
        let payload = {};
        for (let stationName of result.keys()) {
            let value = result.get(stationName);
            if (value !== undefined) {
                payload[stationName] = { latitude: value.latitude, longitude: value.longitude, altitude: value.altitude, lastUpdate: value.lastUpdate.toString() };
            }
        }
        res.status(200).json(payload);
    }
    catch (err) {
        errorOccurred(`Error in get_stations API\nError: ${err}`, res, "Error in get_stations API");
    }
}));
mushroomServer.post('/get_data_of_stations', parser, (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    // Check if an auth token is present
    try {
        if (validateJwt(req, USER_LEVEL) == false) {
            res.status(403).json({ reason: "authentication" });
            return;
        }
    }
    catch (err) {
        errorOccurred(`Error while checking JWT get_data_of_stations API\nError: ${err}`, res, "Error while checking JWT get_data_of_stations API");
        return;
    }
    try {
        const requiredFields = ["stations", "startTimestamp", "endTimestamp"];
        requiredFields.forEach((field) => {
            if (!(field in req.body)) {
                res.status(400).end(`Missing required fields! Field: ${field}`);
                return;
            }
        });
        let stations = JSON.parse(JSON.stringify(req.body.stations));
        if (Array.isArray(stations) === false) {
            res.status(400).end(`Stations is not an array!`);
            return;
        }
        let startTimestamp = parseInt(String(req.body.startTimestamp), 10);
        let endTimestamp = parseInt(String(req.body.endTimestamp), 10);
        if (isNaN(startTimestamp) || isNaN(endTimestamp)) {
            res.status(400).end(`Invalid numerical values!`);
            return;
        }
        if (startTimestamp > endTimestamp) {
            res.status(400).end(`Start timestamp is greater than end timestamp!`);
            return;
        }
        let startDate = new Date(startTimestamp * 1000);
        let startDayTimestamp = Math.round(new Date(`${startDate.getFullYear()}-${startDate.getMonth() + 1}-${startDate.getDate()} 00:00:00`).getTime() / 1000);
        let endDate = new Date(endTimestamp * 1000);
        let endDayTimestamp = Math.round(new Date(`${endDate.getFullYear()}-${endDate.getMonth() + 1}-${endDate.getDate()} 00:00:00`).getTime() / 1000);
        console.log(`startTimestamp: ${startTimestamp}, endTimestamp: ${endTimestamp}, startDayTimestamp: ${startDayTimestamp}, endDayTimestamp: ${endDayTimestamp}`);
        let payload = {};
        let divider = 24 * 3600;
        if (endTimestamp - startTimestamp <= 86400 * 3) {
            divider = 4 * 3600;
        }
        else if (endTimestamp - startTimestamp <= 86400 * 7) {
            divider = 8 * 3600;
        }
        for (let station of stations) {
            payload[station] = {};
            for (let day = startDayTimestamp; day < endDayTimestamp; day += 24 * 3600) {
                let dayString = new Date(day * 1000).toLocaleDateString('it-IT', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
                let dayData = {};
                let precipitationIsAvailable = false;
                let temperatureIsAvailable = false;
                let humidityIsAvailable = false;
                let windSpeedIsAvailable = false;
                let windDirectionIsAvailable = false;
                if (divider != 24 * 3600) {
                    for (let interval = day; interval < day + 24 * 3600; interval += divider) {
                        let intervalString = `${new Date(interval * 1000).getHours()}:00 - ${new Date((interval + divider) * 1000).getHours()}:00`;
                        dayData[intervalString] = { "precip.": "-", "temp.": "-", "min temp.": "-", "max temp.": "-", "umidità": "-", "vel. vento": "-", "direz. vento": "-" };
                        let sum_precipitation = yield dbHandler.get_sum_precipitation_of_station_in_period(station, interval, interval + divider);
                        let ave_instantaneous = yield dbHandler.get_average_instantaneous_data_of_station_in_period(station, interval, interval + divider);
                        let max_min_temperature = yield dbHandler.get_max_min_temperature_of_station_in_period(station, interval, interval + divider);
                        if (sum_precipitation !== null) {
                            dayData[intervalString]["precip."] = (Math.round(sum_precipitation * 10) / 10).toString();
                            precipitationIsAvailable = true;
                        }
                        if (ave_instantaneous["temperature"] !== null) {
                            dayData[intervalString]["temp."] = (Math.round(ave_instantaneous["temperature"] * 10) / 10).toString();
                            temperatureIsAvailable = true;
                        }
                        if (ave_instantaneous["humidity"] !== null) {
                            dayData[intervalString]["umidità"] = (Math.round(ave_instantaneous["humidity"] * 10) / 10).toString();
                            humidityIsAvailable = true;
                        }
                        if (ave_instantaneous["windSpeed"] !== null) {
                            dayData[intervalString]["vel. vento"] = (Math.round(ave_instantaneous["windSpeed"] * 10) / 10).toString();
                            windSpeedIsAvailable = true;
                        }
                        if (ave_instantaneous["windDirection"] !== null) {
                            dayData[intervalString]["direz. vento"] = (Math.round(ave_instantaneous["windDirection"] * 10) / 10).toString();
                            windDirectionIsAvailable = true;
                        }
                        if (max_min_temperature["minTemperature"] !== null) {
                            dayData[intervalString]["min temp."] = (Math.round(max_min_temperature["minTemperature"] * 10) / 10).toString();
                        }
                        if (max_min_temperature["maxTemperature"] !== null) {
                            dayData[intervalString]["max temp."] = (Math.round(max_min_temperature["maxTemperature"] * 10) / 10).toString();
                        }
                    }
                }
                dayData["tot"] = { "precip.": "-", "temp.": "-", "min temp.": "-", "max temp.": "-", "umidità": "-", "vel. vento": "-", "direz. vento": "-" };
                let sum_precipitation = yield dbHandler.get_sum_precipitation_of_station_in_period(station, day, day + 24 * 3600);
                let ave_instantaneous = yield dbHandler.get_average_instantaneous_data_of_station_in_period(station, day, day + 24 * 3600);
                let max_min_temperature = yield dbHandler.get_max_min_temperature_of_station_in_period(station, day, day + 24 * 3600);
                if (sum_precipitation !== null) {
                    dayData["tot"]["precip."] = (Math.round(sum_precipitation * 10) / 10).toString();
                    precipitationIsAvailable = true;
                }
                if (ave_instantaneous["temperature"] !== null) {
                    dayData["tot"]["temp."] = (Math.round(ave_instantaneous["temperature"] * 10) / 10).toString();
                    temperatureIsAvailable = true;
                }
                if (ave_instantaneous["humidity"] !== null) {
                    dayData["tot"]["umidità"] = (Math.round(ave_instantaneous["humidity"] * 10) / 10).toString();
                    humidityIsAvailable = true;
                }
                if (ave_instantaneous["windSpeed"] !== null) {
                    dayData["tot"]["vel. vento"] = (Math.round(ave_instantaneous["windSpeed"] * 10) / 10).toString();
                    windSpeedIsAvailable = true;
                }
                if (ave_instantaneous["windDirection"] !== null) {
                    dayData["tot"]["direz. vento"] = (Math.round(ave_instantaneous["windDirection"] * 10) / 10).toString();
                    windDirectionIsAvailable = true;
                }
                if (max_min_temperature["minTemperature"] !== null) {
                    dayData["tot"]["min temp."] = (Math.round(max_min_temperature["minTemperature"] * 10) / 10).toString();
                }
                if (max_min_temperature["maxTemperature"] !== null) {
                    dayData["tot"]["max temp."] = (Math.round(max_min_temperature["maxTemperature"] * 10) / 10).toString();
                }
                if (precipitationIsAvailable === false && temperatureIsAvailable === false && humidityIsAvailable === false && windSpeedIsAvailable === false && windDirectionIsAvailable === false) {
                    payload[station][dayString] = { "error": "No data" };
                }
                else {
                    payload[station][dayString] = { "columns": ["Periodo"] };
                    if (precipitationIsAvailable) {
                        payload[station][dayString]["columns"].push("Pioggia");
                    }
                    if (temperatureIsAvailable) {
                        payload[station][dayString]["columns"].push("Temp.");
                        payload[station][dayString]["columns"].push("Min Temp.");
                        payload[station][dayString]["columns"].push("Max Temp.");
                    }
                    if (humidityIsAvailable) {
                        payload[station][dayString]["columns"].push("Umidità");
                    }
                    if (windSpeedIsAvailable) {
                        payload[station][dayString]["columns"].push("Vel. Vento");
                    }
                    if (windDirectionIsAvailable) {
                        payload[station][dayString]["columns"].push("Direz. Vento");
                    }
                    payload[station][dayString]["rows"] = [];
                    for (let interval in dayData) {
                        let row = [interval];
                        if (precipitationIsAvailable) {
                            row.push(dayData[interval]["precip."]);
                        }
                        if (temperatureIsAvailable) {
                            row.push(dayData[interval]["temp."]);
                            row.push(dayData[interval]["min temp."]);
                            row.push(dayData[interval]["max temp."]);
                        }
                        if (humidityIsAvailable) {
                            row.push(dayData[interval]["umidità"]);
                        }
                        if (windSpeedIsAvailable) {
                            row.push(dayData[interval]["vel. vento"]);
                        }
                        if (windDirectionIsAvailable) {
                            row.push(dayData[interval]["direz. vento"]);
                        }
                        payload[station][dayString]["rows"].push(row);
                    }
                }
            }
        }
        res.status(200).json(payload);
    }
    catch (err) {
        errorOccurred(`Error in get_data_of_stations API\nError: ${err}`, res, "Error in get_data_of_stations API");
    }
}));
/*
mushroomServer.post('/vpc/admin/get/gps_realtime', parser, async (req: Request, res: Response) => {
    
    // Check if an auth token is present
    try {
        if (validateJwt(req, ADMIN_LEVEL) == false) {
            res.status(403).json({reason: "authentication"});
            return;
        }
    } catch(err) {
        errorOccurred(`Error while checking JWT get_gps_realtime API\nError: ${err}`, res, "Error while checking JWT get_gps_realtime API");
        return;
    }
    
    try{
        let result: any = {};
        for (let [key, value] of vehiclesRealTimeGPS) {
            result[key] = value;
        }

        res.setHeader("Content-Type","application/json");
        res.status(200).json(result);
    }
    catch(err){
        errorOccurred(`Error in get_gps_realtime API\nError: ${err}`, res, "Error in get_gps_realtime API");
    }
})

mushroomServer.post('/vpc/device/upload/data', parser, async (req: Request, res: Response) => {
    // Check if an auth token is present
    try {
        if (validateJwt(req, NO_PRIVILEDGE_REQUIRED) === false) {
            res.status(403).json({reason: "authentication"});
            return;
        }
    } catch(err) {
        errorOccurred(`Error while checking JWT data API\nError: ${err}`, res, "Error while checking JWT data API");
        return;
    }

    try {
        const requiredFields: string[] = ["id", "busStop", "cameraAggregatedCounts", "smartcheckAggregatedCounts", "GPS", "errors"];
        const requiredFieldsBusStop: string[] = ["startTimestamp", "endTimestamp", "startGPSLatitude", "startGPSLongitude", "endGPSLatitude", "endGPSLongitude", "eventCreator", "rawData", "totalIngoing", "totalOutgoing"];
        const requiredFieldsBusStopRawData: string[] = ["sensorID", "ingoing", "outgoing", "absoluteIngoing", "absoluteOutgoing"];
        const requiredFieldsGps: string[] = ["ID", "timestamp", "GPSLatitude", "GPSLongitude"];
        const requiredFieldsErrors: string[] = ["ID", "timestamp", "message", "level", "code", "module"];
        const requiredFieldsCameraAggregatedCounts: string[] = ["ID", "sensorID", "startTimestamp", "endTimestamp", "ingoing", "outgoing"];
        const requiredFieldsSmartcheckAggregatedCounts: string[] = ["ID", "sensorID", "startTimestamp", "endTimestamp", "ingoing", "outgoing", "absoluteIngoing", "absoluteOutgoing"];

        requiredFields.forEach((field: string) => {
            if(!(field in req.body)) {
                res.status(400).end(`Missing required fields! Field: ${field}`);
                return;
            }
        });

        let vehicleMacAddress: string = String(req.body.id).trim().toUpperCase();
        let vehicleId: number = await dbHandler.getVehicleIdFromMac(vehicleMacAddress);

        if (vehicleId === -1){
            res.status(400).end("Invalid vehicle MAC!");
            return;
        }

        let vehicleSensors: {id: number, type: number, address: number | string}[] = await dbHandler.getSensorsFromVehicleId(vehicleId);

        let response: {busStop: number[], cameraAggregatedCounts: number[], smartcheckAggregatedCounts: number[], GPS: number[], errors: number[], replies: string[]} = {"busStop": [], "cameraAggregatedCounts": [], "smartcheckAggregatedCounts": [], "GPS": [], "errors": [], "replies": []};

        // Bus stop table
        try{
            let busStopData: any = JSON.parse(JSON.stringify(req.body.busStop));
            
            if (Array.isArray(busStopData) === true){
                for (let record of busStopData) {
                    try {
                        if (isObject(record) === false){
                            throw new Error("Record is not an object!");
                        }

                        requiredFieldsBusStop.forEach((field: string) => {
                            if(!(field in record)) {
                                throw new Error(`Missing required field. Field: ${field}`);
                            }
                        });

                        if (Array.isArray(record["rawData"]) === false){
                            throw new Error("rawData is not an array!");
                        }

                        let validRawData : {sensor_id: number, ingoing: number, outgoing: number}[] = [];
                        let validAbsoluteSmartcheckCounts : {smartcheckId: number, absoluteIngoing: number, absoluteOutgoing: number}[] = [];
                        let clientRecordsIds: number[] = [];

                        for (let rawDataRecord of record["rawData"]) {
                            try {
                                if (isObject(rawDataRecord) === false){
                                    throw new Error("Raw data record is not an object!");
                                }
    
                                requiredFieldsBusStopRawData.forEach((field: string) => {
                                    if(!(field in rawDataRecord)) {
                                        throw new Error(`Missing required rawData field. Field: ${field}`);
                                    }
                                });
    
                                let recordId: number = parseInt(String(rawDataRecord["ID"]), 10);
                                let sensorId: number = parseInt(String(rawDataRecord["sensorID"]), 10);
                                let ingoing: number = parseInt(String(rawDataRecord["ingoing"]), 10);
                                let outgoing: number = parseInt(String(rawDataRecord["outgoing"]), 10);
    
                                if (isNaN(recordId) || isNaN(sensorId) || isNaN(ingoing) || isNaN(outgoing)){
                                    throw new Error("Invalid numerical values inside record of rawData!");
                                }

                                let absoluteIngoing: number = parseInt(String(rawDataRecord["absoluteIngoing"]), 10);
                                let absoluteOutgoing: number = parseInt(String(rawDataRecord["absoluteOutgoing"]), 10);
                                let sensorIsSmartcheck: boolean = false;
                                let success: boolean = false;

                                vehicleSensors.forEach((sensor: {id: number, type: number, address: number | string}) => {
                                    if (sensor.id === sensorId){
                                        success = true;
                                        if (sensor.type === SENSOR_TYPES.smartcheck){
                                            sensorIsSmartcheck = true;
                                        }
                                        else if (sensor.type === SENSOR_TYPES.camera){
                                            sensorIsSmartcheck = false;
                                        }
                                        else {
                                            throw new Error("Invalid sensor type!");
                                        }
                                    }
                                });
    
                                if (!success) {
                                    throw new Error("Sensor ID not related to the vehicle!");
                                }

                                if (sensorIsSmartcheck && (isNaN(absoluteIngoing) || isNaN(absoluteOutgoing))){		// TODO controlla che valore è associato a Null in modo tale da capire quando c'è uno smartcheck con absolute counts strani
                                    throw new Error("Invalid numerical values for absolute counts inside record of rawData!");
                                }

                                clientRecordsIds.push(recordId);
                                validRawData.push({sensor_id: sensorId, ingoing: ingoing, outgoing: outgoing});
                                
                                if (sensorIsSmartcheck){
                                    validAbsoluteSmartcheckCounts.push({smartcheckId: sensorId, absoluteIngoing: absoluteIngoing, absoluteOutgoing: absoluteOutgoing});
                                }
                            }
                            catch (err){
                                throw new Error(`Error while parsing an element of rawData array. Error: ${err}. Element: ${JSON.stringify(rawDataRecord)}. Ignoring the whole record...`);
                            }
                        }

                        let startTimestamp: number = parseInt(String(record["startTimestamp"]), 10);
                        let endTimestamp: number = parseInt(String(record["endTimestamp"]), 10);
                        let startLatitude: number = parseFloat(String(record["startGPSLatitude"]));
                        let startLongitude: number = parseFloat(String(record["startGPSLongitude"]));
                        let endLatitude: number = parseFloat(String(record["endGPSLatitude"]));
                        let endLongitude: number = parseFloat(String(record["endGPSLongitude"]));
                        let eventCreatorId: number = parseInt(String(record["eventCreator"]), 10);
                        let totalIngoing: number = parseInt(String(record["totalIngoing"]), 10);
                        let totalOutgoing: number = parseInt(String(record["totalOutgoing"]), 10);

                        if (isNaN(startTimestamp) || isNaN(endTimestamp) || isNaN(startLatitude) || isNaN(startLongitude) || isNaN(endLatitude) || isNaN(endLongitude) || isNaN(eventCreatorId) || isNaN(totalIngoing) || isNaN(totalOutgoing)){
                            throw new Error("Invalid numerical values!");
                        }
                        
                        if (startTimestamp > endTimestamp) {
                            throw new Error("Start timestamp is greater than end timestamp!");
                        }

                        await dbHandler.insertRecordedStop(vehicleId, startTimestamp, endTimestamp, totalIngoing, totalOutgoing, startLatitude, startLongitude, endLatitude, endLongitude, 1, validRawData, eventCreatorId);			// TODO CAMBIA
                        
                        for (let record of validAbsoluteSmartcheckCounts) {
                            await dbHandler.insertAbsoluteSmartcheckCounts(record.smartcheckId, endTimestamp, record.absoluteIngoing, record.absoluteOutgoing);
                        }

                        response.busStop.push(...clientRecordsIds);
                    }
                    catch(err){
                        let msg: string = `Error while parsing an element of busStop array. Error: ${err}. Element: ${JSON.stringify(record)}. Ignoring...`
                        console.log(msg);
                        response.replies.push(msg);
                    }
                }
            }
            else {
                throw new Error("busStop is not an array!");
            }
        }
        catch(err){
            console.log(`Error while parsing busStop array. Error: ${err}. Ignoring...`);
            response.replies.push(`Error while parsing busStop array. Error: ${err}. Ignoring...`);
        }


        // GPS table
        try{
            let gpsData: any = JSON.parse(JSON.stringify(req.body.GPS));

            if (Array.isArray(gpsData) === true){
                for (let record of gpsData) {
                    try {
                        if (isObject(record) === false){
                            throw new Error("Record is not an object!");
                        }

                        requiredFieldsGps.forEach((field: string) => {
                            if(!(field in record)) {
                                throw new Error(`Missing required fields! Field: ${field}`);
                            }
                        });
    
                        let timestamp: number = parseInt(String(record["timestamp"]), 10);
                        let id: number = parseInt(String(record["ID"]), 10);
                        let latitude: number = parseFloat(String(record["GPSLatitude"]));
                        let longitude: number = parseFloat(String(record["GPSLongitude"]));
    
                        if (isNaN(timestamp) || isNaN(id) || isNaN(latitude) || isNaN(longitude)){
                            throw new Error("Invalid numerical values!");
                        }
                            
                        await dbHandler.insertGpsTrack(vehicleId, latitude, longitude, timestamp);
                        response.GPS.push(id);
                    }
                    catch(err){
                        let msg: string = `Error while parsing an element of GPS array. Error: ${err}. Element: ${JSON.stringify(record)}. Ignoring...`
                        console.log(msg);
                        response.replies.push(msg);
                    }
                }
            }
            else {
                throw new Error("GPS is not an array!");
            }
        }
        catch(err){
            console.log(`Error while parsing GPS array. Error: ${err}. Ignoring...`);
            response.replies.push(`Error while parsing GPS array. Error: ${err}. Ignoring...`);
        }

        // Errors table
        try{
            let errorsData: any = JSON.parse(JSON.stringify(req.body.errors));

            if (Array.isArray(errorsData) === true){
                for (let record of errorsData) {
                    try {
                        if (isObject(record) === false){
                            throw new Error("Record is not an object!");
                        }

                        requiredFieldsErrors.forEach((field: string) => {
                            if(!(field in record)) {
                                throw new Error(`Missing required fields! Field: ${field}`);
                            }
                        });
    
                        let timestamp: number = parseInt(String(record["timestamp"]), 10);
                        let id: number = parseInt(String(record["ID"]), 10);
                        let level: number = parseInt(String(record["level"]), 10);
                        let code: number = parseInt(String(record["code"]), 10);
                        let message: string = String(record["message"]);
                        let module: string = String(record["module"]);
    
                        if (isNaN(timestamp) || isNaN(id) || isNaN(level) || isNaN(code)){
                            throw new Error("Invalid numerical values!");
                        }
                        if (VEHICLE_LOG_LEVELS.includes(level) === false){
                            throw new Error("Invalid log level value!");
                        }
    
                        await dbHandler.insertLogger(vehicleId, level, timestamp, module, message, code);
                        response.errors.push(id);
                    }
                    catch(err){
                        let msg: string = `Error while parsing an element of errors array. Error: ${err}. Element: ${JSON.stringify(record)}. Ignoring...`
                        console.log(msg);
                        response.replies.push(msg);
                    }
                }
            }
            else {
                throw new Error("Errors is not an array!");
            }
        }
        catch(err){
            console.log(`Error while parsing errors array. Error: ${err}. Ignoring...`);
            response.replies.push(`Error while parsing errors array. Error: ${err}. Ignoring...`);
        }

        // Periodic sensor counts table - First part
        try{
            let cameraAggregatedCountsData: any = JSON.parse(JSON.stringify(req.body.cameraAggregatedCounts));

            if (Array.isArray(cameraAggregatedCountsData) === true){
                for (let record of cameraAggregatedCountsData) {
                    try {
                        if (isObject(record) === false){
                            throw new Error("Record is not an object!");
                        }

                        requiredFieldsCameraAggregatedCounts.forEach((field: string) => {
                            if(!(field in record)) {
                                throw new Error(`Missing required fields! Field: ${field}`);
                            }
                        });
    
                        let id: number = parseInt(String(record["ID"]), 10);
                        let sensorId: number = parseInt(String(record["sensorID"]), 10);
                        let startTimestamp: number = parseInt(String(record["startTimestamp"]), 10);
                        let endTimestamp: number = parseInt(String(record["endTimestamp"]), 10);
                        let ingoing: number = parseInt(String(record["ingoing"]), 10);
                        let outgoing: number = parseInt(String(record["outgoing"]), 10);
    
                        if (isNaN(sensorId) || isNaN(id) || isNaN(startTimestamp) || isNaN(endTimestamp) || isNaN(ingoing) || isNaN(outgoing)){
                            throw new Error("Invalid numerical values!");
                        }
                        if (startTimestamp > endTimestamp) {
                            throw new Error("Start timestamp is greater than end timestamp!");
                        }
                        
                        let success: boolean = false;
                        vehicleSensors.forEach((sensor: {id: number, type: number, address: number | string}) => {
                            if (sensor.id === sensorId && sensor.type === SENSOR_TYPES.camera){
                                success = true;
                            }
                        });

                        if (!success){
                            throw new Error("Invalid sensor ID or sensor type!");
                        }

                        await dbHandler.insertPeriodicSensorCounts(sensorId, endTimestamp, startTimestamp, ingoing, outgoing);
                        response.cameraAggregatedCounts.push(id);
                    }
                    catch(err){
                        let msg: string = `Error while parsing an element of cameraAggregatedCounts array. Error: ${err}. Element: ${JSON.stringify(record)}. Ignoring...`
                        console.log(msg);
                        response.replies.push(msg);
                    }
                }
            }
            else {
                throw new Error("CameraAggregatedCounts is not an array!")
            }
        }
        catch(err){
            console.log(`Error while parsing cameraAggregatedCounts array. Error: ${err}. Ignoring...`);
            response.replies.push(`Error while parsing cameraAggregatedCounts array. Error: ${err}. Ignoring...`);
        }

        // Periodic sensor counts table - Second part
        try{
            let smartcheckAggregatedCountsData: any = JSON.parse(JSON.stringify(req.body.smartcheckAggregatedCounts));

            if (Array.isArray(smartcheckAggregatedCountsData) === true){
                for (let record of smartcheckAggregatedCountsData) {
                    try {
                        if (isObject(record) === false){
                            throw new Error("Record is not an object!");
                        }

                        requiredFieldsSmartcheckAggregatedCounts.forEach((field: string) => {
                            if(!(field in record)) {
                                throw new Error(`Missing required fields! Field: ${field}`);
                            }
                        });
    
                        let id: number = parseInt(String(record["ID"]), 10);
                        let sensorId: number = parseInt(String(record["sensorID"]), 10);
                        let startTimestamp: number = parseInt(String(record["startTimestamp"]), 10);
                        let endTimestamp: number = parseInt(String(record["endTimestamp"]), 10);
                        let ingoing: number = parseInt(String(record["ingoing"]), 10);
                        let outgoing: number = parseInt(String(record["outgoing"]), 10);
                        let absoluteIngoing: number = parseInt(String(record["absoluteIngoing"]), 10);
                        let absoluteOutgoing: number = parseInt(String(record["absoluteOutgoing"]), 10);
    
                        if (isNaN(sensorId) || isNaN(id) || isNaN(startTimestamp) || isNaN(endTimestamp) || isNaN(ingoing) || isNaN(outgoing) || isNaN(absoluteIngoing) || isNaN(absoluteOutgoing)){
                            throw new Error("Invalid numerical values!");
                        }
                        if (startTimestamp > endTimestamp) {
                            throw new Error("Start timestamp is greater than end timestamp!");
                        }
                        
                        let success: boolean = false;
                        vehicleSensors.forEach((sensor: {id: number, type: number, address: number | string}) => {
                            if (sensor.id === sensorId && sensor.type === SENSOR_TYPES.smartcheck){
                                success = true;
                            }
                        });

                        if (!success){
                            throw new Error("Invalid sensor ID or sensor type!");
                        }

                        await dbHandler.insertPeriodicSensorCounts(sensorId, endTimestamp, startTimestamp, ingoing, outgoing);
                        await dbHandler.insertAbsoluteSmartcheckCounts(sensorId, endTimestamp, absoluteIngoing, absoluteOutgoing);
                        response.smartcheckAggregatedCounts.push(id);
                    }
                    catch(err){
                        let msg: string = `Error while parsing an element of smartcheckAggregatedCounts array. Error: ${err}. Element: ${JSON.stringify(record)}. Ignoring...`
                        console.log(msg);
                        response.replies.push(msg);
                    }
                }
            }
            else {
                throw new Error("SmartcheckAggregatedCounts is not an array!");
            }
        }
        catch(err){
            console.log(`Error while parsing smartcheckAggregatedCounts array. Error: ${err}. Ignoring...`);
            response.replies.push(`Error while parsing smartcheckAggregatedCounts array. Error: ${err}. Ignoring...`);
        }

        res.status(200).json(response);
    }
    catch(err){
        errorOccurred(`Error in data API\nError: ${err}`, res, "Error in data API");
        return;
    }
})

mushroomServer.post('/vpc/device/download/config', parser, async (req: Request, res: Response) => {
    
    // Check if an auth token is present
    try {
        if (validateJwt(req, NO_PRIVILEDGE_REQUIRED) == false) {
            res.status(403).json({reason: "authentication"});
            return;
        }
    } catch(err) {
        errorOccurred(`Error while checking JWT config API\nError: ${err}`, res, "Error while checking JWT config API");
        return;
    }
    
    var vehicleId: number = -1;
    var vehicleVersion: string = "";

    try {
        const requiredFields: string[] = ["device_id", "version"];
        
        requiredFields.forEach((field: string) => {
            if(!(field in req.body)) {
                res.status(400).end(`Missing required fields! Field: ${field}`);
                return;
            }
        });

        let vehicleMacAddress: string = String(req.body.device_id).trim().toUpperCase();
        vehicleVersion = String(req.body.version).trim();

        vehicleId = await dbHandler.getVehicleIdFromMac(vehicleMacAddress);

        if (vehicleId === -1){
            res.status(400).end("Invalid vehicle MAC!");
            return;
        }
    } catch(err) {
        errorOccurred(`Error in config API when parsing the request\nError: ${err}`, res, "Error in config API when parsing the request");
        return;
    }

    try {
        let timestamp: number = Math.floor(Date.now() / 1000);
        vehiclesStatus.set(vehicleId, {timestamp: timestamp});

        let vehiclesVersion: Map<number, {time: number, version: string}> = await dbHandler.getVehiclesVersion();
        let storedVehicleVersion: {time: number, version: string} | undefined = vehiclesVersion.get(vehicleId);

        if (storedVehicleVersion === undefined){
            await dbHandler.insertVehicleVersion(vehicleId, timestamp, vehicleVersion.toUpperCase());
        }
        else {
            if (storedVehicleVersion["version"].toUpperCase() !== vehicleVersion.toUpperCase()){
                await dbHandler.updateVehicleVersion(vehicleId, timestamp, vehicleVersion.toUpperCase());
            }
        }
    } catch(err) {
        console.log(`Error in config API while updating vehicle version\nError: ${err}`);
    }

    try{
        let vehicleConfig: any = await dbHandler.getConfigFromVehicleId(vehicleId);
        if (isObject(vehicleConfig) === false){
            throw new Error("Vehicle configuration is not an object!");
        }
        vehicleConfig.sensors = await dbHandler.getSensorsFromVehicleId(vehicleId);
        
        res.setHeader("Content-Type","application/json");
        res.status(200).json(vehicleConfig);
    }
    catch(err){
        errorOccurred(`Error in config API\nError: ${err}`, res, "Error in config API");
    }
})

mushroomServer.post('/vpc/admin/get/vehicle_info', parser, async (req: Request, res: Response) => {
    
    // Check if an auth token is present
    try {
        if (validateJwt(req, ADMIN_LEVEL) == false) {
            res.status(403).json({reason: "authentication"});
            return;
        }
    } catch(err) {
        errorOccurred(`Error while checking JWT get_vehicle_info API\nError: ${err}`, res, "Error while checking JWT get_vehicle_info API");
        return;
    }
    
    try{
        let result: any = {};
        for (let [key, value] of vehiclesStatus) {
            result[key] = value;
        }

        res.setHeader("Content-Type","application/json");
        res.status(200).json(result);
    }
    catch(err){
        errorOccurred(`Error in get_vehicle_info API\nError: ${err}`, res, "Error in get_vehicle_info API");
    }
})*/
try {
    var handler = mushroomServer.listen(serverPort, () => __awaiter(void 0, void 0, void 0, function* () {
        console.log("Mushrooms HTTP Server started");
    }));
    process.on("SIGTERM", () => {
        handler.close(() => {
            process.exit(0);
        });
    });
}
catch (e) {
    dbHandler.close();
    console.log(`Impossible to start the server because:\n${e}`);
    process.exit(1);
}
