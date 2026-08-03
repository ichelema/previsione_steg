#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ReportActions
  ##
  # Setto il path della directory dove andare a salvare i PDF
  #
  # **Expects:**
  # - `env` (`Hash`) Enviroment Application
  #
  # **Promises:**
  # - `path` (`String`) Path dei file pdf
  #
  class GetPath
    # @!parse
    #   extend FunctionalLightService::Action
    extend FunctionalLightService::Action

    # @expects env[Hash] Enviroment Application
    # @promises path[String] Path dei file pdf
    expects :env
    promises :path

    # @!method GetPath(ctx)
    #
    #   @!scope class
    #
    #   @param ctx [FunctionalLightService::Context]
    #
    #   @expects env [Hash] Enviroment Application
    #
    #   @promises path [String] Path dei file pdf
    #
    #   @return [FunctionalLightService::Context, FunctionalLightService::Context.fail_and_return!]
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
