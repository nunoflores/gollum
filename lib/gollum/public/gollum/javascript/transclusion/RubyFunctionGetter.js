
/**
 * Class that combines all the elements and converts the file call syntax in highlighted code.
 * 
 * @param {Object} config Configuration file with repository definition.
 */
function RubyFunctionGetter(config)
{
	this.config = config;
	this.config.language = 'ruby'; //Due to the parser, the code language is forced.
	var github;
	var beuatifier;
	this.files = []; //CodeParser objects
	this.files_status = []; //Deferred objects with file loading status
	this.codes_status = []; //Deferred objects with code loading status
	this.codes_temp = [];
	
	/**
	 * Parse the file call syntax in HTML elements with "gettify" class, gets the corresponding code,
	 * gets the method and colors the resulting code.
	 */
	this.gettify = function()
	{
		var getter = this;
		$( document ).ready(function() {
			$('.gettify').each(function () {
				
				var text = $(this).text();
				var path = {}, flags = {};
				
				$(this).text('Loading...');
				$(this).addClass('gettified').removeClass('gettify');
				
				var config = text.match("^(.*?)(?=(\@))")[0];
				config = config.split(";");
				var configs = {user: config[0], repository: config[1], branch: config[2]};
				configs.language = 'ruby';

				github = new GitHubAccess(configs);
				beuatifier = new Beuatifier(configs);
				path.file = text.match("\@([A-Za-z0-9\-_.\/])+")[0];
				path.file = path.file.substring(1,path.file.length);
				path.version = text.match("\:[a-fA-F0-9]+");
				if(path.version) path.version = path.version[0].substring(1, path.version[0].length);
				path.method = text.match("\#([A-Za-z0-9_.])+");
				path.method = path.method[0].substring(1, path.method[0].length);
				flags.lines  = text.match("-l [0-9\-\, ]+");
				if(flags.lines) flags.lines = flags.lines[0].substring(3, flags.lines[0].length);
				flags.showLines = text.match("( -ls )|( -ls$)") != null ? true : false;
				
				getter.insertFunction(path, flags, $(this));
				
			});
		});
	};
	
	/**
	 * Function to "beautify" the code, once it is available.
	 */
	this.insertFunction = function (path, flags, place)
	{
		var method_code = {};
		$.when(this._getMethod(path, method_code)).done(function () {
			beuatifier.insertCode(method_code.code, place, flags, path.method);
		}).fail(function () {
			beuatifier.insertError(method_code.code, place);
		});
	};
	
	/**
	 * Get a specific file.
	 * Checks if it is already loaded, otherwise gets it from github.
	 */
	this._getFile = function(path, file_code)
	{
		var loaded = $.Deferred();
		var converted_path = this._convertPath(path, false);
		var this_class = this;
		
		if (this.files_status[converted_path])
		{
			$.when(this.files_status[converted_path]).always(function () {
				file_code.code = this_class.files[converted_path];
			}).done(function (){
				loaded.resolve();
			}).fail(function (){
				loaded.reject();
			});
		}
		else
		{
			var getting_file = $.Deferred();
			this.files_status[converted_path] = getting_file;
			github.getFile(path.file, path.version, function (content, err)
			{
				if (err == null || !err){
					this_class.files[converted_path] = new CodeParser(content);
					file_code.code = this_class.files[converted_path];
					getting_file.resolve();
					loaded.resolve();
				} else {
					file_code.code = content;
					getting_file.reject();
					loaded.reject();
				} 
			});
		}
		return loaded;
	};
	
	/**
	 * Get a method from a specific file.
	 * If the method is from a specific version, checks if it is available on browser memory, otherwise fetches it.
	 * Check if no one else asked for that method already and whether the code is already available to use or not. Otherwise, fetch it.
	 */
	this._getMethod = function(path, method_code)
	{
		var loaded = $.Deferred();
		var converted_path = this._convertPath(path);
		
		if (path.version == null)
		{
			var this_class = this;
			if (this.codes_status[converted_path])
			{
				$.when(this.codes_status[converted_path]).always(function () {
					method_code.code = this_class.codes_temp[converted_path];
				}).done(function () {
					loaded.resolve();
				}).fail(function () {
					loaded.reject();
				});
			}
			else
			{
				var getting_code = $.Deferred();
				this.codes_status[converted_path] = getting_code;
				
				var file_code = {};
				$.when(this._getFile(path, file_code)).always(function () {
					
				}).done(function () {
					try {
						var code =  file_code.code.getFunction(path.method);
						this_class.codes_temp[converted_path] = code;
						method_code.code = code;
					}catch(e){
						method_code.code = e;
						getting_code.reject();
						loaded.reject();
					}
					
					getting_code.resolve();
					loaded.resolve();
				}).fail(function () {
					method_code.code = file_code.code;
					getting_code.reject();
					loaded.reject();
				});
			}
		}
		else
		{
			var storage_code = $.jStorage.get(converted_path);
			if (storage_code)
			{
				method_code.code = storage_code;
				loaded.resolve();
			}
			else if (this.codes_status[converted_path])
			{
				$.when(this.codes_status[converted_path]).always(function () {
					method_code.code = $.jStorage.get(converted_path);
				}).done(function () {
					loaded.resolve();
				}).fail(function () {
					loaded.reject();
				});
			}
			else
			{
				var getting_code = $.Deferred();
				this.codes_status[converted_path] = getting_code;
				
				var file_code = {};
				$.when(this._getFile(path, file_code)).always(function () {
					
				}).done(function () {
					try {
						var code =  file_code.code.getFunction(path.method);
						$.jStorage.set(converted_path, code);
						method_code.code = code;
					}catch (e) {
						method_code.code = e;
						getting_code.reject();
						loaded.reject();
					}
					
					getting_code.resolve();
					loaded.resolve();
				}).fail(function () {
					method_code.code = file_code.code;
					getting_code.reject();
					loaded.reject();
				});
			}
		}
		return loaded;
	};
	
	/**
	 * Generate the complete file path for a file.
	 */
	this._convertPath = function(file_path, showMethod)
	{
		var path = this.config.user + '/' + this.config.repository + '/' + this.config.branch + '/';
		path += file_path.file + '/' + file_path.version;
		if(showMethod == null || showMethod) path += '/' + file_path.method;
		
		return path;
	};

}