require 'generate_pdf_helper'

if defined?(Rails)
  if Rails::VERSION::MAJOR == 2
    unless ActionController::Base.instance_methods.include? "render_with_generate_pdf"
      ActionController::Base.send :include, GeneratePdfHelper
    end
    
    Mime::Type.register 'application/pdf', :pdf
  
  else
    class GeneratePdfRailtie < Rails::Railtie
  
      initializer "generate_pdf.register" do |app|
        ActionController::Base.send :include, GeneratePdfHelper
        
  
        Mime::Type.register 'application/pdf', :pdf
      end
    end
  end
end