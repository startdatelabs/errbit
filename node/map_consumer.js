const SourceMap = require('source-map');
const fs = require('fs');

var args = process.argv.slice(2);

var fileName = args[0];
var fileContent = fs.readFileSync(fileName);
var rawSourceMap = JSON.parse(fileContent);

var smc = new SourceMap.SourceMapConsumer(rawSourceMap);

var result = smc.originalPositionFor({
  line: parseInt(args[1], 10),
  column: parseInt(args[2], 10)
});
console.log(JSON.stringify(result));
