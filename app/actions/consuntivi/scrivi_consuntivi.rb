#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ConsuntiviActions
  ##
  # Scrivi i consuntivi letti del file del DB
  #
  # **Expects:**
  # - `consuntivi` (`Array`) consuntivi di Steg letti dai file scaricati via FTP
  #
  class ScriviConsuntivi
    # @!parse
    #   extend FunctionalLightService::Action
    #   extend ForecastConcern::Excel
    extend FunctionalLightService::Action

    expects :consuntivi

    # @!method DownloadConsuntivi(ctx)
    #
    #   @!scope class
    #
    #   @param ctx [FunctionalLightService::Context]
    #
    #   @expects consuntivi [Array] consuntivi di Steg letti dai file scaricati via FTP
    #
    #   @return [FunctionalLightService::Context, FunctionalLightService::Context.fail_and_return!]
    executed do |ctx|
      try! do
        first_row = worksheets("DB").Range("B4").end(-4121).row + 1
        worksheets("DB").Range("B#{first_row}").Resize(ctx.consuntivi.size, ctx.consuntivi.first.size).Value = ctx.consuntivi
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco a scrivere i consuntivi al file #{Ikigai::Config.file.db_xls}",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end
  end
end
