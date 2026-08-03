#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ReportActions
  ##
  # Setto il path dove prendere il PDF del vecchio forecast
  #
  # **Promises:**
  # - `path_pdf_old_report` (`String`) Path del pdf dell'ultimo report creato dal vecchio forecast
  #
  class PathPdfOldForecast
    # @!parse
    #   extend FunctionalLightService::Action
    extend FunctionalLightService::Action

    promises :path_pdf_old_report, :path_pdf_old_report

    # @!method PathPdfOldForecast(ctx)
    #
    #   @!scope class
    #
    #   @param ctx [FunctionalLightService::Context]
    #
    #   @promises path_pdf_old_report [String] Path del pdf dell'ultimo report creato dal vecchio forecast
    #
    #   @return [FunctionalLightService::Context, FunctionalLightService::Context.fail_and_return!]
    executed do |ctx|
      try! do
        ctx.path_pdf_old_report = nil
        if ctx.env.dig(:command_options, :type) == "forecast"
          ctx.path_pdf_old_report = Dir["#{Ikigai::Config.path.forecast_old_pdf}/*.pdf"].max_by { |f| File.ctime(f) }
        end
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco a trovare l'ultimo file pdf del vecchio forecast",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end
  end
end
