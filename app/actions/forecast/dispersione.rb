#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ForecastActions
  # Calcolo la dispersione delle curve sugli anni, come si distribuiscono le curve sui vari anni
  #
  # **Expects:**
  # - `filtered_data_group_by_hour` (`Hash<Array>`) Consuntivi filtrati raggraupati per ora
  # - `previsione_up` (`Hash<Array>`) contiene tutte le curve suddivise per stazione che sono sopra la mia previsione
  # - `previsione_down` (`Hash<Array>`) contiene tutte le curve suddivise per stazione che sono sotto la mia previsione
  # - `data` (`String`) Contiene data e ora del forecast da eseguire
  #
  # **Promises:**
  # - `dispersione` (`Hash<Array>`) Mette in un hash la mia disperzione, nel quale ogni chiave e un anno, e i valori sono un array con tutti le curve relative a quell'anno
  #
  class Dispersione
    # @!parse
    #   extend FunctionalLightService::Action
    extend FunctionalLightService::Action

    expects \
      :filtered_data_group_by_hour,
      :previsione_up,
      :previsione_down,
      :data

    promises \
      :dispersione

    # @!method Dispersione(ctx)
    #
    #   @!scope class
    #
    #   @param ctx [FunctionalLightService::Context]
    #
    #   @expects filtered_data_group_by_hour [Hash<Array>] Consuntivi filtrati raggraupati per ora
    #   @expects previsione_up [Hash<Array>] contiene tutte le curve suddivise per stazione che sono sopra la mia previsione
    #   @expects previsione_down [Hash<Array>] contiene tutte le curve suddivise per stazione che sono sotto la mia previsione
    #   @expects data [String] Contiene data e ora del forecast da eseguire
    #
    #   @promises dispersione [Hash<Array>] Mette in un hash la mia disperzione, nel quale ogni chiave e un anno, e i valori sono un array con tutti le curve relative a quell'anno
    #
    #   @example dispersione
    #     {2015 => [75000, 80000], 2016 => [8000, 445544], 2017 => [332432, 31243, 4324342], 2018 => [32314, 3243432] ... }
    #
    #   @return [FunctionalLightService::Context, FunctionalLightService::Context.fail_and_return!]
    executed do |ctx|
      next ctx.dispersione = nil unless ctx.data[/\s\d\d/].strip == "09"
      try! do
        # @type [Float]
        upper_limit = totale(ctx.previsione_up)
        # @type [Float]
        down_limit = totale(ctx.previsione_down)
        # @type [Integer] conta il numero totale di curve
        _totale_num_curve = ctx.filtered_data_group_by_hour[8].size
        # @type [Integer] conta il numero totale di curve sopra il mio upper_limit
        _num_curve_upper_limit = ctx.filtered_data_group_by_hour[8].count { |x| x["Flow_Totale"] * 1000 > upper_limit }
        # @type [Integer] conta il numero totale di curve sotto il mio down_limit
        _num_curve_down_limit = ctx.filtered_data_group_by_hour[8].count { |x| x["Flow_Totale"] * 1000 < down_limit }

        # @example anno
        #   [[2015],[2015],[2015],[2015],[2016], [2016], [2016], [2017], [2017], [2018], [2018], [2019],[2019],[2020],[2020], [2021],[2021]]
        # @type [Array<Array>] mi estrae dalla prima ora delle mie curve tutti gli anni
        anno = ctx.filtered_data_group_by_hour[8].map { |w| w["Anno"] }.each_slice(1).to_a

        # @type [Hash<Array>] le prevsioni raggruppate per anno
        group_by_year = ctx.filtered_data_group_by_hour[8].group_by { |h| h["Anno"] }
        # @type [Hash<Array>] variabile che conterra la mia dispersione
        ctx.dispersione = {"anno" => anno}

        # scorro i vari anni e per ogni anno prendo le curve
        group_by_year.each do |k, v|
          # prende i totale di tutte le curve relitve all'anno passato come variabile k
          # e lo mette nella'hash ctx.dispersione[k], quindi ottengo per ogni anno tutti i valori giornaliere delle curve
          # @example ctx.dispersione[2015]
          #   [[7367000.0],
          #    [8478000.0],
          #    [5378000.0],
          #    [5349000.0],
          #    [7195000.0],
          #    [5658000.0],
          #    [7452000.0],
          #    [6319000.0],
          #    [8254000.0],
          #    [7092000.0]]
          #
          ctx.dispersione[k] = v.map do |w|
            w["Flow_Totale"] * 1000
          end.each_slice(1).to_a
        end
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Errore non sono riuscito a calcolare la dispersione delle curve",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end

    # fa la somma di tutte le ore per ogni stazione, e somma tutte le stazioni, quindi ottengo un totale giorno di tutte le stazioni
    #
    # @param prv [Hash<Array>] Hash in cui ogni chiave e una stazione e il suo valore è un array con 24 valori uno per ogni ora
    #
    # @return [Float]
    def self.totale(prv)
      prv.reduce(0) do |sum, num|
        sum + num[1].sum
      end
    end

    private_class_method \
      :totale
  end
end
