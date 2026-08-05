#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ReportActions
  ##
  # Salvo i file Forecast.xlsm | Db.xlsm | DB2.xlsm se il report che sto generando è un consuntivo
  class SaveAllFile
    # @!parse
    #   extend ForecastConcern::Excel
    extend FunctionalLightService::Action

    executed do |ctx|
      save("DB.xlsm")
      save("DB2.xlsm")
      save("Forecast.xlsm")
    end

    # chiama la funzione per salvare il file
    #
    # @param workbook_name [String] nome del file da salvare
    #
    # @return [Void, FunctionalLightService::Context.fail_and_return!]
    def self.save(workbook_name)
      try! do
        save_workbook(workbook_name)
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco a salvare il file #{workbook_name}",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end

    private_class_method :save
  end
end
