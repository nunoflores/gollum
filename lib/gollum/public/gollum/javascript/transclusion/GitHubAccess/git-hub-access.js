
/**
 * Class responsible for accessing the github repository and getting its files.
 * 
 * @param config Object with the repository configurations.
 */

function GitHubAccess (config)
{
	this.config = config;
	
	
	/**
	 * Get a file from the current repository.
	 * 
	 * @param file Path to file.
	 * @param version Commit SHA of where to get the file. Optional.
	 * @param callback Function to be called when complete (parameter with content).
	 */
	this.getFile = function(file, version, callback)
	{
		var user = new Gh3.User(this.config.user);
		var repository = new Gh3.Repository(this.config.repository, user);
		
		repository.fetch(function (err, res) //Try to get repository
		{
			if (err)
			{
	    		callback("Repository not found", true);
			}
			repository.fetchBranches(function (err, res) //Try to get branch
			{
				if(err)
				{
					callback("Error fetching branches", true);
				}
				
	    		var branch = repository.getBranchByName(config.branch == null ? 'master' : config.branch);
		    	try
		    	{
		    		branch.fetchContents(function (err, res) //Try to get contents from root
		    		{
		    			if (err)
		    			{
		    				callback("Error fetching contents", true);
		    			}
						_changeDirAndOpen(branch, file.split('/'), version, callback); //Try to open directories or files
					});
				} catch (e) {
					callback("Branch not found", true);
				}
	    	});
		});
	};
	
	/**
	 * Deconstruct the file path and change iteratively the folder.
	 * If in the last folder, try opening the file.
	 * 
	 * @param {Object} previous Previous folder opened.
	 * @param {Object} path Path to desconstruct.
	 * @param {Object} version SHA of the version to get.
	 * @param {Object} callbackF unction to be called when complete (parameter with content).
	 */
	function _changeDirAndOpen(previous, path, version, callback) 
	{
		if(path.length == 1)
		{
			_getFile(previous, path[0], version, callback);
		}
		else
		{
			var dir = previous.getDirByName(path[0]);
			try 
			{
				dir.fetchContents(function (err, res2)
				{
					if (err)
					{
						callback("Error fetching contents inside folder " + path[0], true);
					}
					_changeDirAndOpen(dir, path.splice(1,path.length), version, callback);
				});
			} catch (e) {
				callback("Path to file not valid. Folder " + path[0] + " doesn't exist.", true);
			}
		}
	}
	
	/**
	 * Function to get the file code.
	 * 
	 * @param {Object} directory Directory where the file should exist.
	 * @param {Object} file Filename.
	 * @param {Object} version SHA of the version to get.
	 * @param {Object} callbackF unction to be called when complete (parameter with content).
	 */
	function _getFile(directory, file, version, callback)
	{
		var file_info = directory.getFileByName(file);
		
		if(version == null)
		{
			try
			{
				file_info.fetchContent(function (err, res)
				{
					if (err)
					{
						callback("Error fetching contents", true);
					}
					callback(file_info.getRawContent());
				});
			}catch(e) {
				callback("Could not open file", true);
			}
		}
		else
		{
			file_info.fetchCommits(function (err, res) {
				try
				{
					file_info.fetchContentVersion(version, function (err, res)
					{
						if (err)
						{
							callback("Error fetching contents", true);
						}
						callback(file_info.getRawContent());
					});
				}catch(e) {
					callback("Could not open file", true);
				}
	         });
		}
	}
	
}
