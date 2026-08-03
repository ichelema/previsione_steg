#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

# Crea il report da inviare via e-mail
#
# Utilizzo questa classe per avviare le azioni
# per la creazione del report pdf da inviare
# qualsiasi errore che possa essere avvenuto dentro le varie
# azioni eseguite, in caso di errore imprevisto viene gestino
# da qui e viene stamnpato il log e inviata un'email di notifica
class ReportController < Ikigai::BaseController
  # @!parse
  #   extend FunctionalLightService::Organizer
  #   include ShareAction
  #   include ReportActions
  extend FunctionalLightService::Organizer
  include ReportActions
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

  # Azioni eseguite in serie per creare il report e inviarlo via e-mail
  #
  # {ReportActions::ConnectExcel}
  # Mi connetto ad excel<br/>
  #   - **@promises** mario [WIN32OLE] Instance Excel\
  #   - **@promises** workbook [WIN32OLE] Instance Excel del file excel del Forecast\
  #
  # {ShareActions::SetExcelDay}
  # Setta nel file excel del Forecast la data
  #   - **@promises** data [String] Contiene la data es. "09042021"
  #
  # {ReportActions::GetPath}
  # Setto il path della directory dove andare a salvare i PDF
  #   - **@expects** env[Hash] Enviroment Application
  #   - **@promises** path [String] Path dei file pdf
  #
  # {ReportActions::SetPdfPath}
  # Setto il path dove andare a salvare i PDF
  #   - **@expects** path [String] Path dove salvare i PDF
  #   - **@expects** data [String] Data del report
  #   - **@promises** path_pdf_report [String] Path dove salvare il PDF
  #
  # {ReportActions::SavePdf}
  # Chiama una funzione Excel per salvare su PDF lo sheet Forecast
  #   - **@expects** path_pdf_report [String] Path dove salvare i PDF
  #
  # {ReportActions::MakeHtml}
  # Crea l'HTML da inserire nel body dell'e-mail
  #   - **@promises** html [String] html da inserire del body dell'e-mail
  #
  # {ReportActions::PrintScreenScada}
  # Faccio il printscreen di scada
  #   - **@promises** path_pdf_old_report [String] Path del printscreen di scada
  #
  # {ReportActions::PathPdfOldForecast}
  # Setto il path dove prendere il PDF del vecchio forecast
  #   - **@promises** path_printscreen_scada [String] Path del pdf dell'ultimo report creato dal vecchio forecast
  #
  # {ReportActions::SendEmail}
  # Invia l'e-mail con allegato il report pdf
  #   - **@expects** html [String] html da inserire del body dell'e-mail
  #   - **@expects** path_pdf_report [String] Path dove salvare il PDF
  #
  # {ReportActions::ClearDailyEvolution}
  # Pulisco la tabella daily evolution del forecast
  #
  # {ReportActions::SaveAllFile}
  # Salvo i file Forecast.xlsm | Db.xlsm | DB2.xlsm se il report che sto generando è un consuntivo
  #
  def self.steps
    # rubocop:disable Layout/ExtraSpacing
    [
      ConnectExcel,                                                                                      # E:[]                       P:[excel, workbook]
      SetExcelDay,                                                                                       # E:[]                       P:[data]
      GetPath,                                                                                           # E:[]                       P:[path]
      SetPdfPath,                                                                                        # E:[]                       P:[path_pdf_report]
      SavePdf,                                                                                           # E:[path_pdf_report]        P:[]
      MakeHtml,                                                                                          # E:[]                       P:[html]
      # PrintScreenScada,                                                                                # E:[]                       P:[path_printscreen_scada]
      # PathPdfOldForecast,                                                                              # E:[]                       P:[path_pdf_old_report]
      SendEmail,                                                                                         # E:[html, path_pdf_report]  P:[]
      reduce_if(->(ctx) { ctx.env.dig(:command_options, :type) == "consuntivo" }, ClearDailyEvolution),  # E:[]                       P:[]
      reduce_if(->(ctx) { ctx.env.dig(:command_options, :type) == "consuntivo" }, SaveAllFile)           # E:[]                       P:[]
    ]
    # rubocop:enable Layout/ExtraSpacing
  end

  private_class_method :steps
end
