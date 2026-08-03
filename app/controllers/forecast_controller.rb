#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

PS = %w[feriana kasserine zriba nabeul korba].freeze

# Crea il Forecast
#
# Utilizzo questa classe per avviare le azioni
# per il calcolo del forecast, inoltre gestisco
# qualsiasi errore che possa essere avvenuto dentro le varie
# azioni eseguite, in caso di errore imprevisto viene gestino
# da qui e viene stamnpato il log e inviata un'email di notifica
class ForecastController < Ikigai::BaseController
  # @!parse
  #   extend FunctionalLightService::Organizer
  #   include ShareAction
  #   include ForecastActions
  extend FunctionalLightService::Organizer
  include ForecastActions
  include ShareActions

  # Entry point chiamato per avviare il forecast
  #
  # @param  env [Hash] Enviroment della mia applicazione
  # @option env [String] :controller Controller chiamato
  # @option env [String] :action Entry point del mio controller da eseguire
  # @option env [Hash] :command_options parametri della mia azione da eseguire
  # @option env [Hash] :global_options parametri globali dell'applicazione
  #
  # @example param :env
  #   {
  #     :controller      => "forecast",
  #     :action          => "call",
  #     :command_options => {
  #       "dt"  => "09/04/2021",
  #       :dt   => "09/04/2021",
  #       "day" => "09/04/2021",
  #       :day  => "09/04/2021"
  #     },
  #     :global_options  => {
  #       "l"          => "info",
  #       :l           => "info",
  #     }
  #   }
  #
  # @return [void]
  def self.call(env:)
    # @type [FunctionalLightService::Context]
    result = with(env: env).reduce(steps)
    err_datail_enabled = env.dig(:global_options, :verbose).to_s > "0"
    check_result(result, detail: err_datail_enabled)
    nil
  rescue => e
    msg = e.message + "\n"
    e.backtrace.each { |x| msg += x + "\n" if x.include? APP_NAME }
    log.fatal msg
    exit 1
  end

  # Azioni eseguite in serie per il calcolo del Forecast
  #
  # {ForecastActions::ConnectExcel}
  # Mi connetto ad excel<br/>
  #  - **@promises** excel [WIN32OLE] Instance Excel\
  #  - **@promises** workbook [WIN32OLE] Instance Excel del file excel del Forecast
  #
  # {ShareActions::SetExcelDay}
  # Setta nel file excel del Forecast la data
  #  - **@promises** data [String] Contiene la data e ora es. "17032022 10:00:00"
  #
  # {ForecastActions::GetExcelParams}
  # Prendo da excel tutti i dati di input per eseguire il Forecast
  #  - **@promises** params [Hash] parametri letti da excel per eseguire il forecast
  #
  # {ShareActions::RefreshLinks}
  # Fai il refresh dei link nel file Forecast, chimando una macro presente nel file excel
  #   - **@expects** excel [WIN32OLE]
  #
  # {ForecastActions::ReadDb}
  # Prendo dal db tutti i dati consuntivi
  #  - **@expects** excel [WIN32OLE]
  #  - **@promises** consuntivi [Array<Hash>] Consuntivi di Steg
  #
  # {ForecastActions::FilterData}
  # Filtro i consuntivi letti dal DB in base ai filtri impostati nell'Excel
  #   - **@expects** consuntivi [Array<Hash>] Consuntivi di Steg letti dal DB
  #   - **@expects** params [Hamster::Hash] parametri letti da excel
  #   - **@promises** filtered_data [FunctionalLightService::Result] Se finisce con successo forecast [Array<Hash>]
  #
  # {ForecastActions::GroupByHour}
  # Raggruppo i consuntivi filtrati per ora
  #   - **@expects** filtered_data [FunctionalLightService::Result] Se finisce con successo forecast [Array<Hash>]
  #   - **@promises** filtered_data_group_by_hour [Hash<Array>] Consuntivi filtrati raggraupati per ora
  #
  # {ForecastActions::Previsione}
  # Esegue la media ponderata dei dati filtrati nelo step precedente e crea la mia previsione
  #   - **@expects** filtered_data_group_by_hour [Hash<Array>] Consuntivi filtrati raggraupati per ora
  #   - **@promises** previsione [Hash<Array>] Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
  #
  #    previsone = {"feriana"=>[28513.707674943573, 30426.730663741077],
  #                 "kasserine"=>[5293.154627539503, 5158.996160175534],
  #                 "zriba"=>[236252.539503386, 251786.7526055952],
  #                 "nabeul"=>[79220.02257336344, 87046.02303894682],
  #                 "korba"=>[5760.112866817157, 6106.385079539223]}
  #
  # {ForecastActions::GoalNomination}
  # Avvia la macro che trova la miglior nomina di STEG
  #
  # {ForecastActions::PrevisionLimit}
  # Genero gli estremi superiore e inferiore del mio forecast
  #   - **@expects** previsione [Hash<Array>] Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
  #   - **@expects** data [String] Contiene data e ora del forecast da eseguire
  #   - **@expects** filtered_data_group_by_hour [Hash<Array>] Consuntivi filtrati raggraupati per ora
  #   - **@promises** previsione_up [Hash<Array>] Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
  #   - **@promises** previsione_down [Hash<Array>] Mette in un hash la mia previsione ogni chiave dell'Hash è una stazione
  #
  # @example previsone_up
  #     {"feriana"=>[28513.707674943573, 30426.730663741077],
  #                 "kasserine"=>[5293.154627539503, 5158.996160175534],
  #                 "zriba"=>[236252.539503386, 251786.7526055952],
  #                 "nabeul"=>[79220.02257336344, 87046.02303894682],
  #                 "korba"=>[5760.112866817157, 6106.385079539223]}
  #
  # @example previsone_down
  #     {"feriana"=>[28513.707674943573, 30426.730663741077],
  #                 "kasserine"=>[5293.154627539503, 5158.996160175534],
  #                 "zriba"=>[236252.539503386, 251786.7526055952],
  #                 "nabeul"=>[79220.02257336344, 87046.02303894682],
  #                 "korba"=>[5760.112866817157, 6106.385079539223]}
  #
  # {ForecastActions::Dispersione}
  # Calcolo la dispersione delle curve sugli anni, come si distribuiscono le curve sui vari anni
  #   - **@expects** filtered_data_group_by_hour [Hash<Array>] Consuntivi filtrati raggraupati per ora
  #   - **@expects** previsione_up [Hash<Array>] contiene tutte le curve suddivise per stazione che sono sopra la mia previsione
  #   - **@expects** previsione_down [Hash<Array>] contiene tutte le curve suddivise per stazione che sono sotto la mia previsione
  #   - **@expects** data [String] Contiene data e ora del forecast da eseguire
  #   - **@promises** dispersione [Hash<Array>] Mette in un hash la mia disperzione, nel quale ogni chiave e un anno, e i valori sono un array con tutti le curve relative a quell'anno
  #
  # @example dispersione
  #     {2015 => [75000, 80000], 2016 => [8000, 445544], 2017 => [332432, 31243, 4324342], 2018 => [32314, 3243432] ... }
  #
  # {ForecastActions::DailyEvolution}
  # Prendo i valori della previsione corrente per copiarli nella tabella daily evolution del forecast
  #   - **@expects** workbook [WIN32OLE]
  #   - **@promises** daily_evolution [Hash] Previsione corrente
  #
  # {ForecastActions::CompilaForecastExcel}
  # Compila in il file Forecast,xlsm con la mia previsone
  #   **@expects** previsione [Hash<Array>] la mia previsione ogni chiave dell'Hash è una stazione
  #   **@expects** previsione_up [Hash<Array>] contiene tutte le curve suddivise per stazione che sono sopra la mia previsione
  #   **@expects** previsione_down [Hash<Array>] contiene tutte le curve suddivise per stazione che sono sotto la mia previsione
  #   **@expects** dispersione [Hash<Array>] hash della disperzione, nel quale ogni chiave e un anno, e i valori sono un array con tutti le curve relative a quell'anno
  #   **@expects** daily_evolution [Hash] contiene previsione corrente
  #   **@expects** workbook [WIN32OLE] file excel del mio forecast
  #
  # {ForecastActions::SaveHistory}
  # Salvo nel database la previsione corrente
  #   - **@expects** daily_evolution [Hash] contiene previsione corrente
  #
  def self.steps
    # rubocop:disable Layout/ExtraSpacing
    [
      ConnectExcel,         # E:[], P:[excel, workbook]
      SetExcelDay,          # E:[], P:[data]
      GetExcelParams,       # E:[], P:[params]
      RefreshLinks,         # E:[excel], P:[]
      ReadDb,               # E:[excel], P:[consuntivi]
      FilterData,           # E:[consuntivi, params], P:[filtered_data]
      GroupByHour,          # E:[filtered_data], P:[filtered_data_group_by_hour]
      Previsione,           # E:[filtered_data_group_by_hour], P:[previsione]
      GoalNomination,       # E:[], P:[]
      PrevisionLimit,       # E:[previsione,filtered_data_group_by_hour, data], P:[previsone_up, previsone_down]
      Dispersione,          # E:[filtered_data_group_by_hour, previsione, previsione_down, data], P:[dispersione]
      DailyEvolution,       # E:[workbook], P:[daily_evolution]
      CompilaForecastExcel, # E:[previsione, previsione_up, previsione_down, dispersione, daily_evolution, workbook] P:[]
      SaveHistory           # E:[daily_evolution], P:[]
    ]
    # rubocop:enable Layout/ExtraSpacing
  end

  private_class_method :steps
end
