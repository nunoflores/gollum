//URL to the parser server
CodeParser.SERVICE_URL = "http://weaki.movercado.org:8081/";


/**
 * Class to comunicate with the parser located on a server.
 * Receives code as text, sends it to the server and stores the session ID of the server.
 * 
 * @param {Object} codeGiven Code to parse
 */
function CodeParser(codeGiven)
{
	var code = codeGiven;
	var serverId;
	var lastCodeToReturn;
	
	$.ajax({
		type: "POST",
		url: CodeParser.SERVICE_URL,
		data: {
			code : code
		},
		async : false
	}).done(function( data ) {
			console.log(data);
			serverId = data;
	});
	
	/**
	 * Function to get a specific method's code.
	 * Once the code is stored in the server, it asks to return a specific method.
	 * 
	 * @param methodToReturn Name of the method to return.
	 */
	this.getFunction = function (methodToReturn)
	{
		if (serverId == "") 
			throw "Code parsing error!";
		
		$.ajax({
			type: "GET",
			url: CodeParser.SERVICE_URL + 'code/',
			data: {
			idCode : serverId,
			method : methodToReturn
			},
			async : false
		}).done(function( data ) {
				lastCodeToReturn = data;
		}).fail(function() {
		    alert( "error" );
		  });
		
		if(lastCodeToReturn == "")
			throw "Method not found!";
			
		return lastCodeToReturn;
	};
}