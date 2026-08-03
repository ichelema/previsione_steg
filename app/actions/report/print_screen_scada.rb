#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ReportActions
  ##
  # Faccio il printscreen di scada
  #
  # **Promises:**
  # - `path_printscreen_scada` (`String`) Path del printscreen di scada
  #
  class PrintScreenScada
    # @!parse
    #   extend FunctionalLightService::Action
    extend FunctionalLightService::Action

    promises :path_printscreen_scada

    # @!method PathPdfOldForecast(ctx)
    #
    #   @!scope class
    #
    #   @param ctx [FunctionalLightService::Context]
    #
    #   @promises path_printscreen_scada [String] Path del printscreen di scada
    #
    #   @return [FunctionalLightService::Context, FunctionalLightService::Context.fail_and_return!]
    executed do |ctx|
      try! do
        # ctx.path_pdf_old_report = nil
        file_name = "SCADA_#{DateTime.now.strftime("%d%m%Y_%H%M")}.jpg"
        ctx.path_printscreen_scada = (File.expand_path Ikigai::Config.path.print_screen_scada + file_name).tr("/", "\\")
        _stdout, stderr, _wait_thr = Open3.capture3("MiniCap.exe -save \"#{ctx.path_printscreen_scada}\" -capturemon 1 -exit -nofocus -stderr")
        raise stderr unless stderr.empty?
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco a fare il printscreen di scada",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end
  end
end
