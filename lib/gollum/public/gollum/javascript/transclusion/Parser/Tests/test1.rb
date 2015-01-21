require_relative '../app/application'

codigo = CodeParser.new(File.open(File.dirname(__FILE__) + "/code1.txt", "r").read)

# p codigo.getFunction("ole1")
p codigo.getFunction("ole2")
# p codigo.getFunction("Teste.dentroClasse")
# p codigo.getAST
