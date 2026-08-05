#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ForecastActions
  ##
  # Filtro i consuntivi letti dal DB in base ai filtri impostati nell'Excel
  #
  # @example promises filtered_data value
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
  #     ]
  class FilterData
    # @!parse
    #   extend ForecastConcern::Excel
    extend FunctionalLightService::Action

    # @expects consuntivi [Array<Hash>] Consuntivi di Steg letti dal DB
    expects :consuntivi
    # @expects params [Hamster::Hash] parametri letti da excel
    expects :params
    # @promises filtered_data [FunctionalLightService::Result<Array<Hash>>] `Success` con i consuntivi filtrati; in caso di `Failure` la pipeline si ferma qui
    promises :filtered_data

    executed do |ctx|
      ctx.filtered_data = Success(ctx.consuntivi) \
                     >> method(:filter_giorno) \
                     >> method(:filter_festivo) \
                     >> method(:filter_festivita)
      ctx.fail_and_return!(ctx.filtered_data.value) if ctx.filtered_data.failure?
    end

    # Applico questo filtro se nei miei filtri ho impostato che devo selezionare il giorno esatto della settimana
    #
    # @param consuntivi [Array<Hash>] Consuntivi di Steg letti dal DB
    #
    # @return [FunctionalLightService::Result]
    def self.filter_giorno(consuntivi)
      return Success(consuntivi) if ctx.params[:giorno_settimana] == "NO"
      try! do
        consuntivi.select { |row| row["Giorno_Sett_Num"] == ctx.params[:day].value[5].to_i }
      end.map_err { Failure("Non riesco ad applicare il filtro giorno_settimana") }
    end

    # Applico il filtro che mi seleziona se è un festivo o un settimanale
    #
    # @param consuntivi [Array<Hash>] Consuntivi di Steg letti dal DB
    #
    # @return [FunctionalLightService::Result]
    def self.filter_festivo(consuntivi)
      return Success(consuntivi) if ctx.params[:festivo] == "ALL"
      try! do
        yes_not = ctx.params[:festivo] == "SI" ? "Y" : "N"
        consuntivi.select { |row| row["Festivo"] == yes_not }
      end.map_err { Failure("Non riesco ad applicare il filtro festivo") }
    end

    # Applico il filtro che mi seleziona se è una festività
    #
    # @param consuntivi [Array<Hash>] Consuntivi di Steg letti dal DB
    #
    # @return [FunctionalLightService::Result]
    def self.filter_festivita(consuntivi)
      return Success(consuntivi) if ctx.params[:festivita] == "ALL"
      try! do
        yes_not = ctx.params[:festivita] == "SI" ? "Y" : "N"
        consuntivi.select { |row| row["Festivita"] == yes_not }
      end.map_err { Failure("Non riesco ad applicare il filtro festivita") }
    end

    private_class_method \
      :filter_giorno,
      :filter_festivo,
      :filter_festivita
  end
end
