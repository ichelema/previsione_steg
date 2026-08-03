#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ForecastActions
  # Esegue la media ponderata dei dati filtrati nelo step precedente e crea la mia previsione
  #
  # **Expects:**
  # - `filtered_data_group_by_hour` (`Hash<Array>`) Consuntivi filtrati raggraupati per ora
  #
  # **Promises:**
  # - `previsione` (`Hash<Array>`) Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
  #
  class Previsione
    # @!parse
    #   extend FunctionalLightService::Action
    extend FunctionalLightService::Action

    expects :filtered_data_group_by_hour
    promises :previsione

    # @!method Previsione(ctx)
    #
    #   @!scope class
    #
    #   @param ctx [FunctionalLightService::Context]
    #
    #   @expects filtered_data_group_by_hour [Hash<Array>] Consuntivi filtrati raggraupati per ora
    #
    #   @promises previsione [Hash<Array>] Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
    #
    #   @example previsione
    #       {
    #          "feriana":   [25513.70, 30426.73, 4513.70, 10426.73, ....],
    #          "kasserine": [28513.70, 30426.73, 8513.70, 30426.73, ....],
    #          "zriba":     [18513.70, 30426.73, 18513.70, 20426.73, ....],
    #          "korba":     [38513.70, 30426.73, 58513.70, 10426.73, ....],
    #       }
    #
    #   @return [FunctionalLightService::Context, FunctionalLightService::Context.fail_and_return!]
    executed do |ctx|
      # creo un hash in cui ogni stazione ha un array vuoto
      # {
      #   "feriana"   => [],
      #   "kasserine" => [],
      #   "zriba"     => [],
      #   "nabeul"    => [],
      #   "korba"     => []
      # }
      # @type ctx.previsione [Hash]
      ctx.previsione ||= PS.to_h { |s| [s, []] }

      # scorro le varie ore e prendo solo il valore che è un Hash di tutti i consuntivi filtrati per quell'ora
      # e lo passo al blocco come variabile fcs_hour
      ctx.filtered_data_group_by_hour.each do |hour, fcs_hour|
        # scorro le PS ["feriana","kasserine","zriba","nabeul","korba"]
        # e metto in ctx.previsione[ps] la media ponderata di tutti i dati filtrati per quell'ora
        # quindi ogni stazione ha un array di 24 valori in cui ogni valore è la media ponderata
        #    {
        #       "feriana":   [25513.70, 30426.73, 4513.70, 10426.73, ....],
        #       "kasserine": [28513.70, 30426.73, 8513.70, 30426.73, ....],
        #       "zriba":     [18513.70, 30426.73, 18513.70, 20426.73, ....],
        #       "korba":     [38513.70, 30426.73, 58513.70, 10426.73, ....],
        #    }
        PS.each do |ps|
          try! do
            ctx.previsione[ps] << media_ponderata(ps, fcs_hour) * 1000
          end.map_err do |err|
            ctx.fail_and_return!(
              {message: "Errore non sono riuscito a fare la media ponderata per la ps:#{ps.capitalize} ora:#{hour}",
               detail: err.message,
               location: "#{__FILE__}:#{__LINE__}"}
            )
          end
        end
      end
    end

    # Esegue la media ponderata pesata per la stazione passata come parametro, di tutti i consuntivi filtrati
    #
    # @param ps [String] Ps di cui devo fare la media ponderata
    #
    # @param fcs_hour [Array<Hash> Contiene tutti i dati filtrati per una specifica ora
    #
    # @example params fcs_hour
    #     [
    #        [0] {
    #         "Date"            => #<DateTime: 2015-10-20T08:00:00+00:00 ((2457316j,28800s,0n),+0s,2299161j)>,
    #         "Giorno"          => 20,
    #         "Mese"            => 10,
    #         "Anno"            => 2015,
    #         "Ora"             => 8,
    #         "Giorno_Sett_Num" => 2,
    #         "Festivo"         => "N",
    #         "Festivita"       => "N",
    #         "Stagione"        => "autunno",
    #         "Exclude"         => "N",
    #         "Peso"            => 1.0,
    #         "Flow_Feriana"    => 70.0,
    #         "Flow_Kasserine"  => 1.0,
    #         "Flow_Zriba"      => 256.0,
    #         "Flow_Nabeul"     => 49.0,
    #         "Flow_Korba"      => 7.0,
    #         "Flow_Totale"     => 9235.0
    #       }
    #       ....
    #     ]
    #
    # @return [Float]
    def self.media_ponderata(ps, fcs_hour)
      fcs_hour.then do |forecast|
        # crea un array di array in cui per ogni elemento dell'array prende il consuntivo da Flow_Stazione e il relativo peso
        #  [
        #    [70.0,1.0],
        #    [60.0,1.0],
        #    ....
        #  ]
        #
        forecast.map { |h| [h["Flow_#{ps.capitalize}"], h["Peso"]] }
      end
        .then do |tmp|
        # eseguo la media ponderata vera e propria e mi restituisce un float che è il vaore della media calcolato
        tmp.reduce(0) { |sum, num| sum + num[0] * num[1] } / tmp.reduce(0) { |sum, num| sum + num[1] }
      end
    end

    private_class_method :media_ponderata
  end
end
