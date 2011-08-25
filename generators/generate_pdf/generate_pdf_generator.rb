class GeneratePdfGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.file "generate_pdf.rb", "config/initializers/generate_pdf.rb"
    end
  end
end
