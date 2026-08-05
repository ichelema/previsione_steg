#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ShareActions
  ##
  # Refresha i collegamenti del file Excel forecast
  class RefreshLinks
    # @!parse
    #   extend ForecastConcern::Excel
    extend FunctionalLightService::Action

    executed do |ctx|
      try! do
        workbook_forecast = ctx.excel.Workbooks(Ikigai::Config.file.excel_forecast)
        path = workbook_forecast.Worksheets("Config").Range("C4").value
        refresh_links(workbook_forecast, path)
      end.map_err do |err|
        msg = <<~HEREDOC
          Non riesco ad aggiornare i link nel file del Forecast
          Controllare di aver aggiornato nel file #{Ikigai::Config.file.excel_forecast}
          In Dati => Modifica Collegamenti
          Aggiornare il Collegamento a Programmazione con il mese corretto
        HEREDOC
        ctx.fail_and_return!(
          {message: msg,
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end
  end
end
