#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ForecastActions
  # Raggruppo i consuntivi filtrati per ora
  #
  # @example promises filtered_data_group_by_hour
  #     {
  #        8: [
  #            [0] {
  #              "Date"            => #<DateTime: 2021-11-16T08:00:00+00:00 ((2459535j,28800s,0n),+0s,2299161j)>,
  #              "Giorno"          => 20,
  #              "Mese"            => 10,
  #              "Anno"            => 2015,
  #              "Ora"             => 8,
  #              "Giorno_Sett_Num" => 2,
  #              "Festivo"         => "N",
  #              "Festivita"       => "N",
  #              "Stagione"        => "autunno",
  #              "Exclude"         => "N",
  #              "Peso"            => 1.0,
  #              "Flow_Feriana"    => 70.0,
  #              "Flow_Kasserine"  => 1.0,
  #              "Flow_Zriba"      => 256.0,
  #              "Flow_Nabeul"     => 49.0,
  #              "Flow_Korba"      => 7.0,
  #              "Flow_Totale"     => 9235.0
  #             }
  #             ....
  #          ]
  #        9: [
  #            [0] {
  #              "Date"            => #<DateTime: 2021-11-16T09:00:00+00:00 ((2459535j,28800s,0n),+0s,2299161j)>,
  #              "Giorno"          => 20,
  #              "Mese"            => 10,
  #              "Anno"            => 2015,
  #              "Ora"             => 9,
  #              "Giorno_Sett_Num" => 2,
  #              "Festivo"         => "N",
  #              "Festivita"       => "N",
  #              "Stagione"        => "autunno",
  #              "Exclude"         => "N",
  #              "Peso"            => 1.0,
  #              "Flow_Feriana"    => 70.0,
  #              "Flow_Kasserine"  => 1.0,
  #              "Flow_Zriba"      => 256.0,
  #              "Flow_Nabeul"     => 49.0,
  #              "Flow_Korba"      => 7.0,
  #              "Flow_Totale"     => 9235.0
  #             }
  #             ....
  #          ]
  #     }
  class GroupByHour
    extend FunctionalLightService::Action

    # @expects filtered_data [FunctionalLightService::Result] Se finisce con successo forecast [`Array<Hash>`]
    expects :filtered_data
    # @promises filtered_data_group_by_hour [Hash<Array>] Consuntivi filtrati raggraupati per ora
    promises :filtered_data_group_by_hour

    executed do |ctx|
      # @type [Hash]
      group_by_hour = ctx.filtered_data.value.group_by { |h| h["Ora"] }
      hours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 0, 1, 2, 3, 4, 5, 6, 7]
      ctx.filtered_data_group_by_hour = {}
      try! do
        hours.each do |h|
          ctx.filtered_data_group_by_hour[h] = group_by_hour[h.to_f]
        end
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Errore nel raggruppare i consuntivi per ora",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
      ctx.filtered_data_group_by_hour.freeze
    end
  end
end
