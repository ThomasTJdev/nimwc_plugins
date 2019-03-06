import json, ospaths
var ugly: string
ugly.toUgly(parseJson(readFile(currentSourcePath().parentDir / "plugins.json")))
writeFile(currentSourcePath().parentDir / "plugins.json", ugly)
