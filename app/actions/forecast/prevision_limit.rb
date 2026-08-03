#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ForecastActions
  # Genero gli estremi superiore e inferiore del mio forecast
  #
  # **Expects:**
  # - `previsione` (`Hash<Array>`) Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
  # - `filtered_data_group_by_hour` (`Hash<Array>`) Consuntivi filtrati raggraupati per ora
  # - `data` (`String`) Contiene data e ora del forecast da eseguire
  #
  # **Promises:**
  # - `previsione_up` (`Hash<Array>`) Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
  # - `previsione_down` (`Hash<Array>`) Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
  #
  class PrevisionLimit
    # @!parse
    #   extend FunctionalLightService::Action
    extend FunctionalLightService::Action

    expects :previsione, :filtered_data_group_by_hour, :data
    promises :previsione_up, :previsione_down

    # @!method Previsione(ctx)
    #
    #   @!scope class
    #
    #   @param ctx [FunctionalLightService::Context]
    #
    #   @expects previsione [Hash<Array>] Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
    #   @expects filtered_data_group_by_hour [Hash<Array>] Consuntivi filtrati raggraupati per ora
    #   @expects data [String] Contiene data e ora del forecast da eseguire
    #
    #   @promises previsione_up [Hash<Array>] Mette in un hash la mia previsione_up ogni chiave dell'Hash è una stazione
    #   @promises previsione_down [Hash<Array>] Mette in un hash la mia previsione_down ogni chiave dell'Hash è una stazione
    #
    #   @example previsione_up
    #       {
    #          "feriana":   [25513.70, 30426.73, 4513.70, 10426.73, ....],
    #          "kasserine": [28513.70, 30426.73, 8513.70, 30426.73, ....],
    #          "zriba":     [18513.70, 30426.73, 18513.70, 20426.73, ....],
    #          "korba":     [38513.70, 30426.73, 58513.70, 10426.73, ....],
    #       }
    #   @example previsione_down
    #       {
    #          "feriana":   [25513.70, 30426.73, 4513.70, 10426.73, ....],
    #          "kasserine": [28513.70, 30426.73, 8513.70, 30426.73, ....],
    #          "zriba":     [18513.70, 30426.73, 18513.70, 20426.73, ....],
    #          "korba":     [38513.70, 30426.73, 58513.70, 10426.73, ....],
    #       }
    #
    #   @return [FunctionalLightService::Context, FunctionalLightService::Context.fail_and_return!]
    executed do |ctx|
      try! do
        if ctx.data[/\s\d\d/].strip == "09"
          curve_up, curve_down = limit
          ctx.previsione_up = previsione(curve_up)
          ctx.previsione_down = previsione(curve_down)
        else
          ctx.previsione_up = nil
          ctx.previsione_down = nil
        end
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Errore non sono riuscito a calcolare il limite superiore o inferiore della mia previsione",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end

    def self.limit
      # @type [Hash]
      limit_up = {}
      # @type [Hash]
      limit_down = {}
      # @type [Float]
      totale = totale_day_previsione

      # scorro per ogni ora i dati filtrati
      # metto nell'hash limit_up per ogni ora prendo tutti i consuntivi che hanno un valore totale giorno maggiore del mio totale giorno delle prevsione
      # metto nell'hash limit_down per ogni ora prendo tutti i consuntivi che hanno un valore totale giorno inferiore del mio totale giorno delle prevsione
      ctx.filtered_data_group_by_hour.each do |k, v|
        limit_up[k] = v.select do |row|
          next if row["Flow_Totale"].nil?
          (row["Flow_Totale"] * 1000) >= totale
        end
        limit_down[k] = v.select do |row|
          next if row["Flow_Totale"].nil?
          (row["Flow_Totale"] * 1000) < totale
        end
      end
      [limit_up, limit_down]
    end

    # Esegue la media ponderata dei dati filtrati passati come parametro fcs
    #
    # @param fcs [Hash<Array>] Consuntivi filtrati raggraupati per ora

    # @return [Hash<Array>]
    #       {
    #          "feriana":   [25513.70, 30426.73, 4513.70, 10426.73, ....],
    #          "kasserine": [28513.70, 30426.73, 8513.70, 30426.73, ....],
    #          "zriba":     [18513.70, 30426.73, 18513.70, 20426.73, ....],
    #          "korba":     [38513.70, 30426.73, 58513.70, 10426.73, ....],
    #       }
    def self.previsione(fcs)
      # creo un hash in cui ogni stazione ha un array vuoto
      # {
      #   "feriana"   => [],
      #   "kasserine" => [],
      #   "zriba"     => [],
      #   "nabeul"    => [],
      #   "korba"     => []
      # }
      #
      # @type [Hash]
      previsione = PS.to_h { |s| [s, []] }
      # scorro le varie ore e prendo solo il valore che è un Hash di tutti i consuntivi filtrati per quell'ora
      # e lo passo al blocco come variabile fcs_hour
      fcs.each_value do |fcs_hour|
        # scorro le PS ["feriana","kasserine","zriba","nabeul","korba"]
        # e metto in previsione[ps] la media ponderata di tutti i dati filtrati per quell'ora
        # quindi ogni stazione ha un array di 24 valori in cui ogni valore è la media ponderata
        #    {
        #       "feriana":   [25513.70, 30426.73, 4513.70, 10426.73, ....],
        #       "kasserine": [28513.70, 30426.73, 8513.70, 30426.73, ....],
        #       "zriba":     [18513.70, 30426.73, 18513.70, 20426.73, ....],
        #       "korba":     [38513.70, 30426.73, 58513.70, 10426.73, ....],
        #    }
        PS.each do |ps|
          previsione[ps] << media_ponderata(ps, fcs_hour) * 1000
        end
      end
      previsione
    end

    # calcola il valore totale giorno delle previsione
    #
    # @return [Float]
    def self.totale_day_previsione
      ctx.previsione.reduce(0) do |sum, num|
        sum + num[1].sum
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
        forecast.map { |h| [h["Flow_#{ps.capitalize}"], h["Peso"]] }
      end
        .then do |tmp|
        tmp.reduce(0) { |sum, num| sum + num[0] * num[1] } / tmp.reduce(0) { |sum, num| sum + num[1] }
      end
    end

    private_class_method \
      :limit,
      :previsione,
      :totale_day_previsione,
      :media_ponderata
  end
end
