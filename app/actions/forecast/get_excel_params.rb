#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ForecastActions
  ##
  # Prendo da excel tutti i dati di input per eseguire il Forecast
  class GetExcelParams
    # @!parse
    #   extend ForecastConcern::Excel
    extend FunctionalLightService::Action

    # @promises params [Hash] parametri letti da excel per eseguire il forecast
    promises :params

    executed do |ctx|
      ctx.params = Hamster::Hash[
        day: get_day,
        giorno_settimana: get_giorno_settimana,
        festivo: get_festivo,
        festivita: get_festivita,
      ]
      ctx.params
    end

    # Prendo da "Forecast.xlsm" foglio "Day" la tabella con nome Day, che contiene il giorno di cui devo fare il forecast
    #
    # @return [FunctionalLightService::Result::Success, FunctionalLightService::Context.fail_and_return!]<br>
    #   Se finisce con seccesso [Array] Contiene le caratteristiche del giorno che devo fare il forecast, tipo il giorno settimana, se è un festivo, ecc..
    #   ```ruby
    #     [
    #        [0] {
    #          "Date"            => 2021-11-25 08:00:00 +0100,
    #          "Giorno"          => 25.0,
    #          "Mese"            => 11.0,
    #          "Anno"            => 2021.0,
    #          "Ora"             => 8.0,
    #          "Giorno_Sett_Num" => 4.0,
    #          "Giorno_Sett_Txt" => "giovedì",
    #          "Festivo"         => "N",
    #          "Festivita"       => "N",
    #          "Stagione"        => "autunno"
    #        }
    #      ]
    #   ```
    #   Se Finisce in errore, ritorna in stato failure e il messaggio di errore "Controllare che nel file Forecast.xlsm ci sia il foglio Day con presenta la tabella Day"
    #
    def self.get_day
      try! { day }.map_err {
        ctx.fail_and_return!("Controllare che nel file Forecast.xlsm ci sia il foglio Day con presenta la tabella Day")
      }
    end

    # Prendo da "Forecast.xlsm" foglio "Forecast V1" se devo prendere un giorno della settima esatto
    #
    # @return [FunctionalLightService::Result::Success, FunctionalLightService::Context.fail_and_return!]<br>
    #   Se finisce con seccesso [String] se è un giorno della settimana esatto ["SI", "NO"]
    #   Se Finisce in errore, ritorna in stato failure e il messaggio di errore
    def self.get_giorno_settimana
      unless ["SI", "NO"].include? giorno_settimana
        ctx.fail_and_return!(
          <<~HEREDOC
            Controllare che nel file: Forecast.xlsm 
            Foglio: "Forecast V1"
            Giorno Settimana esatto: ci sia "SI" o "NO"
          HEREDOC
        )
      end
      giorno_settimana
    end

    # Prendo da "Forecast.xlsm" foglio "Forecast V1" se è un giorno festivo
    #
    # @return [FunctionalLightService::Result::Success, FunctionalLightService::Context.fail_and_return!]<br>
    #   Se finisce con seccesso [String] Se è un giorno festivo ["SI", "NO", "ALL"]
    #   Se Finisce in errore, ritorna in stato failure e il messaggio di errore
    def self.get_festivo
      unless ["SI", "NO", "ALL"].include? festivo
        ctx.fail_and_return!(
          <<~HEREDOC
            Controllare che nel file: Forecast.xlsm 
            Foglio: "Forecast V1"
            Festivo: ci sia "SI" o "NO" o "ALL"
          HEREDOC
        )
      end
      festivo
    end

    # Prendo da "Forecast.xlsm" foglio "Forecast V1" se è un festività
    #
    # @return [FunctionalLightService::Result::Success, FunctionalLightService::Context.fail_and_return!]<br>
    #   Se finisce con seccesso [String] Se è una festività ["SI", "NO", "ALL"]
    #   Se Finisce in errore, ritorna in stato failure e il messaggio di errore
    def self.get_festivita
      unless ["SI", "NO", "ALL"].include? festivita
        ctx.fail_and_return!(
          <<~HEREDOC
            Controllare che nel file: Forecast.xlsm 
            Foglio: "Forecast V1"
            Festivita: ci sia "SI" o "NO" o "ALL"
          HEREDOC
        )
      end
      festivita
    end

    private_class_method \
      :get_day,
      :get_giorno_settimana,
      :get_festivo,
      :get_festivita
  end
end
