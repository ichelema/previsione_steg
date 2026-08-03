#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ReportActions
  ##
  # Setto il path dove salvare il PDF
  #
  # **Expects:**
  # - `path` (`String`) Path dove salvare i PDF
  # - `data` (`String`) Data del report
  #
  # **Promises:**
  # - `path_pdf_report` (`String`) Path dove salvare il PDF
  #
  class SetPdfPath
    # @!parse
    #   extend FunctionalLightService::Action
    extend FunctionalLightService::Action

    expects :path, :data
    promises :path_pdf_report

    # @!method SetPdfPath(ctx)
    #
    #   @!scope class
    #
    #   @param ctx [FunctionalLightService::Context]
    #
    #   @expects path [String] Path dove salvare i PDF
    #   @expects data [String] Data del report
    #
    #   @promises path_pdf_report [String] Path dove salvare il PDF
    #
    #   @return [FunctionalLightService::Context, FunctionalLightService::Context.fail_and_return!]
    executed do |ctx|
      try! do
        ctx.path_pdf_report = nil
        file_name = "/STEG_#{type}_#{data}_rev#{version}.pdf"
        full_path = (ctx.path + file_name).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
        ctx.path_pdf_report = full_path.freeze
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Non riesco a settare il path dove salvare i PDF dei report",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end

    # cerco l'ultima versionamento da assegnarli
    #
    # @return [Integer]
    def self.version
      files = Dir.glob("#{ctx.path}/STEG_*_#{data}_rev*.pdf")
      return "1" if files.empty?
      last_version = files.max_by { |x| x.scan(/rev\d/) }.match(%r{(?<version>rev\d)})
      return "1" if last_version.nil?
      last_version[:version][-1].to_i + 1
    end

    # setto il tipo di report se consuntivo o forecast
    #
    # @return [String]
    def self.type
      ctx.env.dig(:command_options, :type) == "forecast" ? "FCT" : "CONS"
    end

    # setto la data
    #
    # @return [String]
    def self.data
      ctx.env.dig(:command_options, :type) == "forecast" ? ctx.data.tr(" ", "_")[0..10] : ctx.data[0..7]
    end

    private_class_method \
      :version,
      :type,
      :data
  end
end
