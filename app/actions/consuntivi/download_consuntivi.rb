#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ConsuntiviActions
  ##
  # Avvio lo scaricamento dei consuntivi dal FTP di scada
  class DownloadConsuntivi
    extend FunctionalLightService::Action

    executed do |ctx|
      now = DateTime.now - 5

      begin
        Net::SFTP.start("10.97.195.213", "SCADA", {password: "scadaprod", port: 10022, timeout: 30, non_interactive: true}) do |sftp|
          sftp.dir.glob("/Archive", "*.dat") do |file|
            # puts entry.longname
            if Time.at(file.attributes.mtime).to_datetime > now
              name = file.name
              local_path = "#{Ikigai::Config.path.consuntivi_scada}#{name}"
              unless File.exist?(local_path)
                sftp.download("/Archive/#{name}", local_path)
              end
            end
          end
        end
      rescue Net::SSH::AuthenticationFailed => err
        ctx.fail_and_return!(
          {message: "Errore di auteticazione al server FTP controllare user e password",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
        ctx.fail_and_return!("Errore di auteticazione al server FTP controllare user e password")
      rescue Net::SFTP::StatusException => err
        ctx.fail_and_return!(
          {message: "Errore nello scariamenti del file #{err.text.sub("open ", "")} dal server FTP",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      rescue => err
        ctx.fail_and_return!(
          {message: "Errore nello scariamenti dei consuntivi dal server FTP",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end
  end
end
