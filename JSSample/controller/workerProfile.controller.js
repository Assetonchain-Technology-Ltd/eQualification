const Web3 = require('web3');
const fs = require('fs');
const logger = require('../lib/logger');
const provider = "http://118.140.169.14:2323";
const NOTVALIDADDRESS=1;
const NOTINTEGER=2;
const PUBLICENS="0x6B86471B49d91017fd9F3AcF5608249EB0EACEdA";
const VIEWER="0x6E6ff139d6851217066Ec1c08e541ECCa3B676F9";

exports.getAttribute = function(req,res){
		let targetAccount = req.query.account;
		let attributeIndex = parseInt(req.query.arrt_index,10);
		let org = req.query.org;

		if(typeof targetAccount!= 'undefined' && typeof attributeIndex != 'undefined' && typeof org != 'undefined')
		{
			var web3 = new Web3(new Web3.providers.HttpProvider(provider)); 
			var mask=0;
			mask = web3.utils.isAddress(targetAccount)? (mask):(mask|NOTVALIDADDRESS);
			mask = Number.isInteger(attributeIndex)? (mask):(mask|NOTINTEGER);
			web3.eth.defaultAccount=VIEWER;
			web3.eth.ens.registryAddress=PUBLICENS;

			if(mask==0){
					var ens = web3.eth.ens;
					ens.getAddress('workerprofile').then(function(result){
					    var tokenAddress = result;	
						console.log(`WorkerProfileToken Address : \t${tokenAddress}`);
						if(tokenAddress!='0x0000000000000000000000000000000000000000'){
							const tokenabi = JSON.parse(fs.readFileSync('./abi/WorkerProfileToken.json')).abi;
							var token = new web3.eth.Contract(tokenabi,tokenAddress);
							var txobj = {from:VIEWER,gas:300000000,gasPrice:0};
							token.methods.balanceOf(targetAccount).call(txobj).then(function(balance){
								console.log(`Worker ${targetAccount} got ${balance}  WorkerProfileToken`);
								token.methods.tokenOfOwnerByIndex(targetAccount,0).call(txobj).then(function(tokenid){
									var profileAddress =web3.utils.toHex(tokenid);
									console.log(`Worker Profile Address : ${profileAddress}`);
									const workerlogicabi = JSON.parse(fs.readFileSync('./abi/WorkerProfileLogic.json')).abi;
									var workerlogic = new web3.eth.Contract(workerlogicabi,profileAddress);
									workerlogic.methods.getAttributeByIndex(org,attributeIndex).call(txobj).then(function(result){
											console.log(`Attribute name(hash) : ${result[0]} , Attribute Value : ${result[1]} , Attribute Data type : ${result[2]}`);
											res.send(result);
									}).catch((error)=>{   //end of WorkerProfieLofic getAttribute then
										console.log(`WorkerProfile - getAttribute error : ${error}`);
										res.status(500).send(`WorkerProfile getAttribute error : ${error}`);
									}); //end of WorkerProfileLogic getAttributeByIndex catch 
								}).catch((error)=>{  // end of tokenOfOwnerByIndex then
									console.log(`WorkerProfileToken - tokenOfOwnerByIndex error : ${error}`);
									res.status(500).send(`WorkerProfileToken tokenOfOwnerByIndex error : ${error}`);
								}); //end of tokenOfOwnerByIndex catch
							}).catch((error)=>{  // end of balanceOf then
								console.log(`WorkerProfileToken - balanceOf error : ${error}`);
								res.status(500).send(`WorkerProfileToken balanceOf error : ${error}`);
							});// end of balanceOf catch
						}else{
							//Report Error
							console.log(`Address is 0!`);
							res.status(500).send(`The ENS resolve address of WorkerProfileToken to 0`);
						}
					}).catch((error)=>{  //end of ens getAddress the
						console.log(`ENS - getAddress error : ${error}`);
						res.status(500).send(`ENS Resolve error : ${error}`);
					}); // end of end getAddress catch
			}else{
				//Report error
				console.log(`Mask error : ${mask}`);

			}

		}else{
			 console.log(`Type checking error`);
		} 
}
