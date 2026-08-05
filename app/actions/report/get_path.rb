#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ReportActions
  ##
  # Setto il path della directory dove andare a salvare i PDF
  class GetPath
    extend FunctionalLightService::Action

    # @expects env[Hash] Enviroment Application
    expects :env
    # @promises path[String] Path dei file pdf
    promises :path

    executed do |ctx|
      ctx.path = nil
      path = case ctx.env.dig(:command_options, :type)
                 when "consuntivo"
                   Ikigai::Config.path.consuntivi_pdf
                 when "forecast"
                   Ikigai::Config.path.forecast_pdf

      end
      if path.nil? || !File.directory?(path)
        ctx.fail_and_return!(
          {message: "Constrollare che la directory \"#{File.expand_path(path)}\" esiste",
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
      ctx.path = File.expand_path(path).freeze
    end
  end
end
