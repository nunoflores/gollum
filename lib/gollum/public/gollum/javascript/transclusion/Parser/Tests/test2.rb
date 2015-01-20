require_relative '../app/application'

codigo = CodeParser.new(File.open(File.dirname(__FILE__) + "/code2.txt", "r").read)

# p codigo.getFunction("Twilio.Util.url_encode")
p codigo.getFunction("Twilio.Util.get_string")
# p codigo.getAST