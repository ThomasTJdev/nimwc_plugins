import json, ospaths
writeFile(currentSourcePath().parentDir / "plugins.json", parseJson(readFile(currentSourcePath().parentDir / "plugins.json")).pretty & "\n")
