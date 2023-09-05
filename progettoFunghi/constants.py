class _AbstractEnum():
	def __init__(self) -> None:
		raise Exception("Enum Classes can't be concrete!")

	@classmethod
	def list(cls):
		varList = [attr for attr in vars(cls) if not callable(getattr(cls, attr)) and not attr.startswith("__")]
		return [vars(cls)[elem] for elem in varList]
	
class STATION_KEYS(_AbstractEnum):
	NAME = "Name"
	LATITUDE = "Latitude"
	LONGITUDE = "Longitude"
	ALTITUDE = "Altitude"

class DATA_KEYS(_AbstractEnum):
	TEMPERATURE = "Temperature"             # K
	PRECIPITATION = "Precipitation"         # KG/M**2
	RELATIVE_HUMIDITY = "Humidity"          # %
	WIND_DIRECTION = "Wind Direction"       # DEGREES
	WIND_SPEED = "Wind Speed"               # M/S

class DATA_CODES(_AbstractEnum):
	TEMPERATURE = "B12101"
	PRECIPITATION = "B13011"
	RELATIVE_HUMIDITY = "B13003"
	WIND_DIRECTION = "B11001"
	WIND_SPEED = "B11002"

class STATION_CODES(_AbstractEnum):
	NAME = "B01019"
	LATITUDE = "B05001"
	LONGITUDE = "B06001"
	ALTITUDE = "B07030"

class TOSCANA_DATA_HTTP_KEYS(_AbstractEnum):
	PRECIPIATION = "pluvio"
	TEMPERATURE = "termo"
	WIND = "anemo"
	UMIDITY = "igro"
