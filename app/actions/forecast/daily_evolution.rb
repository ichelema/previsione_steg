#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ForecastActions
  ##
  # Prendo i valori della previsione corrente per copiarli nella tabella daily evolution del forecast
  class DailyEvolution
    # @!parse
    #   extend ForecastConcern::Excel
    extend FunctionalLightService::Action

    #  @expects workbook [WIN32OLE]
    expects :workbook
    # @promises daily_evolution [Hash] Previsione corrente
    promises :daily_evolution

    executed do |ctx|
      try! do
        ctx.workbook.sheets("Forecast").Activate
        daily_evolution = {}
        daily_evolution[:previsione_v1] = ctx.workbook.sheets("Forecast").Range("$X$6").value.round(0 / 0.5)
        daily_evolution[:previsione_v2] = ctx.workbook.sheets("Forecast").Range("$X$8").value.round(0 / 0.5)
        daily_evolution[:previsione_v3] = ctx.workbook.sheets("Forecast").Range("$X$10").value.round(0 / 0.5)
        daily_evolution[:nomina] = ctx.workbook.sheets("Forecast").Range("$X$12").value.round(0 / 0.5)
        daily_evolution[:progressivo] = ctx.workbook.sheets("Forecast").Range("$X$14").value.round(0 / 0.5)
        daily_evolution[:consuntivo] = ctx.workbook.sheets("Forecast").Range("$X$16").value.round(0 / 0.5)
        daily_evolution[:peso_previsione_nomina] = ctx.workbook.sheets("Forecast").Range("$AJ$11").value
        daily_evolution[:correzione_cons_parziale] = ctx.workbook.sheets("Forecast").Range("$AJ$13").value
        daily_evolution[:nomina_goal] = (ctx.workbook.sheets("Nomina_Goal").Range("$D$32").value / 1000).round(0 / 0.5)
        ctx.daily_evolution = daily_evolution.freeze
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco a prendere i valori della previsione corrente per copiarli nella tabella daily evolution del file #{Ikigai::Config.file.excel_forecast}",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end
  end
end
