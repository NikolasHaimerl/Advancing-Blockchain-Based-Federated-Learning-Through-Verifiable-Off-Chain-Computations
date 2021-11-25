const Migrations = artifacts.require("Migrations");
const FederatedModel = artifacts.require("FederatedModel")
const verifier = artifacts.require("Verifier")
const fs = require('fs');
const yaml = require('js-yaml');

module.exports = function (deployer) {
 let fileContents = fs.readFileSync('/home/nikolas/PycharmProjects/MasterThesis_SoftwareEngineering/CONFIG.yaml', 'utf8');
  let data = yaml.safeLoad(fileContents);
  deployer.deploy(Migrations);
  deployer.deploy(FederatedModel,data.DEFAULT.InputDimension,data.DEFAULT.OutputDimension,data.DEFAULT.LearningRate,data.DEFAULT.Precision,data.DEFAULT.BatchSize,data.DEFAULT.IntervalTime);
  deployer.deploy(verifier,{gas:data.DEFAULT.Gas});
};


