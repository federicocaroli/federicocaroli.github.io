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
Object.defineProperty(exports, "__esModule", { value: true });
exports.MariaDBHandler = void 0;
const mariadb = require('mariadb');
const pool = mariadb.createPool({ host: process.env.DB_HOST, user: process.env.DB_USER, connectionLimit: 5 });
class MariaDBHandler {
    constructor(host, user, password, database) {
        this.host = host;
        this.user = user;
        this.password = password;
        this.database = database;
        this.pool = mariadb.createPool({
            host: this.host,
            user: this.user,
            password: this.password,
            database: this.database,
            connectionLimit: 10
        });
    }
    authenticate_user(username, password) {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
                let auth_level = -1;
                try {
                    if (typeof username !== "string" || typeof password !== "string") {
                        throw new Error("Invalid username or password. Username or password is not string.");
                    }
                    let resp = yield this.pool.query("SELECT AuthLevel FROM USER WHERE Username = ? AND Password = ?", [username, password]);
                    // The user exists
                    if (resp.length > 0) {
                        auth_level = parseInt(resp[0]["AuthLevel"]);
                        if (isNaN(auth_level)) {
                            throw new Error(`Invalid auth_level for user: ${username}. Auth_level is not numerical. Auth_level: ${resp[0]["AuthLevel"]}`);
                        }
                    }
                }
                catch (err) {
                    reject(new Error(`Database authenticate_user method: ${err}`));
                    return;
                }
                resolve(auth_level);
            }));
        });
    }
    get_stations() {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
                let result = new Map();
                try {
                    let resp = yield this.pool.query("SELECT Name, Latitude, Longitude, Altitude, LastUpdate FROM STATION ORDER BY Name");
                    for (let record of resp) {
                        result.set(record["Name"], { latitude: record["Latitude"], longitude: record["Longitude"], altitude: record["Altitude"], lastUpdate: record["LastUpdate"] });
                    }
                }
                catch (err) {
                    reject(new Error(`Database get_stations method: ${err}`));
                    return;
                }
                resolve(result);
            }));
        });
    }
    get_sum_precipitation_of_station_in_period(station, startTimestamp, endTimestamp) {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
                try {
                    let resp = yield this.pool.query("SELECT SUM(Precipitation) as Somma FROM PERIODIC_DATA WHERE StationName = ? AND StartTimestamp >= ? AND EndTimestamp < ?", [station, startTimestamp, endTimestamp]);
                    if (resp.length > 0) {
                        resolve(resp[0]["Somma"]);
                    }
                }
                catch (err) {
                    reject(new Error(`Database get_sum_precipitation_of_station_in_period method: ${err}`));
                    return;
                }
                resolve(null);
            }));
        });
    }
    get_average_instantaneous_data_of_station_in_period(station, startTimestamp, endTimestamp) {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
                let result = { temperature: null, humidity: null, windSpeed: null, windDirection: null };
                try {
                    let resp = yield this.pool.query("SELECT AVG(Temperature) as Temperature, AVG(Humidity) as Humidity, AVG(WindSpeed) as WindSpeed, AVG(WindDirection) as WindDirection FROM INSTANTANEOUS_DATA WHERE StationName = ? AND Timestamp >= ? AND Timestamp < ?", [station, startTimestamp, endTimestamp]);
                    if (resp.length > 0) {
                        result.temperature = resp[0]["Temperature"];
                        result.humidity = resp[0]["Humidity"];
                        result.windSpeed = resp[0]["WindSpeed"];
                        result.windDirection = resp[0]["WindDirection"];
                    }
                }
                catch (err) {
                    reject(new Error(`Database get_average_instantaneous_data_of_station_in_period method: ${err}`));
                    return;
                }
                resolve(result);
            }));
        });
    }
    get_max_min_temperature_of_station_in_period(station, startTimestamp, endTimestamp) {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
                let result = { minTemperature: null, maxTemperature: null };
                try {
                    let resp = yield this.pool.query("SELECT MIN(Temperature) as MinTemperature, MAX(Temperature) as MaxTemperature FROM INSTANTANEOUS_DATA WHERE StationName = ? AND Timestamp >= ? AND Timestamp < ?", [station, startTimestamp, endTimestamp]);
                    if (resp.length > 0) {
                        result.minTemperature = resp[0]["MinTemperature"];
                        result.maxTemperature = resp[0]["MaxTemperature"];
                    }
                }
                catch (err) {
                    reject(new Error(`Database get_max_min_temperature_of_station_in_period method: ${err}`));
                    return;
                }
                resolve(result);
            }));
        });
    }
    close() {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
                try {
                    yield pool.end();
                }
                catch (err) {
                    reject(new Error(`Database close method: ${err}`));
                    return;
                }
                resolve();
            }));
        });
    }
}
exports.MariaDBHandler = MariaDBHandler;
