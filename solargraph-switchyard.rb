# frozen_string_literal: true

# Convention Solargraph per la DSL di FunctionalLightService/Switchyard.
#
# Legge le chiamate `expects :x` / `promises :y` nel corpo delle classi action
# (con gli eventuali tag @expects/@promises nel commento sopra la chiamata per
# tipi e descrizioni) e arricchisce il docstring del pin della classe con il
# contratto in markdown: l'hover mostra la descrizione della classe seguita da
# Expects/Promises presi direttamente dalla DSL, senza duplicare commenti.
#
# Caricamento: in .solargraph.yml
#   plugins:
#   - "./solargraph-switchyard"

class SwitchyardConvention < Solargraph::Convention::Base
  DSL_LINE = /^\s*(expects|promises)\s+(:\w+(?:\s*,\s*:\w+)*)/
  TAG_LINE = /^\s*#\s*@(expects|promises)\s+(\w+)(?:\s+\[([^\]]*)\])?\s*(.*)$/

  # @param source_map [Solargraph::SourceMap]
  # @return [Solargraph::Environ]
  def local source_map
    code = source_map.source.code
    return EMPTY_ENVIRON unless code.match?(DSL_LINE)

    lines = code.lines
    source_map.pins.each do |nspin|
      next unless nspin.is_a?(Solargraph::Pin::Namespace)
      next unless nspin.type == :class && nspin.location
      next if nspin.name.to_s.empty? # pin root del file, non e' una classe reale
      # commento vecchio stile con contratto gia' scritto a mano: non duplicare
      next if nspin.comments.to_s.match?(/\*\*(Expects|Promises):\*\*/)

      contract = extract(lines, nspin.location.range)
      next if contract.empty?

      enrich(nspin, render(contract))
    end
    EMPTY_ENVIRON
  end

  private

  # Appende il contratto al commento del pin reale della classe, cosi'
  # l'hover resta un blocco unico: descrizione prima, contratto dopo.
  # I memoizzati derivati dal commento vengono azzerati per farli rigenerare.
  #
  # @param nspin [Solargraph::Pin::Namespace]
  # @param contract_md [String]
  # @return [void]
  def enrich nspin, contract_md
    merged = [nspin.comments.to_s.strip, contract_md].reject(&:empty?).join("\n\n")
    nspin.instance_variable_set(:@comments, merged)
    nspin.instance_variable_set(:@docstring, nil)
    nspin.instance_variable_set(:@documentation, nil)
  end

  # Scansiona le righe del corpo della classe: raccoglie i tag nel commento
  # sopra la chiamata DSL e i nomi dichiarati nella chiamata stessa.
  #
  # @param lines [Array<String>]
  # @param range [Solargraph::Range]
  # @return [Hash{String => Array<Array(String, String, String)>}]
  def extract lines, range
    found = { "expects" => [], "promises" => [] }
    pending = {} # nome => [tipo, descrizione] dai tag del commento

    (range.start.line..range.ending.line).each do |i|
      line = lines[i] or next
      if (m = line.match(TAG_LINE))
        pending[m[2]] = [m[3], m[4]]
      elsif (m = line.match(DSL_LINE))
        m[2].scan(/:(\w+)/).flatten.each do |name|
          type, desc = pending[name]
          found[m[1]] << [name, type, desc]
        end
        pending = {}
      elsif !line.strip.start_with?("#") && !line.strip.empty?
        pending = {}
      end
    end

    found.reject { |_, items| items.empty? }
  end

  # @param contract [Hash]
  # @return [String]
  def render contract
    parts = []
    { "expects" => "Expects", "promises" => "Promises" }.each do |key, title|
      next unless contract[key]

      parts << "**#{title}:**"
      contract[key].each do |name, type, desc|
        line = "- `#{name}`"
        line += " (`#{type}`)" if type && !type.empty?
        # i token con parentesi angolari (Array<Hash>) nel testo libero vengono
        # racchiusi in backtick: come code span attraversano indenni la pipeline
        # markdown dell'hover, che altrimenti li tratterebbe da tag HTML
        unless desc.to_s.strip.empty?
          line += " #{desc.strip.gsub(/(?<!`)[\w:]+<[^<>]+>/) { |t| "`#{t}`" }}"
        end
        parts << line
      end
      parts << ""
    end
    parts.join("\n").strip
  end
end

Solargraph::Convention.register SwitchyardConvention
