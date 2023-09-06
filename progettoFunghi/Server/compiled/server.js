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
        let missingRequiredFields = false;
        requiredFields.forEach((field) => {
            if (!(field in req.body) && missingRequiredFields === false) {
                res.status(400).end(`Missing required fields! Field: ${field}`);
                missingRequiredFields = true;
            }
        });
        if (missingRequiredFields) {
            return;
        }
        var username = String(req.body.username).trim();
        var password = String(req.body.password).trim();
    }
    catch (err) {
        errorOccurred(`Error in login API when parsing the request\n${err}`, res, "Error in login API when parsing the request");
        return;
    }
    // User's privilege level. If the auth is wrong or the user do not exists it is -1
    let authLevel = -1;
    // Check the auth
    try {
        authLevel = yield dbHandler.authenticate_user(username, password);
    }
    catch (e) {
        errorOccurred(`Error in login API when checking the user in DB\n${e}`, res, "Error in login API when checking the user in DB");
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
        errorOccurred(`Error in login API when creating the token\n${err}`, res, "Error in login API when creating the token");
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
        errorOccurred(`Error while checking JWT get_stations API\n${err}`, res, "Error while checking JWT get_stations API");
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
        errorOccurred(`Error in get_stations API\n${err}`, res, "Error in get_stations API");
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
        errorOccurred(`Error while checking JWT get_data_of_stations API\n${err}`, res, "Error while checking JWT get_data_of_stations API");
        return;
    }
    try {
        const requiredFields = ["stations", "startTimestamp", "endTimestamp"];
        let missingRequiredFields = false;
        requiredFields.forEach((field) => {
            if (!(field in req.body) && missingRequiredFields === false) {
                res.status(400).end(`Missing required fields! Field: ${field}`);
                missingRequiredFields = true;
            }
        });
        if (missingRequiredFields) {
            return;
        }
        let stations = null;
        if (typeof req.body.stations === "string") {
            stations = JSON.parse(req.body.stations);
        }
        else {
            stations = JSON.parse(JSON.stringify(req.body.stations));
        }
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
        errorOccurred(`Error in get_data_of_stations API\n${err}`, res, "Error in get_data_of_stations API");
    }
}));
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
