#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ReportActions
  ##
  # Crea l'HTML da inserire nel body dell'e-mail
  #
  # **Promises:**
  # - `html` (`String`) html da inserire del body dell'e-mail
  #
  class MakeHtml
    # @!parse
    #   extend FunctionalLightService::Action
    #   extend ForecastConcern::Excel
    extend FunctionalLightService::Action

    promises :html

    # @!method MakeHtml(ctx)
    #
    #   @!scope class
    #
    #   @param ctx [FunctionalLightService::Context]
    #
    #   @promises html [String] html da inserire del body dell'e-mail
    #
    #   @return [FunctionalLightService::Context, FunctionalLightService::Context.fail_and_return!]
    executed do |ctx|
      # rubocop:disable Layout/ExtraSpacing
      try! do
        # @type [Hash]
        prv_report = {dicom: {title: "DICOM"}, prv: {title: "PREVISIONE"}, simulazione: {title: "SIMULAZIONE"}}
        prv_report.each do |k, v|
          prv_report[k][:previsione]          = {value: number_with_delimiter(previsione(k)) + " (#{(previsione_delta(k) * 100).round}%)", name: "Previsione V3"}
          prv_report[k][:nomina_steg]         = {value: number_with_delimiter(previsione_nomina_steg(k)), name: "Nomina STEG"}
          prv_report[k][:nom_steg_progre]     = {value: number_with_delimiter(previsione_nomina_steg_progressivo(k)) + " (#{(previsione_nomina_steg_progressivo_delta(k) * 100).round}%)", name: "STEG Progres."}
          prv_report[k][:consuntivo]          = {value: number_with_delimiter(previsione_consuntivi(k)), name: "Consuntivo"}
          prv_report[k][:consuntivo_d_meno_1] = {value: number_with_delimiter(previsione_consuntivi_consuntivo_d_meno_1(k)), name: "Consuntivo D-1"}
        end
        # @type [Hash]
        prv_daily_evolution = {nomina: [], previsione: [], steg_progr: [], nomina_goal: [], goal_avg: []}
        prv_daily_evolution.each do |k, v|
          7.upto(19) do |i|
            v << number_with_delimiter(daily_evolution(k, i))
          end
        end
        ctx.html = ERB.new(File.read("./template/report.html.erb"), trim_mode: "-").result(binding).freeze
        # rubocop:enable Layout/ExtraSpacing
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco a creare l'HTML da inserire nel body dell'email",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end

    # Trasforma un numero senza punti in un numero con il punto per separare le migliaia
    #
    # @param number [Integer] numero da trasformare in formato decimale con i punti 10044 => "10.044"
    #
    # @return [String]
    def self.number_with_delimiter(number)
      return "" if number == ""
      return "0" if number == 0
      return number if number < 1000
      number.to_s.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/) do |digit_to_delimit|
        "#{digit_to_delimit}."
      end
    end

    private_class_method :number_with_delimiter
  end
end
