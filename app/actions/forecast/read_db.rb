#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ForecastActions
  ##
  # Prendo dal db tutti i dati consuntivi
  #
  # @note Scarta le righe con Exclude == "Y" o con Flow_Korba vuoto
  #
  # @example promises consuntivi value
  #     [
  #        [0] {
  #         "Date"            => #<DateTime: 2015-10-20T08:00:00+00:00 ((2457316j,28800s,0n),+0s,2299161j)>,
  #         "Giorno"          => 20,
  #         "Mese"            => 10,
  #         "Anno"            => 2015,
  #         "Ora"             => 8.0,
  #         "Giorno_Sett_Num" => 2,
  #         "Festivo"         => "N",
  #         "Festivita"       => "N",
  #         "Stagione"        => "autunno",
  #         "Exclude"         => "N",
  #         "Peso"            => 1.0,
  #         "Flow_Feriana"    => 70.0,
  #         "Flow_Kasserine"  => 1.0,
  #         "Flow_Zriba"      => 256.0,
  #         "Flow_Nabeul"     => 49.0,
  #         "Flow_Korba"      => 7.0,
  #         "Flow_Totale"     => 9235.0
  #       }
  #     ]
  class ReadDb
    extend FunctionalLightService::Action

    # @promises consuntivi [Array<Hash>] Consuntivi di Steg
    promises :consuntivi
    # @expects excel [WIN32OLE]
    expects :excel

    executed do |ctx|
      try! do
        workbook = ctx.excel.Workbooks(Ikigai::Config.file.db2_xls)
        worksheet = workbook.worksheets("DB2")
        last_row = worksheet.Range("S2").end(-4121).row
        value = worksheet.Range("$A$1:$T$#{last_row}").value.reject { |x| x[18] == "" || x[12] == "Y" }
        ctx.consuntivi = IceNine.deep_freeze!(value[1..].map(&value[0].method(:zip)).map(&:to_h))
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco a leggere il file #{Ikigai::Config.file.db_csv} controllare di avere fatto l'esportazione del database",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
      ctx.fail_and_return!("Controllare che nel file DB2.csv siano presenti i dati esportortati dal DB") if ctx.consuntivi.nil?
    end
  end
end
