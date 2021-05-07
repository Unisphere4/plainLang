async function eventFilterv5(contractAddress, contractAbi, _provider) 
{
    const iface = new ethers.utils.Interface(contractAbi);
    const logs = await _provider.getLogs({
        address: contractAddress
    });
    console.log("logs = ", logs);

    const decodedEvents = logs.map(log => {
        iface.decodeEventLog("AgreementCreated", log.data) 
    });
    
    console.log("decodedEvents = ", decodedEvents);
    const agreementNumber = decodedEvents.map(event => event["values"]["agreementNumber"]);
    const originator = decodedEvents.map(event => event["values"]["originator"]);
    const token = decodedEvents.map(event => event["values"]["token"]);
    
    return [agreementNumber, originator, token];
    
    // Get unindexed data -- to be used in order to reduce indexing and also because there are more than 4 important pieces of data we need from each event
    /*const decoder = new ethers.utils.AbiCoder();
    const unindexedEvents = events.inputs.filter(event => event.indexed === false);
    const decodedLogs = logs.map(log => decoder.decode(unindexedEvents, log.data);*/
    
}

// Get contract ABI from Hardhat file
var fs = require('fs');
var jsonFile = "/home/chris/dev/plainlang/artifacts/contracts/PlainLang.sol/PlainLang.json";
var parsed= JSON.parse(fs.readFileSync(jsonFile));
var plainabi = parsed.abi;

returnValues = await eventFilterv5(lang.address, plainabi, provider);
console.log("returnValues = ", returnValues);