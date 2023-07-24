#!/usr/bin/env zx
$.verbose = false;

import Case from "case";

const OPEN_WEATHER_API_KEY = "9e0ce81aa1aed4f13e1aa8a4a106abd4";

const ip = await $`curl -s ifconfig.me`;
const ipInfo = await fetch(`https://ipinfo.io/${ip}/json`).then((data) =>
	data.json()
);

const [lat, lon] = ipInfo.loc.split(",");

const data = await fetch(
	`https://api.openweathermap.org/data/3.0/onecall?lat=${lat}&lon=${lon}&appid=${OPEN_WEATHER_API_KEY}&units=metric`
).then((res) => res.json());

const { icon, main, description } = data.current.weather[0];
const { sunrise, sunset, pressure, humidity, temp } = data.current;

const iconMap = {
	"01d": "", // Clear sky - day
	"01n": "", // Clear sky - night
	"02d": "", // Few clouds (11-25%) - day
	"02n": "", // Few clouds (11-25%) - night
	"03d": "", // Scattered clouds (25-50%) - day/night
	"03n": "", // Scattered clouds (25-50%) - day/night
	"04d": "", // Broken / Overcast clouds (51-84% / 85-100%) - day/night
	"04n": "", // Broken / Overcast clouds (51-84% / 85-100%) - day/night
	"09d": "", // Shower rain - day
	"09n": "", // Shower rain - night
	"10d": "", // Moderate / heavy rain - day
	"10n": "", // Moderate / heavy rain - night
	"11d": "", // Thunderstorm - day
	"11n": "", // Thunderstorm - night
	"13d": "", // Snow - day
	"13n": "", // Snow - night
	"50d": "", // Fog - day
	"50n": "", // Fog - night
	_: "N/A", // ??
};

console.log(
	`${iconMap[icon]} ${Case.capital(description)} | ${temp.toFixed(0)} °C`
);
