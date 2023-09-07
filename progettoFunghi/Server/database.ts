import { resolve } from "path";

const mariadb = require('mariadb');
const pool = mariadb.createPool({host: process.env.DB_HOST, user: process.env.DB_USER, connectionLimit: 5});

class MariaDBHandler {
    host: string;
    user: string;
    password: string;
    database: string;  
    pool: any;

    constructor(host: string, user: string, password: string, database: string) {
		this.host = host;
		this.user = user;
		this.password = password;
		this.database = database;
		this.pool = mariadb.createPool({
            host: this.host,
            user: this.user,
            password: this.password,
            database: this.database,
            port: 3306,
            connectionLimit: 10
        });
	}

    async authenticate_user(username: string, password: string): Promise<number> {
		return new Promise(async (resolve, reject) => {
            let auth_level: number = -1;
            
            try{
                if (typeof username !== "string" || typeof password !== "string") {
                    throw new Error("Invalid username or password. Username or password is not string.");
                }
                
                let resp = await this.pool.query("SELECT AuthLevel FROM USER WHERE Username = ? AND Password = ?", [username, password]);

                // The user exists
                if (resp.length > 0) {
                    auth_level = parseInt(resp[0]["AuthLevel"]);
                    if (isNaN(auth_level)) {
                        throw new Error(`Invalid auth_level for user: ${username}. Auth_level is not numerical. Auth_level: ${resp[0]["AuthLevel"]}`);
                    }
                } 
            }
            catch(err) {
                reject(new Error(`Database authenticate_user method. ${err}`));
                return;
            }

            resolve(auth_level);
		});
	}

    async get_stations(): Promise<Map<number, {latitude: number, longitude: number, altitude: number, lastUpdate: number}>> {
		return new Promise(async (resolve, reject) => {
            let result: Map<number, {latitude: number, longitude: number, altitude: number, lastUpdate: number}> = new Map();
            
            try{                
                let resp = await this.pool.query("SELECT Name, Latitude, Longitude, Altitude, LastUpdate FROM STATION ORDER BY Name");

                for(let record of resp) {
                    result.set(record["Name"], {latitude: record["Latitude"], longitude: record["Longitude"], altitude: record["Altitude"], lastUpdate: record["LastUpdate"]});
                }
            }
            catch(err) {
                reject(new Error(`Database get_stations method. ${err}`));
                return;
            }

            resolve(result);
		});
	}

    async get_sum_precipitation_of_station_in_period(station: string, startTimestamp: number, endTimestamp: number): Promise<number | null> {
        return new Promise(async (resolve, reject) => {            
            try{
                let resp = await this.pool.query("SELECT SUM(Precipitation) as Somma FROM PERIODIC_DATA WHERE StationName = ? AND StartTimestamp >= ? AND EndTimestamp < ?", [station, startTimestamp, endTimestamp]);

                if (resp.length > 0) {
                    resolve(resp[0]["Somma"]);
                }
            }
            catch(err) {
                reject(new Error(`Database get_sum_precipitation_of_station_in_period method. ${err}`));
                return;
            }

            resolve(null);
        });
    }

    async get_average_instantaneous_data_of_station_in_period(station: string, startTimestamp: number, endTimestamp: number): Promise<{temperature: number|null, humidity: number|null, windSpeed: number|null, windDirection: number|null}> {
        return new Promise(async (resolve, reject) => {
            let result: {temperature: number|null, humidity: number|null, windSpeed: number|null, windDirection: number|null} = {temperature: null, humidity: null, windSpeed: null, windDirection: null};
            
            try{
                let resp = await this.pool.query("SELECT AVG(Temperature) as Temperature, AVG(Humidity) as Humidity, AVG(WindSpeed) as WindSpeed, AVG(WindDirection) as WindDirection FROM INSTANTANEOUS_DATA WHERE StationName = ? AND Timestamp >= ? AND Timestamp < ?", [station, startTimestamp, endTimestamp]);

                if (resp.length > 0) {
                    result.temperature = resp[0]["Temperature"];
                    result.humidity = resp[0]["Humidity"];
                    result.windSpeed = resp[0]["WindSpeed"];
                    result.windDirection = resp[0]["WindDirection"];
                }                
            }
            catch(err) {
                reject(new Error(`Database get_average_instantaneous_data_of_station_in_period method. ${err}`));
                return;
            }

            resolve(result);
        });
    }

    async get_max_min_temperature_of_station_in_period(station: string, startTimestamp: number, endTimestamp: number): Promise<{minTemperature: number|null, maxTemperature: number|null}> {
        return new Promise(async (resolve, reject) => {
            let result: {minTemperature: number|null, maxTemperature: number|null} = {minTemperature: null, maxTemperature: null};
            
            try{
                let resp = await this.pool.query("SELECT MIN(Temperature) as MinTemperature, MAX(Temperature) as MaxTemperature FROM INSTANTANEOUS_DATA WHERE StationName = ? AND Timestamp >= ? AND Timestamp < ?", [station, startTimestamp, endTimestamp]);

                if (resp.length > 0) {
                    result.minTemperature = resp[0]["MinTemperature"];
                    result.maxTemperature = resp[0]["MaxTemperature"];
                }                
            }
            catch(err) {
                reject(new Error(`Database get_max_min_temperature_of_station_in_period method. ${err}`));
                return;
            }

            resolve(result);
        });
    }

    async close(): Promise<void>{
        return new Promise(async (resolve, reject) => {
            try {
                await pool.end();
            }
            catch(err) {
                reject(new Error(`Database close method. ${err}`));
                return;
            }

            resolve();
        });
    }
}

export {MariaDBHandler}