#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ConsuntiviActions
  ##
  # Legge i consuntivi che ha scaricato via FTP da scada
  class LeggiConsuntivi
    # @!parse
    #   extend ForecastConcern::Excel
    extend FunctionalLightService::Action

    @@first_row = nil
    @@last_row = nil

    # @promises consuntivi [Array] consuntivi di Steg letti dai file scaricati via FTP
    promises :consuntivi

    executed do |ctx|
      try! do
        ctx.consuntivi = nil
        if first_row == last_row
          ctx.skip_remaining!("Nessun consuntivo da leggere")
        else
          ctx.consuntivi = consuntivi
          raise "Nessun consuntivo da leggere, controllare che siano stati scaricati corretamente dall'FTP di Scada" if ctx.consuntivi.size == 0
        end
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco a leggere i Consuntivi scaricati dall'FTP di Scada",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end

    # cerca nel file delle misure la misura da leggere, attraverso il codice passato come parametro
    #
    # @param file [Array]
    # @param value [Array] stringa da cercare
    #
    # @return [String]
    def self.get_value(file, value)
      search = file.grep(/^#{value}/)
      return "" if search.empty?
      return "" if search[0].split(";").size != 4
      search[0].split(";")[1].sub(".", ",")
    end

    # trova la prima riga vuota del DB
    #
    # @return [Integer]
    def self.first_row
      @@first_row ||= worksheets("DB").Range("B4").end(-4121).row + 1
    end

    # trova l'ultima riga del DB da compilare
    #
    # @return [Integer]
    def self.last_row
      return @@last_row unless @@last_row.nil?
      @@last_row = first_row
      now = (Time.now - 3600).strftime("%d-%m-%Y %H")
      until worksheets("DB").Range("a#{@@last_row}").value.strftime("%d-%m-%Y %H") == now
        @@last_row += 1
      end
      @@last_row
    end

    # legge i consuntivi e li mette in un array
    #
    # @return [Array]
    def self.consuntivi
      consuntivi = []
      worksheets("DB").range("A#{first_row}:B#{last_row - 1}").rows.each do |row|
        full_pathname = nil
        (0..7200).step(3600).each do |index|
          data = (row.cells(1, 1).value + 7200 - index)
          file_name = "DatiSITE_#{data.strftime("%Y%m%d%H")}00.dat"
          full_pathname = Ikigai::Config.path.consuntivi_scada + file_name
          break if File.exist?(full_pathname)
        end
        if File.exist?(full_pathname)
          file = File.readlines(full_pathname).map(&:chomp)
          parse_value = []
          parse_value << get_value(file, "MXCPS01QTDEPIQ")
          parse_value << get_value(file, "MXCPS04QTDEPIQ")
          parse_value << get_value(file, "MXCPS14QTDEPIQ")
          parse_value << get_value(file, "MXCPS16QTDEPIQ")
          parse_value << get_value(file, "MXCPS17QTDEPIQ")
          parse_value << get_value(file, "MXFESEDCSATTAMB")
          parse_value << get_value(file, "MXSKSETTAMB")
          parse_value << get_value(file, "MXKOSETTAMB")
          parse_value << get_value(file, "MXCBSETTAMB")
          consuntivi << parse_value
        else
          raise "File #{file_name} non trovato"
        end
      end
      consuntivi
    end

    private_class_method \
      :get_value,
      :first_row,
      :last_row,
      :consuntivi
  end
end
