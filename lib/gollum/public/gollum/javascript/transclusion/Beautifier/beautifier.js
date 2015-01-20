
/**
 * Class to highlight the syntax of the code.
 * 
 * @param config Object with configurations (namely the language of the code)
 */

function Beuatifier(config)
{
	this.config = config;
	
	/**
	 * Function to insert the code with color highlighting.
	 * 
	 * @param code Code to color.
	 * @param place Html element where to put the result.
	 * @param flags Flags to show lines and/or highlits a specific line(s).
	 */
	this.insertCode = function(code, place, flags, method)
	{
		var random = Math.floor(Math.random()*101);
		css_selector = method.replace('.',"\\\\.");
		
		var code_to_insert = '<a role="button" onclick="$(\'pre#'+css_selector+'\').toggle();">'+method+'</a><pre id="'+method+'" class="transclusion_method" style="display:none;"';
		if (flags.showLines){
			code_to_insert += ' class="line-numbers"';
		}
		if (flags.lines != null){
			code_to_insert += ' data-line="'+flags.lines+'"';
		}
		code_to_insert += '><code id="beautifier-'+random+'" class="language-'+this.config.language+'">';
		code_to_insert += code;
		code_to_insert += '</code></pre>';
		$(place).html(code_to_insert);
		Prism.highlightElement($('#beautifier-'+random)[0]);
	};
	
	/**
	 * Insert an error message.
	 */
	this.insertError = function(text, place)
	{
		$(place).html('<span class="error">'+text);
	};
}