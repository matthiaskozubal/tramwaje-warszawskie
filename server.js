var express = require('express');
var fs = require('fs');
var exec = require('child_process').exec;
var app = express();

app.use(express.static('static'));

app.get('/line-scheme', function (req, res) {
  fs.readFile('data/line_scheme_26.geojson', function (err, data) {
    if (err) {
      return console.error(err);
    }
    res.setHeader('Content-Type', 'application/json');
    res.send(data);
  });
});

// TODO: async + promises!

app.get('/positions', function (req, res) {
  console.log("[" + new Date().toString() + "] Running R script");
  exec("Rscript analysis/main.R", function (error, stdout, stderr) {
    console.log(stdout + stderr);
    if (error !== null) { console.log('exec error: ' + error); }
    var resultsRunningPath = 'data/vehicles-running.json'
    var resultsHaltedPath = 'data/vehicles-halted.json'
    var dataRunning = null;
    var dataHalted = null;
    if (fs.existsSync(resultsRunningPath)) {
      dataRunning = fs.readFileSync(resultsRunningPath)
    }
    if (fs.existsSync(resultsHaltedPath)) {
      dataHalted = fs.readFileSync(resultsHaltedPath)
    }
    res.setHeader('Content-Type', 'application/json');
    res.send({ "running": JSON.parse(dataRunning), "halted": JSON.parse(dataHalted) });
  });
});

app.listen(3000, function () {
  console.log('Listening on port 3000');
});