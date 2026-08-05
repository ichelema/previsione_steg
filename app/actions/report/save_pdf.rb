#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ReportActions
  ##
  # Chiama una funzione Excel per salvare su PDF lo sheet Forecast
  class SavePdf
    # @!parse
    #   extend ForecastConcern::Excel
    extend FunctionalLightService::Action

    executed do |ctx|
      feedback = save_pdf(ctx.path_pdf_report)
      unless feedback
        ctx.fail_and_return!(
          {message: "Non sono riuscito a salvare il file \"#{ctx.path_pdf_report}\"",
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end
  end
end
