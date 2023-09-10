import express, {Request, Response, Express} from 'express';
import jwt from "jsonwebtoken";
import cors from "cors";
import {MariaDBHandler} from "./database";
import { type } from 'os';

// Create the PostgreSQL handler
var dbHandler = new MariaDBHandler(
	"127.0.0.1",
	"root",
	"Vialedellapace14!",
	"Mushrooms"
);

// Setup express for API
const mushroomServer: Express = express();
mushroomServer.use(express.json({limit: '20mb'}));
mushroomServer.use(cors({}));
const parser = express.urlencoded({extended: false});
const serverPort: number = 8001;

// Define authentication levels for APIs
const NO_PRIVILEDGE_REQUIRED: number = 0;
const USER_LEVEL: number = 1;
const ADMIN_LEVEL: number = 2;

// Check if variable is an object
function isObject(variable: any) : boolean {
	return variable !== null && typeof variable == 'object' && !Array.isArray(variable);
  }

// Issue a new JWT token
function issueJwt(username: string, authLevel: number): string {
	let jwtSecretKey: string = "=H}3NKzBbrJG}EX3";

	let payload: {authLevel: number} = {
		authLevel: authLevel,
	};
	
	let signOption: {issuer: string, subject: string, expiresIn: string} = {
		issuer: "Mushrooms",
		subject: username,
		expiresIn:  "8h"
	};

	return jwt.sign(payload, jwtSecretKey, signOption);
}

// Verify auth token
function verifyJwt(token: string, username: string) {
	let jwtSecretKey = "=H}3NKzBbrJG}EX3";

	try {
		let verifyOption: {issuer: string, subject: string, expiresIn: string} = {
			issuer: "Mushrooms",
			subject: username,
			expiresIn:  "8h",
		}

		return jwt.verify(token, jwtSecretKey, verifyOption);
	} catch (err) {
		return null;
	}
}

