module GeneratePdfHelper
  require 'generate_pdf'

  def self.included(base)
    base.class_eval do
      alias_method_chain :render, :generate_pdf
    end
  end

  def render_with_generate_pdf(options = nil, *args, &block)
    if (response.content_type == "application/pdf" || response.request.parameters["format"] == "pdf") && @done_rendering_pdf.nil?
      logger.info '*'*15 + 'Shreyas' + '*'*15
      options ||= {}
      options[:pdf] ||= "temp_file"
      @done_rendering_pdf = true
      make_and_send_pdf(options.delete(:pdf), (GeneratePdf.config || {}).merge(options))
    else
      render_without_generate_pdf(options, *args, &block)
    end
  end

  private
  def make_pdf(options = {})
    html_string = translate_paths(render_to_string(:template => options[:template], :layout => options[:layout]))
    w = GeneratePdf.new(options[:wkhtmltopdf])
    w.pdf_from_string(html_string, options)
  end

  def make_and_send_pdf(pdf_name, options = {})
    options[:wkhtmltopdf] ||= nil
    options[:layout] ||= false
    options[:template] ||= get_template_file#File.join(controller_path, action_name)
    options[:disposition] ||= "inline"
      
    options = prerender_header_and_footer(options)
    if options[:show_as_html]
      render :template => options[:template], :layout => options[:layout], :content_type => "text/html"
    else
      pdf_content = make_pdf(options)
      File.open(options[:save_to_file], 'wb') {|file| file << pdf_content } if options[:save_to_file]
      send_data(pdf_content, :filename => pdf_name + '.pdf', :type => 'application/pdf', :disposition => options[:disposition]) unless options[:save_only]
    end
  end

  # Given an options hash, prerenders content for the header and footer sections
  # to temp files and return a new options hash including the URLs to these files.
  def prerender_header_and_footer(options)
    [:header, :footer].each do |hf|
      if options[hf] && options[hf][:html] && options[hf][:html][:template]
        GeneratePdfTempfile.open("generate_pdf.html") do |f|
          f << render_to_string(:template => options[hf][:html][:template],
            :layout => options[:layout])
          options[hf][:html].delete(:template)
          options[hf][:html][:url] = "file://#{f.path}"
        end
      end
    end

    return options
  end
    
  def get_template_file
    temp_name = File.join(controller_path, action_name)
    if File.exist?("#{Rails.root}/app/views/#{temp_name}.pdf.erb")
      return "#{temp_name}.pdf.erb"
    elsif File.exist?("#{Rails.root}/app/views/#{temp_name}.html.erb")
      return "#{temp_name}.html.erb"
    end
  end
    
  def translate_paths(p)
    root = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/"
    p.gsub(/(href|src)=(['"])\/([^\"']*|[^"']*)['"]/, '\1=\2' + root + '\3\2')
  end
    
end
