#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ShareActions
  ##
  # Setta nel file excel la data e la salva nella variabile data
  #
  # **Promises:**
  # - `data` (`String`) Contiene data e ora del forecast da eseguire
  #
  class SetExcelDay
    # @!parse
    #   extend FunctionalLightService::Action
    #   extend ForecastConcern::Excel
    extend FunctionalLightService::Action

    promises :data

    # @!method SetExcelDay(ctx)
    #
    #   @!scope class
    #
    #   @param ctx [FunctionalLightService::Context]
    #
    #   @promises data [String] Contiene data e ora del forecast da eseguire
    #
    #   @return [FunctionalLightService::Context, FunctionalLightService::Context.fail_and_return!]
    executed do |ctx|
      ctx.data = nil
      # @type [String]
      data_hour = ctx.dig(:env, :command_options, :day) + " #{ctx.dig(:env, :command_options, :hour)}:00:00"
      try! do
        set_day(data_hour)
        ctx.data = data_hour.delete("/").freeze
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco a impostare la data in file #{Ikigai::Config.file.excel_forecast} Forecast V1 cella M3",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end
  end
end
