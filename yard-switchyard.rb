# frozen_string_literal: true

# Plugin YARD per la DSL di FunctionalLightService/Switchyard.
#
# Intercetta le chiamate `promises :x, :y` ed `expects :x, :y` nel corpo della
# classe e attacca il contratto alla documentazione della classe come tag
# @promises/@expects, che YARD renderizza nelle sezioni "Promises:"/"Expects:"
# (vedi --type-name-tag in .yardopts).
#
# Il commento sopra la chiamata puo' arricchire il contratto con tipi e
# descrizioni:
#
#   # @promises excel [WIN32OLE] connessione a Excel
#   # @promises workbook [WIN32OLE]
#   promises :excel, :workbook
#
# I nomi passati alla DSL senza tag esplicito vengono comunque documentati
# (senza tipo). Caricare con: -e yard-switchyard.rb in .yardopts.

YARD::Tags::Library.define_tag("Promises", :promises, :with_types_and_name)
YARD::Tags::Library.define_tag("Expects", :expects, :with_types_and_name)
YARD::Tags::Library.visible_tags |= %i[promises expects]

# Handler per le chiamate DSL promises/expects dentro il corpo della classe.
class SwitchyardContractHandler < YARD::Handlers::Ruby::Base
  handles method_call(:promises)
  handles method_call(:expects)
  namespace_only

  process do
    tag_sym = statement.method_name(true)

    # tag espliciti scritti nel commento sopra la chiamata
    explicit = YARD::Docstring.new(statement.docstring.to_s).tags(tag_sym)

    # nomi dichiarati nella chiamata DSL: promises :excel, :workbook
    names = statement.parameters(false).compact.map do |param|
      param.source.to_s.strip.sub(/\A:/, "").delete(%q{"'})
    end

    names.each do |name|
      tag = explicit.find { |t| t.name.to_s == name } ||
            YARD::Tags::Tag.new(tag_sym, "", nil, name)
      namespace.docstring.add_tag(tag)
    end
  end
end