// Validate JWT
function validateJwt(req: Request, minLevel: number): boolean {
	
	// Get header fields
	let token: string | undefined = req.header("token");
	let username: string | undefined = req.header("username");
    
   	// Missing auth token
    if (token === undefined || username === undefined) {
        return false;
    }

	let jwtPayload: any = verifyJwt(token, username);

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

function renewJwt(username: string, token: string): string | null {
	
	// Missing auth token
    if (typeof token !== "string" || typeof username !== "string") {
        return null;
    }

	let jwtPayload: any = verifyJwt(token, username);

	// Check if the token is valid
	if (jwtPayload === null) {
		return null;
	}
	else if (isObject(jwtPayload) === false) {
		return null;
	}
	else if (jwtPayload.hasOwnProperty("authLevel") === false) {
		return null;
	}
	else if (Number.isInteger(jwtPayload["authLevel"]) === false) {
		return null;
	}

	return issueJwt(username, jwtPayload["authLevel"]);
}

function errorOccurred(message: string, res: Response, resMessage: string = ""){
	console.log(message);
	res.status(500).end(resMessage);
}

// Let the user authenticate
mushroomServer.post("/login", parser, async (req: Request, res: Response) => {
	
	// Check the required request fields
	try {
		const requiredFields: string[] = ["username", "password"];

		let missingRequiredFields: boolean = false;

		requiredFields.forEach((field: string) => {
			if(!(field in req.body) && missingRequiredFields === false) {
				res.status(400).end(`Missing required fields! Field: ${field}`);
				missingRequiredFields = true;
			}
		});

        if (missingRequiredFields) {
            return;
        }

		var username: string = String(req.body.username).trim();
		var password: string = String(req.body.password).trim();

	} catch(err) {
		errorOccurred(`Error in login API when parsing the request\n${err}`, res, "Error in login API when parsing the request");
		return;
	}

	// User's privilege level. If the auth is wrong or the user do not exists it is -1
	let authLevel: number = -1;

	// Check the auth
	try{
		authLevel = await dbHandler.authenticate_user(username, password);
	} catch(e) {
		errorOccurred(`Error in login API when checking the user in DB\n${e}`, res, "Error in login API when checking the user in DB");
		return;
	}

    try{
        // Check if invalid auth level
        if (authLevel < 0) {
            res.status(403).json({reason: "authentication"});
            return;
        }

        // Generate the JWT token
        const token = issueJwt(username, authLevel);

		res.setHeader("Content-Type","application/json");
		res.status(200).json({"token": token});
		res.end();
    }
    catch(err){
        errorOccurred(`Error in login API when creating the token\n${err}`, res, "Error in login API when creating the token")
    }
});

mushroomServer.post('/get_stations', parser, async (req: Request, res: Response) => {
	
	// Check if an auth token is present
	try {
		if (validateJwt(req, USER_LEVEL) == false) {
			res.status(403).json({reason: "authentication"});
			return;
		}
	} catch(err) {
		errorOccurred(`Error while checking JWT get_stations API\n${err}`, res, "Error while checking JWT get_stations API");
		return;
	}
	
	try{
        let result: Map<string, {latitude: number, longitude: number, altitude: number, lastUpdate: number}> = await dbHandler.get_stations();
		let payload: any = {};

        for (let stationName of result.keys()) {
			let value = result.get(stationName);
			let sensors: Array<string> = await dbHandler.get_sensors_per_station(stationName);

			if (value !== undefined){
				payload[stationName] = {latitude: value.latitude, longitude: value.longitude, altitude: value.altitude, lastUpdate: value.lastUpdate.toString(), sensors: sensors};
			}
        }
		res.status(200).json(payload);
	}
	catch(err){
		errorOccurred(`Error in get_stations API\n${err}`, res, "Error in get_stations API");
	}
})

mushroomServer.post('/get_data_of_stations', parser, async (req: Request, res: Response) => {
	
	// Check if an auth token is present
	try {
		if (validateJwt(req, USER_LEVEL) == false) {
			res.status(403).json({reason: "authentication"});
			return;
		}
	} catch(err) {
		errorOccurred(`Error while checking JWT get_data_of_stations API\n${err}`, res, "Error while checking JWT get_data_of_stations API");
		return;
	}
	
	try{
		const requiredFields: string[] = ["stations", "startTimestamp", "endTimestamp"];
		
		let missingRequiredFields: boolean = false;

		requiredFields.forEach((field: string) => {
			if(!(field in req.body) && missingRequiredFields === false) {
				res.status(400).end(`Missing required fields! Field: ${field}`);
				missingRequiredFields = true;
			}
		});

        if (missingRequiredFields) {
            return;
        }

		let stations: any = null;
			
		if (typeof req.body.stations === "string"){
			stations = JSON.parse(req.body.stations);
		}
		else {
			stations = JSON.parse(JSON.stringify(req.body.stations));
		}

		if (Array.isArray(stations) === false){
			res.status(400).end(`Stations is not an array!`);
			return;
		}

		let startTimestamp: number = parseInt(String(req.body.startTimestamp), 10);
		let endTimestamp: number = parseInt(String(req.body.endTimestamp), 10);

		if (isNaN(startTimestamp) || isNaN(endTimestamp)){
			res.status(400).end(`Invalid numerical values!`);
			return;
		}

		if (startTimestamp > endTimestamp){
			res.status(400).end(`Start timestamp is greater than end timestamp!`);
			return;
		}

		let startDate: Date = new Date(startTimestamp * 1000);
		let startDayTimestamp = Math.round(new Date(`${startDate.getFullYear()}-${startDate.getMonth() + 1}-${startDate.getDate()} 00:00:00`).getTime() / 1000);

		let endDate: Date = new Date(endTimestamp * 1000);
		let endDayTimestamp = Math.round(new Date(`${endDate.getFullYear()}-${endDate.getMonth() + 1}-${endDate.getDate()} 00:00:00`).getTime() / 1000);

		let payload: any = {};
		let divider: number = 24 * 3600;

		if (endTimestamp - startTimestamp <= 86400 * 3){
			divider = 4 * 3600;
		}
		else if (endTimestamp - startTimestamp <= 86400 * 7){
			divider = 8 * 3600;
		}

		for (let station of stations){
			payload[station] = {};
			
			for(let day = startDayTimestamp; day < endDayTimestamp; day += 24 * 3600){
				let dayString = new Date(day * 1000).toLocaleDateString('it-IT', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
				let dayData: any = {};

				let precipitationIsAvailable: boolean = false;
				let temperatureIsAvailable: boolean = false;
				let humidityIsAvailable: boolean = false;
				let windSpeedIsAvailable: boolean = false;
				let windDirectionIsAvailable: boolean = false;

				if (divider != 24 * 3600){
					for (let interval = day; interval < day + 24 * 3600; interval += divider){
						let intervalString = `${new Date(interval * 1000).getHours()}:00 - ${new Date((interval + divider) * 1000).getHours()}:00`;
	
						dayData[intervalString] = {"precip.": "-", "temp.": "-", "min temp.": "-", "max temp.": "-", "umidità": "-", "vel. vento": "-", "direz. vento": "-"};
	
						let sum_precipitation = await dbHandler.get_sum_precipitation_of_station_in_period(station, interval, interval + divider);
						let ave_instantaneous = await dbHandler.get_average_instantaneous_data_of_station_in_period(station, interval, interval + divider);
						let max_min_temperature = await dbHandler.get_max_min_temperature_of_station_in_period(station, interval, interval + divider);
	
						if (sum_precipitation !== null){
							dayData[intervalString]["precip."] = (Math.round(sum_precipitation * 10) / 10).toString();
							precipitationIsAvailable = true;
						}
						
						if (ave_instantaneous["temperature"] !== null){
							dayData[intervalString]["temp."] = (Math.round(ave_instantaneous["temperature"] * 10) / 10).toString();
							temperatureIsAvailable = true;
						}
	
						if (ave_instantaneous["humidity"] !== null){
							dayData[intervalString]["umidità"] = (Math.round(ave_instantaneous["humidity"] * 10) / 10).toString();
							humidityIsAvailable = true;
						}
	
						if (ave_instantaneous["windSpeed"] !== null){
							dayData[intervalString]["vel. vento"] = (Math.round((ave_instantaneous["windSpeed"] * 3.6) * 10) / 10).toString();
							windSpeedIsAvailable = true;
						}
	
						if (ave_instantaneous["windDirection"] !== null){
							dayData[intervalString]["direz. vento"] = (Math.round(ave_instantaneous["windDirection"] * 10) / 10).toString();
							windDirectionIsAvailable = true;
						}

						if (max_min_temperature["minTemperature"] !== null){
							dayData[intervalString]["min temp."] = (Math.round(max_min_temperature["minTemperature"] * 10) / 10).toString();
						}

						if (max_min_temperature["maxTemperature"] !== null){
							dayData[intervalString]["max temp."] = (Math.round(max_min_temperature["maxTemperature"] * 10) / 10).toString();
						}
					}
				}

				dayData["tot"] = {"precip.": "-", "temp.": "-", "min temp.": "-", "max temp.": "-", "umidità": "-", "vel. vento": "-", "direz. vento": "-"};

				let sum_precipitation = await dbHandler.get_sum_precipitation_of_station_in_period(station, day, day + 24 * 3600);
				let ave_instantaneous = await dbHandler.get_average_instantaneous_data_of_station_in_period(station, day, day + 24 * 3600);
				let max_min_temperature = await dbHandler.get_max_min_temperature_of_station_in_period(station, day, day + 24 * 3600);

				if (sum_precipitation !== null){
					dayData["tot"]["precip."] = (Math.round(sum_precipitation * 10) / 10).toString();
					precipitationIsAvailable = true;
				}

				if (ave_instantaneous["temperature"] !== null){
					dayData["tot"]["temp."] = (Math.round(ave_instantaneous["temperature"] * 10) / 10).toString();
					temperatureIsAvailable = true;
				}

				if (ave_instantaneous["humidity"] !== null){
					dayData["tot"]["umidità"] = (Math.round(ave_instantaneous["humidity"] * 10) / 10).toString();
					humidityIsAvailable = true;
				}

				if (ave_instantaneous["windSpeed"] !== null){
					dayData["tot"]["vel. vento"] = (Math.round((ave_instantaneous["windSpeed"] * 3.6) * 10) / 10).toString();
					windSpeedIsAvailable = true;
				}

				if (ave_instantaneous["windDirection"] !== null){
					dayData["tot"]["direz. vento"] = (Math.round(ave_instantaneous["windDirection"] * 10) / 10).toString();
					windDirectionIsAvailable = true;
				}

				if (max_min_temperature["minTemperature"] !== null){
					dayData["tot"]["min temp."] = (Math.round(max_min_temperature["minTemperature"] * 10) / 10).toString();
				}

				if (max_min_temperature["maxTemperature"] !== null){
					dayData["tot"]["max temp."] = (Math.round(max_min_temperature["maxTemperature"] * 10) / 10).toString();
				}

				if (precipitationIsAvailable === false && temperatureIsAvailable === false && humidityIsAvailable === false && windSpeedIsAvailable === false && windDirectionIsAvailable === false){
					payload[station][dayString] = {"error": "No data"};
				}
				else{
					payload[station][dayString] = {"columns": ["Periodo"]};

					if (precipitationIsAvailable){
						payload[station][dayString]["columns"].push("Pioggia");
					}
					if (temperatureIsAvailable){
						payload[station][dayString]["columns"].push("Temp.");
						payload[station][dayString]["columns"].push("Min Temp.");
						payload[station][dayString]["columns"].push("Max Temp.");
					}
					if (humidityIsAvailable){
						payload[station][dayString]["columns"].push("Umidità");
					}
					if (windSpeedIsAvailable){
						payload[station][dayString]["columns"].push("Vel. Vento");
					}
					if (windDirectionIsAvailable){
						payload[station][dayString]["columns"].push("Direz. Vento");
					}

					payload[station][dayString]["rows"] = [];

					for (let interval in dayData){
						let row: string[] = [interval];

						if (precipitationIsAvailable){
							row.push(dayData[interval]["precip."]);
						}
						if (temperatureIsAvailable){
							row.push(dayData[interval]["temp."]);
							row.push(dayData[interval]["min temp."]);
							row.push(dayData[interval]["max temp."]);
						}
						if (humidityIsAvailable){
							row.push(dayData[interval]["umidità"]);
						}
						if (windSpeedIsAvailable){
							row.push(dayData[interval]["vel. vento"]);
						}
						if (windDirectionIsAvailable){
							row.push(dayData[interval]["direz. vento"]);
						}

						payload[station][dayString]["rows"].push(row);
					}
				}
			}
		}

		res.status(200).json(payload);
	}
	catch(err){
		errorOccurred(`Error in get_data_of_stations API\n${err}`, res, "Error in get_data_of_stations API");
	}
})

mushroomServer.post('/renew', parser, async (req: Request, res: Response) => {
	
	// Check if an auth token is present
	try {
		const requiredFields: string[] = ["username", "token"];
		
		let missingRequiredFields: boolean = false;

		requiredFields.forEach((field: string) => {
			if(!(field in req.body) && missingRequiredFields === false) {
				res.status(400).end(`Missing required fields! Field: ${field}`);
				missingRequiredFields = true;
			}
		});

        if (missingRequiredFields) {
            return;
        }

		if (typeof req.body.username !== "string" || typeof req.body.token !== "string"){
			res.status(400).end(`Invalid params!`);
			return;
		}

	} catch(err) {
		errorOccurred(`Error while checking JWT check_cookie API\n${err}`, res, "Error while checking JWT check_cookie API");
		return;
	}
	
	try{
		let token: string|null = renewJwt(req.body.username, req.body.token);
		if (token === null){
			res.status(403).json({reason: "authentication"});
			return;
		}

		res.status(200).json({"token": token});
	}
	catch(err){
		errorOccurred(`Error in check_cookie API\n${err}`, res, "Error in check_cookie API");
	}

});

try {
	var handler = mushroomServer.listen(serverPort, async () => {
		console.log("Mushrooms HTTP Server started");
	});

	process.on("SIGTERM", () => {
		handler.close(() => {
			process.exit(0);
		});
	});
} catch(e) {
	dbHandler.close();
	console.log(`Impossible to start the server because:\n${e}`);
	process.exit(1);
}