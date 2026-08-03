#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ForecastActions
  ##
  # Compila in il file Forecast,xlsm con la mia previsone
  #
  # **Expects:**
  # - `previsione` (`Hash<Array>`) Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
  # - `previsione_up` (`Hash<Array>`) Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
  # - `previsione_down` (`Hash<Array>`) Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
  # - `dispersione` (`Hash<Array>`) Mette in un hash la mia disperzione, nel quale ogni chiave e un anno, e i valoru sono un array con tutti le curve relative a quell'anno
  # - `daily_evolution` (`Hash`) contiene previsione corrente
  # - `workbook` (`WIN32OLE`)
  #
  class CompilaForecastExcel
    # @!parse
    #   extend FunctionalLightService::Action
    extend FunctionalLightService::Action

    expects \
      :previsione,
      :previsione_up,
      :previsione_down,
      :dispersione,
      :daily_evolution,
      :workbook

    # @!method CompilaForecastExcel(ctx)
    #
    #   @!scope class
    #
    #   @param ctx [FunctionalLightService::Context]
    #
    #   @expects previsione [Hash<Array>] la mia previsione ogni chiave dell'Hash è una stazione
    #   @expects previsione_up [Hash<Array>] contiene tutte le curve suddivise per stazione che sono sopra la mia previsione
    #   @expects previsione_down [Hash<Array>] contiene tutte le curve suddivise per stazione che sono sotto la mia previsione
    #   @expects dispersione [Hash<Array>] hash della disperzione, nel quale ogni chiave e un anno, e i valori sono un array con tutti le curve relative a quell'anno
    #   @expects daily_evolution [Hash] Previsione corrente
    #   @expects workbook [WIN32OLE] file excel del mio forecast
    #
    #   @return [FunctionalLightService::Context, FunctionalLightService::Context.fail_and_return!]
    executed do |ctx|
      screen_updating(false)
      calculation(ExcelConst::XlManual)
      compila(ctx.previsione, "Previsione")
      compila(ctx.previsione_down, "Previsione_Down") unless ctx.previsione_down.nil?
      compila(ctx.previsione_up, "Previsione_UP") unless ctx.previsione_up.nil?
      compila_dispersione unless ctx.dispersione.nil?
      compila_daily_evolution
      screen_updating(true)
      calculation(ExcelConst::XlAutomatic)
    end

    # compila il relativo foglio del file forecast con la previsione passata come parametro
    #
    # @param previsione [Hash<Array>] previsione
    # @param sheet [String] foglio da selezionare
    #
    # @return [Void]
    def self.compila(previsione, sheet)
      try! do
        previsione.each do |ps, v|
          column = column_ps(ps)
          ctx.workbook.Worksheets(sheet).Range("#{column}3:#{column}26").value = v.each_slice(1).to_a
        end
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco scrivere la #{sheet} nel file #{Ikigai::Config.file.excel_forecast}",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end

    # compila la tabella daily evolution del foglio forecast del forecast
    #
    # @return [Void]
    def self.compila_daily_evolution
      try! do
        hour = ctx.dig(:env, :command_options, :H).to_i
        if hour.between?(10, 22)
          rnum = hour - 3
          worksheet = ctx.workbook.sheets("Forecast")
          worksheet.Range("$D$#{rnum}").value = ctx.daily_evolution[:nomina]
          worksheet.Range("$F$#{rnum}").value = ctx.daily_evolution[:previsione_v3]
          worksheet.Range("$H$#{rnum}").value = ctx.daily_evolution[:progressivo]
          worksheet.Range("$J$#{rnum}").value = ctx.daily_evolution[:nomina_goal]
        end
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco a compilare la tabella daily evolution foglio forecast del file #{Ikigai::Config.file.excel_forecast}",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end

    # compila il foglio della dispersione del file forecast
    #
    # @return [Void]
    def self.compila_dispersione
      try! do
        ctx.workbook.Worksheets("Previsione_Dispersione").Range("B3:H4000").ClearContents
        first_cell = 3
        last_cell = 0
        ctx.dispersione.each do |k, v|
          if k == "anno"
            ctx.workbook.Worksheets("Previsione_Dispersione").Range("B3:B#{ctx.dispersione["anno"].size + 2}").value = ctx.dispersione["anno"]
          else
            first_cell = last_cell == 0 ? 3 : last_cell + 1
            last_cell += last_cell == 0 ? ctx.dispersione[k].size + 2 : ctx.dispersione[k].size
            column_year = column_year(k)
            ctx.workbook.Worksheets("Previsione_Dispersione").Range("#{column_year}#{first_cell}:#{column_year}#{last_cell}").value = ctx.dispersione[k]
          end
        end
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco scrivere disperzione delle curve nel file #{Ikigai::Config.file.excel_forecast}",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end

    # seleziona la colonna relativa all'anno
    #
    # @param year [Integer]
    #
    # @return [String]
    def self.column_year(year)
      case year
      when 2017 then "C"
      when 2018 then "D"
      when 2019 then "E"
      when 2020 then "F"
      when 2021 then "G"
      when 2022 then "H"
      when 2023 then "I"
      when 2024 then "J"
      when 2025 then "K"
      end
    end

    # seleziona la colonna relativa alla ps
    #
    # @param ps [String]
    #
    # @return [String]
    def self.column_ps(ps)
      case ps
      when "feriana" then "C"
      when "kasserine" then "D"
      when "zriba" then "E"
      when "nabeul" then "F"
      when "korba" then "G"
      end
    end

    private_class_method \
      :column_ps,
      :column_year,
      :compila,
      :compila_daily_evolution,
      :compila_dispersione
  end
end
