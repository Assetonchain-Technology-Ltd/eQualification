// Libaray declare
const express = require('express')
const path = require('path');
const cors = require('cors');
const request = require('request');
const morgan = require('morgan');
const bodyParser = require('body-parser');
const logger = require('./lib/logger');

//app setting
const app = express();
app.use(cors());
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(morgan('combined', { stream: logger.stream }));

app.use(express.urlencoded({
    extended: true
}));
app.use(bodyParser.json());


// Variable declare
const PORT = process.env.PORT ||5000;


//Router Declare
const workerprofile = require('./routes/workerProfile.route');

//Router mapping 
app.use('/workerprofile',workerprofile);



module.exports = app;

app.listen(process.env.PORT||5000,console.log('5000'));



