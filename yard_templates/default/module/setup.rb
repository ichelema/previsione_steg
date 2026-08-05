# frozen_string_literal: true

# Estensione del template module/class: sezione "Contract" dedicata con i tag
# @expects/@promises attaccati alla classe dal plugin yard-switchyard.
# I tag vengono rimossi dal docstring della classe, cosi' compaiono SOLO nella
# sezione Contract e non nell'Overview (i tag a livello di metodo non sono
# toccati e restano nei Method Details).
def init
  super
  unless @contract_captured
    @contract_captured = true
    @expects = object.docstring.tags(:expects)
    @promises = object.docstring.tags(:promises)
    object.docstring.delete_tags(:expects) if @expects.any?
    object.docstring.delete_tags(:promises) if @promises.any?
  end
  sections.place(:contract).before(:method_summary)
end

def contract
  return if @contract_rendered
  return if (@expects.nil? || @expects.empty?) && (@promises.nil? || @promises.empty?)
  @contract_rendered = true
  erb(:contract)
end
